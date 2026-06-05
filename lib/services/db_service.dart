import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/scan_record.dart';

class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'scans_database.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT,
        module_id TEXT,
        job_card TEXT,
        station TEXT,
        operator TEXT,
        reason TEXT,
        is_synced INTEGER DEFAULT 0,
        backend_id TEXT,
        time TEXT,
        saved_by TEXT
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE scans ADD COLUMN is_synced INTEGER DEFAULT 0');
        await db.execute('ALTER TABLE scans ADD COLUMN backend_id TEXT');
      } catch (e) {
        // Safe to ignore if columns already exist
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE scans ADD COLUMN time TEXT');
        await db.execute('ALTER TABLE scans ADD COLUMN saved_by TEXT');
      } catch (e) {
        // Safe to ignore if columns already exist
      }
    }
  }

  Future<int> insertScan(ScanRecord record) async {
    final db = await database;
    return await db.insert('scans', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ScanRecord>> getScansByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'date = ?',
      whereArgs: [date],
    );
    return List.generate(maps.length, (i) {
      return ScanRecord.fromMap(maps[i]);
    });
  }

  Future<List<ScanRecord>> searchScansByModuleId(String moduleIdQuery) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'module_id LIKE ?',
      whereArgs: ['%$moduleIdQuery%'],
    );
    return List.generate(maps.length, (i) {
      return ScanRecord.fromMap(maps[i]);
    });
  }

  Future<bool> isDuplicate(String moduleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'module_id = ?',
      whereArgs: [moduleId],
    );
    return maps.length > 1; // If it's saved more than once, it's a duplicate
  }

  Future<bool> exists(String moduleId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'module_id = ?',
      whereArgs: [moduleId],
    );
    return maps.isNotEmpty;
  }

  Future<List<ScanRecord>> getScansByDateRange(String startDate, String endDate) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
    return List.generate(maps.length, (i) {
      return ScanRecord.fromMap(maps[i]);
    });
  }

  Future<int> deleteScan(int id) async {
    final db = await database;
    return await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<ScanRecord>> getUnsyncedScans() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scans',
      where: 'is_synced = 0',
    );
    return List.generate(maps.length, (i) {
      return ScanRecord.fromMap(maps[i]);
    });
  }

  Future<int> updateScan(int localId, ScanRecord record) async {
    final db = await database;
    return await db.update(
      'scans',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<int> markAsSynced(int localId, String backendId) async {
    final db = await database;
    return await db.update(
      'scans',
      {
        'is_synced': 1,
        'backend_id': backendId,
      },
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('scans');
  }
}
