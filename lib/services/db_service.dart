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
      version: 1,
      onCreate: _onCreate,
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
        reason TEXT
      )
    ''');
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
}
