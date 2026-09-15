import 'dart:async';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'settings_provider.dart';
import '../services/serial_service.dart';
import '../services/api_service.dart';
import '../utils/sensor_parser.dart';

enum AppStatus { idle, sampling, predicting, flushing, testing }

class SamplingProvider with ChangeNotifier {
  final SerialService _serialService;
  final ApiService _apiService;

  AppStatus _status = AppStatus.idle;
  final List<String> _logs = [];
  final List<Map<String, double>> _sensorDataPoints = [];
  final List<Map<String, double>> _liveChartPoints = [];
  Map<String, double> _currentLiveValues = {};
  
  // Results
  String _predictionCategory = '-';
  double _tvcScore = 0.0;
  String _lastRawLine = '';
  
  // Timers and Countdowns
  int _countdownSeconds = 0;
  Timer? _countdownTimer;
  StreamSubscription<String>? _serialSubscription;

  SamplingProvider(this._serialService, this._apiService) {
    // Listen to line stream to update live dashboard charts even when not sampling
    _serialService.lineStream.listen((line) {
      _lastRawLine = line;
      final allPins = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'];
      _currentLiveValues = SensorParser.parseLine(line, allPins);
      
      _liveChartPoints.add(_currentLiveValues);
      if (_liveChartPoints.length > 50) {
        _liveChartPoints.removeAt(0);
      }
      notifyListeners();
    });
  }

  // Getters
  AppStatus get status => _status;
  List<String> get logs => _logs;
  List<Map<String, double>> get sensorDataPoints => _sensorDataPoints;
  List<Map<String, double>> get liveChartPoints => _liveChartPoints;
  Map<String, double> get currentLiveValues => _currentLiveValues;
  String get predictionCategory => _predictionCategory;
  double get tvcScore => _tvcScore;
  String get lastRawLine => _lastRawLine;
  int get countdownSeconds => _countdownSeconds;

  bool get isRunning => _status != AppStatus.idle;

  void addLog(String message) {
    final timestamp = DateTime.now().toString().split('.').first;
    _logs.add("[$timestamp] $message");
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void _startCountdown(int seconds, {required VoidCallback onFinished}) {
    _countdownTimer?.cancel();
    _countdownSeconds = seconds;
    notifyListeners();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        _countdownSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        onFinished();
      }
    });
  }

  /// Exhale / clean gas sequence (1 minute exhale, stop)
  Future<void> runFlushSequence() async {
    addLog("Membersihkan gas - flushing...");
    _serialService.writeString('2'); // Send exhale signal
    
    // In Python it flushes for 60 seconds
    await Future.delayed(const Duration(seconds: 60));
    
    _serialService.writeString('3'); // Stop pumps
    await Future.delayed(const Duration(seconds: 5));
  }

  /// Stop all operations immediately
  void stopAll() {
    _countdownTimer?.cancel();
    _serialSubscription?.cancel();
    _serialService.writeString('3'); // Stop command
    _status = AppStatus.idle;
    _countdownSeconds = 0;
    addLog("Proses dibatalkan oleh pengguna.");
    notifyListeners();
  }

  /// Start local testing sequence
  void startTesting() {
    if (isRunning) return;
    _status = AppStatus.testing;
    addLog("Mulai testing...");
    notifyListeners();

    _startCountdown(3, onFinished: () {
      addLog("Testing selesai.");
      _status = AppStatus.idle;
      notifyListeners();
    });
  }

  /// Start manual flushing sequence
  Future<void> startFlushing() async {
    if (isRunning) return;
    _status = AppStatus.flushing;
    addLog("Mulai flushing...");
    notifyListeners();

    await runFlushSequence();
    
    addLog("Flushing selesai.");
    _status = AppStatus.idle;
    notifyListeners();
  }

  /// Start standard CSV sampling sequence
  Future<void> startSampling(SettingsProvider settings) async {
    if (isRunning) return;
    if (!_serialService.isConnected) {
      addLog("Error: Port serial belum terkoneksi!");
      return;
    }

    _status = AppStatus.sampling;
    _sensorDataPoints.clear();
    _predictionCategory = '-';
    _tvcScore = 0.0;
    
    final sampleLabel = "${settings.selectedSampleType} - ${settings.sampleName}";
    final nextCount = settings.samplingCount + 1;
    addLog("Mulai sampling #$nextCount [$sampleLabel] - Interval: ${settings.samplingInterval} menit...");
    notifyListeners();

    // Step 1: Send Stop, wait 3 seconds
    _serialService.writeString('3');
    await Future.delayed(const Duration(seconds: 3));

    // Step 2: Send Inhale, countdown sampling interval
    addLog("Menyedot sampel gas...");
    _serialService.writeString('1');
    
    final samplingDurationSeconds = (settings.samplingInterval * 60).toInt();
    _startCountdown(samplingDurationSeconds, onFinished: () async {
      // Step 3: Send Stop, wait 20 seconds
      _serialService.writeString('3');
      addLog("Mempersiapkan pembacaan data sensor (tunggu 20 detik)...");
      
      _startCountdown(20, onFinished: () async {
        // Step 4: Collect data (60 lines)
        addLog("Mengambil data sensor...");
        final enabledPins = settings.getEnabledPins();
        
        final completer = Completer<void>();
        int count = 0;
        
        _serialSubscription = _serialService.lineStream.listen((line) {
          _lastRawLine = line;
          final parsed = SensorParser.parseLine(line, enabledPins);
          _currentLiveValues = parsed;
          _sensorDataPoints.add(parsed);
          
          count++;
          if (count >= 60) {
            _serialSubscription?.cancel();
            completer.complete();
          }
          notifyListeners();
        });

        await completer.future;
        addLog("Pembacaan data selesai. Menyimpan file CSV...");

        // Save CSV to Desktop or Documents
        await saveCsvFile(settings);

        // Exhale and clean
        await runFlushSequence();

        addLog("Akhir sampling.");
        _status = AppStatus.idle;
        notifyListeners();
      });
    });
  }

  /// Start prediction sequence calling the Flask API
  Future<void> startPrediction(SettingsProvider settings) async {
    if (isRunning) return;
    if (!_serialService.isConnected) {
      addLog("Error: Port serial belum terkoneksi!");
      return;
    }

    _status = AppStatus.predicting;
    _sensorDataPoints.clear();
    _predictionCategory = '-';
    _tvcScore = 0.0;

    final sampleLabel = "${settings.selectedSampleType} - ${settings.sampleName}";
    addLog("Mulai prediksi sampel [$sampleLabel]...");
    notifyListeners();

    // Step 1: Stop, wait 3 seconds
    _serialService.writeString('3');
    await Future.delayed(const Duration(seconds: 3));

    // Step 2: Inhale, countdown
    addLog("Menyedot gas sampel...");
    _serialService.writeString('1');
    
    final samplingDurationSeconds = (settings.samplingInterval * 60).toInt();
    _startCountdown(samplingDurationSeconds, onFinished: () async {
      // Step 3: Stop, wait 60 seconds (original Python delay before reading)
      _serialService.writeString('3');
      addLog("Mempersiapkan pembacaan sensor (tunggu 60 detik)...");
      
      _startCountdown(60, onFinished: () async {
        // Step 4: Collect data (60 lines)
        addLog("Membaca data sensor...");
        final enabledPins = settings.getEnabledPins();
        
        final completer = Completer<void>();
        int count = 0;
        
        _serialSubscription = _serialService.lineStream.listen((line) {
          _lastRawLine = line;
          final parsed = SensorParser.parseLine(line, enabledPins);
          _currentLiveValues = parsed;
          _sensorDataPoints.add(parsed);
          
          count++;
          if (count >= 60) {
            _serialSubscription?.cancel();
            completer.complete();
          }
          notifyListeners();
        });

        await completer.future;
        addLog("Data sensor berhasil dibaca. Mengirim ke API untuk klasifikasi & XAI...");

        // Step 5: Calculate averages across 60 rows
        final allPins = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'];
        final averages = SensorParser.calculateAverages(_sensorDataPoints, allPins);
        final averageValuesList = allPins.map((pin) => averages[pin]!).toList();

        // Step 6: Hit API
        try {
          final result = await _apiService.predict(
            deviceId: settings.deviceId,
            sensorValues: averageValuesList,
          );

          if (result['status'] == 'success') {
            _predictionCategory = result['classification'].toString();
            // Let's format the multiclass code into letter category
            if (_predictionCategory == '0') {
              _predictionCategory = 'A';
            } else if (_predictionCategory == '1') {
              _predictionCategory = 'C';
            } else if (_predictionCategory == '2') {
              _predictionCategory = 'D';
            } else if (_predictionCategory == '3') {
              _predictionCategory = 'E';
            } else if (_predictionCategory == '4') {
              _predictionCategory = 'F';
            }

            _tvcScore = double.tryParse(result['regression_value'].toString()) ?? 0.0;
            addLog("Hasil Prediksi Kategori: $_predictionCategory | Nilai Prediksi: ${_tvcScore.toStringAsFixed(2)}");
          } else {
            addLog("Gagal memproses prediksi: ${result['error'] ?? 'API Error'}");
          }
        } catch (e) {
          addLog("Error saat memproses API: $e");
        }

        // Clean cycle
        await runFlushSequence();

        addLog("Proses prediksi selesai.");
        _status = AppStatus.idle;
        notifyListeners();
      });
    });
  }

  /// Helper to save collected data points as CSV file
  Future<void> saveCsvFile(SettingsProvider settings) async {
    try {
      final sensorNamesMap = settings.getSensorNamesMap();
      final headers = sensorNamesMap.values.toList();
      final pins = sensorNamesMap.keys.toList();

      final List<List<dynamic>> rows = [headers];
      
      for (final point in _sensorDataPoints) {
        final row = pins.map((pin) => (point[pin] ?? 0.0).round()).toList();
        rows.add(row);
      }

      final csvData = const ListToCsvConverter().convert(rows);
      
      // Increment counter when saving new sampling file
      final currentCount = settings.incrementSamplingCount();

      // Determine file path
      Directory? baseDir;
      final customPath = settings.csvExportDirectory.trim();
      if (customPath.isNotEmpty) {
        try {
          final dir = Directory(customPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          baseDir = dir;
        } catch (dirErr) {
          addLog("Peringatan: Folder custom tidak dapat diakses ($dirErr), menggunakan folder default.");
        }
      }

      baseDir ??= await getDownloadsDirectory();
      baseDir ??= await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now()
          .toString()
          .replaceAll(":", "-")
          .replaceAll(" ", "_")
          .split(".")
          .first;

      final sampleTypePrefix = settings.selectedSampleType
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
      
      final rawSampleName = settings.sampleName.trim();
      final sampleNamePrefix = (rawSampleName.isEmpty ? 'sampel' : rawSampleName)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

      // Format: sampling_[jenis]_[nama]_[counter]_[timestamp].csv
      final fileName = "sampling_${sampleTypePrefix}_${sampleNamePrefix}_${currentCount}_$timestamp.csv";
      final filePath = "${baseDir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsString(csvData);
      
      addLog("File CSV berhasil disimpan: $fileName");
      addLog("Lokasi: $filePath");
    } catch (e) {
      addLog("Gagal menyimpan file CSV: $e");
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _serialSubscription?.cancel();
    super.dispose();
  }
}
