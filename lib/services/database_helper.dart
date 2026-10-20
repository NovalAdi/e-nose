import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

  /// Initialize the database. Must be called once at app start.
  Future<void> initDatabase() async {
    if (_database != null) return;

    // Initialize FFI for desktop platforms
    sqfliteFfiInit();

    final dbPath = await databaseFactoryFfi.getDatabasesPath();
    final path = p.join(dbPath, 'enose_history.db');

    _database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE sampling_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sample_type TEXT NOT NULL,
            sample_name TEXT NOT NULL,
            profile_name TEXT NOT NULL,
            sensor_data TEXT NOT NULL,
            sensor_headers TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            sampling_count INTEGER NOT NULL,
              notes TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE sensor_profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_name TEXT NOT NULL UNIQUE,
            config_data TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE app_settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT NOT NULL
            )
          ''');
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE sensor_profiles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profile_name TEXT NOT NULL UNIQUE,
              config_data TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE app_settings (
              key TEXT PRIMARY KEY,
              value TEXT NOT NULL,
              updated_at TEXT NOT NULL
              )
            ''');
          }
        },
      ),
    );
  }

  Database get _db {
    if (_database == null) {
      throw StateError(
        'Database belum diinisialisasi. Panggil initDatabase() terlebih dahulu.',
      );
    }
    return _database!;
  }

  /// Insert a new sampling record
  Future<int> insertSamplingRecord({
    required String sampleType,
    required String sampleName,
    required String profileName,
    required String sensorData,
    required String sensorHeaders,
    required DateTime timestamp,
    required int samplingCount,
    String? notes,
  }) async {
    return await _db.insert('sampling_history', {
      'sample_type': sampleType,
      'sample_name': sampleName,
      'profile_name': profileName,
      'sensor_data': sensorData,
      'sensor_headers': sensorHeaders,
      'timestamp': timestamp.toIso8601String(),
      'sampling_count': samplingCount,
      'notes': notes,
    });
  }

  /// Get all history records sorted by timestamp descending
  Future<List<Map<String, dynamic>>> getAllHistory() async {
    return await _db.query('sampling_history', orderBy: 'timestamp DESC');
  }

  /// Get a single record by ID
  Future<Map<String, dynamic>?> getRecordById(int id) async {
    final results = await _db.query(
      'sampling_history',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Delete a single record by ID
  Future<int> deleteRecord(int id) async {
    return await _db.delete(
      'sampling_history',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all records
  Future<int> deleteAllRecords() async {
    return await _db.delete('sampling_history');
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  /// Save a sensor configuration profile
  Future<int> saveSensorProfile({
    required String profileName,
    required String configData,
  }) async {
    final now = DateTime.now().toIso8601String();
    try {
      return await _db.insert('sensor_profiles', {
        'profile_name': profileName,
        'config_data': configData,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      // If insert fails due to unique constraint, update instead
      return await _db.update(
        'sensor_profiles',
        {'config_data': configData, 'updated_at': now},
        where: 'profile_name = ?',
        whereArgs: [profileName],
      );
    }
  }

  /// Get all sensor profiles
  Future<List<Map<String, dynamic>>> getAllSensorProfiles() async {
    return await _db.query('sensor_profiles', orderBy: 'profile_name ASC');
  }

  /// Get a sensor profile by name
  Future<Map<String, dynamic>?> getSensorProfile(String profileName) async {
    final results = await _db.query(
      'sensor_profiles',
      where: 'profile_name = ?',
      whereArgs: [profileName],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Delete a sensor profile
  Future<int> deleteSensorProfile(String profileName) async {
    return await _db.delete(
      'sensor_profiles',
      where: 'profile_name = ?',
      whereArgs: [profileName],
    );
  }

  /// Save an app setting
  Future<void> saveSetting(String key, String value) async {
    final now = DateTime.now().toIso8601String();
    await _db.insert(
      'app_settings',
      {
        'key': key,
        'value': value,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get an app setting
  Future<String?> getSetting(String key) async {
    final results = await _db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    return results.isNotEmpty ? results.first['value'] as String : null;
  }

  /// Get all app settings
  Future<Map<String, String>> getAllSettings() async {
    final results = await _db.query('app_settings');
    return Map.fromEntries(
      results.map((row) => MapEntry(
        row['key'] as String,
        row['value'] as String,
      )),
    );
  }
}
