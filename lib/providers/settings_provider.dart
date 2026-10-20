import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sensor_config.dart';
import '../services/serial_service.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class SettingsProvider with ChangeNotifier {
  final SerialService _serialService;
  final ApiService _apiService;

  String _selectedPort = '';
  double _samplingInterval = 60.0;
  String _selectedSampleType = 'Teh';
  final List<String> _sampleTypes = ['Teh', 'Kopi'];
  String _sampleName = 'Hitam';
  int _samplingCount = 0;
  String _deviceId = 'e-nose_2';
  String _apiUrl = 'http://localhost:5000';
  String _csvExportDirectory = '';
  String _defaultExportDirectory = '';

  final Map<String, SensorConfig> _sensorConfigs = {};
  final Map<String, Map<String, SensorConfig>> _savedProfiles = {};
  String _currentProfile = "Config Sensor V2";
  String _lastActiveProfile = "Config Sensor V2";
  bool _hasUnsavedChanges = false;

  SettingsProvider(this._serialService, this._apiService) {
    _initDefaultProfiles();
    _refreshPorts();
    _initDefaultExportDirectory();
    _loadProfilesFromDatabase();
    _loadAppSettings();
  }

  // Getters
  String get selectedPort => _selectedPort;
  double get samplingInterval => _samplingInterval;
  String get selectedSampleType => _selectedSampleType;
  List<String> get sampleTypes => _sampleTypes;
  String get sampleName => _sampleName;
  int get samplingCount => _samplingCount;
  String get deviceId => _deviceId;
  String get apiUrl => _apiUrl;
  Map<String, SensorConfig> get sensorConfigs => _sensorConfigs;

  List<String> get availablePorts => _serialService.getAvailablePorts();
  bool get isConnected => _serialService.isConnected;

  // Profile Management Getters
  List<String> get profileNames => _savedProfiles.keys.toList();
  String get currentProfile => _currentProfile;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Get port description
  String getPortDescription(String name) {
    return _serialService.getPortDescription(name);
  }

  set selectedPort(String value) {
    _selectedPort = value;
    notifyListeners();
  }

  set samplingInterval(double value) {
    if (value > 0) {
      _samplingInterval = value;
      _saveAppSetting('sampling_interval', value.toString());
      notifyListeners();
    }
  }

  set selectedSampleType(String value) {
    if (_sampleTypes.contains(value) && _selectedSampleType != value) {
      _selectedSampleType = value;
      _samplingCount = 0; // Reset counter on sample type change
      notifyListeners();
    }
  }

  set sampleName(String value) {
    final trimmed = value.trim();
    if (_sampleName != trimmed) {
      _sampleName = trimmed;
      _samplingCount = 0; // Reset counter on sample name change
      notifyListeners();
    }
  }

  int incrementSamplingCount() {
    _samplingCount++;
    notifyListeners();
    return _samplingCount;
  }

  void resetSamplingCount() {
    _samplingCount = 0;
    notifyListeners();
  }

  set deviceId(String value) {
    _deviceId = value;
    _saveAppSetting('device_id', value);
    notifyListeners();
  }

  set apiUrl(String value) {
    _apiUrl = value;
    _apiService.updateBaseUrl(_apiUrl);
    _saveAppSetting('api_url', value);
    notifyListeners();
  }

  // CSV Export Directory Management
  String get csvExportDirectory => _csvExportDirectory;
  String get defaultExportDirectory => _defaultExportDirectory;

  set csvExportDirectory(String value) {
    final trimmed = value.trim();
    if (_csvExportDirectory != trimmed) {
      _csvExportDirectory = trimmed;
      _saveAppSetting('csv_export_directory', trimmed);
      notifyListeners();
    }
  }

  /// Get the system default downloads directory, fallback to documents directory
  Future<String> getDefaultExportDirectory() async {
    try {
      Directory? dir = await getDownloadsDirectory();
      dir ??= await getApplicationDocumentsDirectory();
      return dir.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> _initDefaultExportDirectory() async {
    final defaultDir = await getDefaultExportDirectory();
    if (defaultDir.isNotEmpty) {
      _defaultExportDirectory = defaultDir;
      if (_csvExportDirectory.isEmpty) {
        _csvExportDirectory = defaultDir;
        notifyListeners();
      }
    }
  }

  Future<void> resetCsvExportDirectoryToDefault() async {
    if (_defaultExportDirectory.isEmpty) {
      _defaultExportDirectory = await getDefaultExportDirectory();
    }
    if (_defaultExportDirectory.isNotEmpty) {
      _csvExportDirectory = _defaultExportDirectory;
      notifyListeners();
    }
  }

  Future<bool> pickCsvExportDirectory() async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: "Pilih Folder Simpan CSV",
        initialDirectory: _csvExportDirectory.isNotEmpty
            ? _csvExportDirectory
            : (_defaultExportDirectory.isNotEmpty
                  ? _defaultExportDirectory
                  : null),
      );
      if (selectedPath != null && selectedPath.trim().isNotEmpty) {
        csvExportDirectory = selectedPath.trim();
        return true;
      }
    } catch (e) {
      debugPrint("Error picking directory: $e");
    }
    return false;
  }

  /// Initialize default profiles with Config Sensor V2 as default
  void _initDefaultProfiles() {
    final pins = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5', 'A6', 'A7', 'A8', 'A9'];

    // 1. Config Sensor V2 (From config sensor v2.hbb - Default)
    final v2SensorMap = {
      'A0': 'MQ6',
      'A1': 'MQ4',
      'A2': 'TGS2620',
      'A3': 'MQ5',
      'A4': 'MQ2',
      'A5': 'TGS2602',
      'A6': 'MQ7',
      'A7': 'MQ3',
      'A8': 'MQ135',
      'A9': 'MQ138',
    };

    final profileV2 = <String, SensorConfig>{};
    for (final pin in pins) {
      profileV2[pin] = SensorConfig(
        pin: pin,
        enabled: true,
        name: v2SensorMap[pin] ?? pin,
        type: 'Custom',
      );
    }
    _savedProfiles["Config Sensor V2"] = profileV2;

    // 2. Setting Default Pin (A0..A9)
    final profileDefault = <String, SensorConfig>{};
    for (final pin in pins) {
      profileDefault[pin] = SensorConfig(
        pin: pin,
        enabled: true,
        name: pin,
        type: 'Default',
      );
    }
    _savedProfiles["Setting Default Pin"] = profileDefault;

    // 3. Setting 5 Sensor (A0..A4)
    final profile5 = <String, SensorConfig>{};
    for (int i = 0; i < pins.length; i++) {
      final pin = pins[i];
      final isEnabled = i < 5;
      profile5[pin] = SensorConfig(
        pin: pin,
        enabled: isEnabled,
        name: isEnabled ? pin : 'OFF',
        type: isEnabled ? 'Default' : 'OFF',
      );
    }
    _savedProfiles["Setting 5 Sensor"] = profile5;

    // Load Config Sensor V2 by default
    selectProfile("Config Sensor V2");
  }

  /// Load a saved profile into active sensorConfigs
  void selectProfile(String profileName) {
    if (_savedProfiles.containsKey(profileName)) {
      _sensorConfigs.clear();
      final profile = _savedProfiles[profileName]!;
      for (final entry in profile.entries) {
        _sensorConfigs[entry.key] = entry.value.clone();
      }
      _currentProfile = profileName;
      _lastActiveProfile = profileName;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Mark current configuration as modified (unsaved "New")
  void markModified() {
    _currentProfile = "New";
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Save current configuration under a given profile name
  Future<void> saveCurrentAsProfile(String name) async {
    final cleanName = name.trim().isEmpty
        ? "Setting ${_savedProfiles.length + 1}"
        : name.trim();
    final profile = <String, SensorConfig>{};
    for (final entry in _sensorConfigs.entries) {
      profile[entry.key] = entry.value.clone();
    }
    _savedProfiles[cleanName] = profile;
    _currentProfile = cleanName;
    _lastActiveProfile = cleanName;
    _hasUnsavedChanges = false;

    // Save to database
    await _saveProfileToDatabase(cleanName, profile);
    notifyListeners();
  }

  /// Discard unsaved changes and restore previous active profile
  void discardChanges() {
    if (_savedProfiles.containsKey(_lastActiveProfile)) {
      selectProfile(_lastActiveProfile);
    } else if (_savedProfiles.isNotEmpty) {
      selectProfile(_savedProfiles.keys.first);
    }
  }

  /// Scan for available serial ports and auto-select first one if needed
  void _refreshPorts() {
    final ports = availablePorts;
    if (ports.isNotEmpty) {
      if (_selectedPort.isEmpty || !ports.contains(_selectedPort)) {
        _selectedPort = ports.first;
      }
    } else {
      _selectedPort = '';
    }
    notifyListeners();
  }

  void refreshPortsList() {
    _refreshPorts();
  }

  /// Handle sensor type dropdown changes (Default, OFF, Custom)
  void onSensorTypeChange(String pin, String type) {
    final config = _sensorConfigs[pin];
    if (config == null) return;

    config.type = type;
    if (type == 'OFF') {
      config.enabled = false;
      config.name = 'OFF';
    } else if (type == 'Default') {
      config.enabled = true;
      config.name = pin;
    } else if (type == 'Custom') {
      config.enabled = true;
    }
    markModified();
  }

  /// Handle enabled checkbox change
  void onCheckboxChange(String pin, bool enabled) {
    final config = _sensorConfigs[pin];
    if (config == null) return;

    config.enabled = enabled;
    if (!enabled) {
      config.type = 'OFF';
      config.name = 'OFF';
    } else {
      if (config.type == 'OFF') {
        config.type = 'Default';
        config.name = pin;
      }
    }
    markModified();
  }

  /// Update custom sensor name text
  void updateSensorName(String pin, String name) {
    final config = _sensorConfigs[pin];
    if (config == null) return;
    config.name = name;
    markModified();
  }

  /// Return List of enabled pins (e.g. ['A0', 'A1', ...])
  List<String> getEnabledPins() {
    return _sensorConfigs.entries
        .where((entry) => entry.value.enabled)
        .map((entry) => entry.key)
        .toList();
  }

  /// Return map of active pin name to display name
  Map<String, String> getSensorNamesMap() {
    return Map.fromEntries(
      _sensorConfigs.entries
          .where((entry) => entry.value.enabled)
          .map((entry) => MapEntry(entry.key, entry.value.name)),
    );
  }

  /// Toggle or attempt serial connection only
  Future<String> toggleConnection() async {
    if (isConnected) {
      _serialService.disconnect();
      notifyListeners();
      return "Koneksi port $_selectedPort diputuskan.";
    }

    if (_selectedPort.isEmpty) {
      return "Gagal: Belum ada port serial yang dipilih.";
    }

    final success = _serialService.connect(_selectedPort);
    notifyListeners();
    if (success) {
      return "Berhasil terhubung ke port $_selectedPort!";
    } else {
      return "Gagal menghubungkan ke $_selectedPort. Pastikan kabel & perangkat terpasang.";
    }
  }

  /// Export configuration to a .hbb file
  Future<bool> exportSettings(String filePath) async {
    try {
      final file = File(filePath);
      final sink = file.openWrite();

      sink.writeln("# T-NOSE Sensor Configuration File");
      sink.writeln("# Generated on: ${DateTime.now()}");
      sink.writeln("# Format: PIN=ENABLED,NAME,TYPE");
      sink.writeln("");

      for (final entry in _sensorConfigs.entries) {
        final pin = entry.key;
        final config = entry.value;
        final enabled = config.enabled ? "1" : "0";
        sink.writeln("$pin=$enabled,${config.name},${config.type}");
      }

      await sink.flush();
      await sink.close();
      return true;
    } catch (e) {
      debugPrint("Error exporting settings: $e");
      return false;
    }
  }

  /// Import configuration from a .hbb file
  Future<bool> importSettings(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final lines = await file.readAsLines();
      final importedConfig = <String, SensorConfig>{};

      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        if (trimmed.contains('=')) {
          final parts = trimmed.split('=');
          final pin = parts[0].trim();
          final configStr = parts[1].trim();

          final configParts = configStr.split(',');
          if (configParts.length >= 3) {
            final enabled = configParts[0].trim() == '1';
            final name = configParts[1].trim();
            final type = configParts[2].trim();

            importedConfig[pin] = SensorConfig(
              pin: pin,
              enabled: enabled,
              name: name,
              type: type,
            );
          }
        }
      }

      if (importedConfig.isNotEmpty) {
        final fileName = file.uri.pathSegments.last.replaceAll('.hbb', '');
        final profileName = fileName.isNotEmpty ? fileName : "Imported Setting";

        _savedProfiles[profileName] = importedConfig;
        selectProfile(profileName);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Error importing settings: $e");
      return false;
    }
  }

  /// Load all profiles from database
  Future<void> _loadProfilesFromDatabase() async {
    try {
      final db = DatabaseHelper();
      final profiles = await db.getAllSensorProfiles();

      for (final row in profiles) {
        final profileName = row['profile_name'] as String;
        final configData = row['config_data'] as String;

        try {
          final List<dynamic> configList = jsonDecode(configData);
          final profile = <String, SensorConfig>{};

          for (final item in configList) {
            final config = SensorConfig.fromJson(item as Map<String, dynamic>);
            profile[config.pin] = config;
          }

          _savedProfiles[profileName] = profile;
        } catch (e) {
          debugPrint('Error parsing profile $profileName: $e');
        }
      }

      // If we loaded profiles and current profile exists, select it
      if (_savedProfiles.containsKey(_currentProfile)) {
        selectProfile(_currentProfile);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profiles from database: $e');
    }
  }

  /// Save a profile to database
  Future<void> _saveProfileToDatabase(
    String profileName,
    Map<String, SensorConfig> profile,
  ) async {
    try {
      final configList = profile.values
          .map((config) => config.toJson())
          .toList();
      final configData = jsonEncode(configList);

      final db = DatabaseHelper();
      await db.saveSensorProfile(
        profileName: profileName,
        configData: configData,
      );
    } catch (e) {
      debugPrint('Error saving profile to database: $e');
    }
  }

  /// Delete a profile from memory and database
  Future<bool> deleteProfile(String profileName) async {
    // Don't allow deleting default profiles
    if (profileName == "Config Sensor V2" ||
        profileName == "Setting Default Pin" ||
        profileName == "Setting 5 Sensor") {
      return false;
    }

    try {
      final db = DatabaseHelper();
      await db.deleteSensorProfile(profileName);
      _savedProfiles.remove(profileName);

      // If we deleted the current profile, switch to default
      if (_currentProfile == profileName) {
        selectProfile("Config Sensor V2");
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting profile: $e');
      return false;
    }
  }

  /// Load app settings from database
  Future<void> _loadAppSettings() async {
    try {
      final db = DatabaseHelper();
      final settings = await db.getAllSettings();
      
      if (settings.containsKey('device_id')) {
        _deviceId = settings['device_id']!;
      }
      if (settings.containsKey('api_url')) {
        _apiUrl = settings['api_url']!;
        _apiService.updateBaseUrl(_apiUrl);
      }
      if (settings.containsKey('csv_export_directory')) {
        _csvExportDirectory = settings['csv_export_directory']!;
      }
      if (settings.containsKey('sampling_interval')) {
        _samplingInterval = double.tryParse(settings['sampling_interval']!) ?? 60.0;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading app settings: $e');
    }
  }

  /// Save a single app setting to database
  Future<void> _saveAppSetting(String key, String value) async {
    try {
      final db = DatabaseHelper();
      await db.saveSetting(key, value);
    } catch (e) {
      debugPrint('Error saving app setting $key: $e');
    }
  }
}
