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
        version: 1,
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
}
