import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/database_helper.dart';
import 'settings_provider.dart';

class HistoryProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get history => List.unmodifiable(_history);
  bool get isLoading => _isLoading;

  HistoryProvider() {
    loadHistory();
  }

  /// Load all history from database
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    _history = await _dbHelper.getAllHistory();

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new sampling record to history
  Future<void> addRecord({
    required String sampleType,
    required String sampleName,
    required String profileName,
    required List<Map<String, double>> sensorDataPoints,
    required Map<String, String> sensorNamesMap,
    required int samplingCount,
  }) async {
    // Build CSV string from sensor data points
    final headers = sensorNamesMap.values.toList();
    final pins = sensorNamesMap.keys.toList();

    final List<List<dynamic>> rows = [headers];
    for (final point in sensorDataPoints) {
      final row = pins.map((pin) => (point[pin] ?? 0.0).round()).toList();
      rows.add(row);
    }
    final csvData = const ListToCsvConverter().convert(rows);

    // Store headers as JSON for later reconstruction
    final headersJson = jsonEncode(sensorNamesMap);

    await _dbHelper.insertSamplingRecord(
      sampleType: sampleType,
      sampleName: sampleName,
      profileName: profileName,
      sensorData: csvData,
      sensorHeaders: headersJson,
      timestamp: DateTime.now(),
      samplingCount: samplingCount,
    );

    await loadHistory();
  }

  /// Delete a single record
  Future<void> deleteRecord(int id) async {
    await _dbHelper.deleteRecord(id);
    await loadHistory();
  }

  /// Delete all records
  Future<void> deleteAllRecords() async {
    await _dbHelper.deleteAllRecords();
    await loadHistory();
  }

  /// Export a record to CSV file. Returns the file path on success, null on failure.
  Future<String?> exportToCsv(int id, SettingsProvider settings) async {
    try {
      final record = await _dbHelper.getRecordById(id);
      if (record == null) return null;

      final csvData = record['sensor_data'] as String;

      // Determine export directory from settings
      Directory? baseDir;
      final customPath = settings.csvExportDirectory.trim();
      if (customPath.isNotEmpty) {
        try {
          final dir = Directory(customPath);
          if (!await dir.exists()) {
            await dir.create(recursive: true);
          }
          baseDir = dir;
        } catch (_) {
          // Fallback to default
        }
      }

      baseDir ??= await getDownloadsDirectory();
      baseDir ??= await getApplicationDocumentsDirectory();

      // Build filename from record metadata
      final timestamp = (record['timestamp'] as String)
          .replaceAll(':', '-')
          .replaceAll(' ', '_')
          .split('.')
          .first
          .replaceAll('T', '_');

      final sampleType = (record['sample_type'] as String)
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

      final sampleName = (record['sample_name'] as String)
          .toLowerCase()
          .trim()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

      final count = record['sampling_count'] ?? 0;

      final fileName = "sampling_${sampleType}_${sampleName}_${count}_$timestamp.csv";
      final filePath = "${baseDir.path}/$fileName";
      final file = File(filePath);
      await file.writeAsString(csvData);

      return filePath;
    } catch (e) {
      debugPrint("Error exporting CSV: $e");
      return null;
    }
  }
}
