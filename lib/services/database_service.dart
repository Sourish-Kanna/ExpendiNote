import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/spending.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  final Logger _logger = Logger();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    _logger.i('Initializing database...');
    String path = join(await getDatabasesPath(), 'spending_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        _logger.i('Creating spendings table...');
        return db.execute(
          'CREATE TABLE spendings(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, description TEXT)',
        );
      },
    );
  }

  Future<void> insertSpending(Spending spending) async {
    _logger.i('Inserting spending: ${spending.title}');
    final db = await database;
    await db.insert(
      'spendings',
      spending.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSpending(Spending spending) async {
    _logger.i('Updating spending with ID: ${spending.id}');
    final db = await database;
    await db.update(
      'spendings',
      spending.toMap(),
      where: 'id = ?',
      whereArgs: [spending.id],
    );
  }

  Future<List<Spending>> getSpendings() async {
    _logger.i('Fetching all spendings...');
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'spendings',
      orderBy: 'date DESC',
    );
    _logger.i('Fetched ${maps.length} entries.');
    return List.generate(maps.length, (i) {
      return Spending.fromMap(maps[i]);
    });
  }

  Future<void> deleteSpending(int id) async {
    _logger.i('Deleting spending with ID: $id');
    final db = await database;
    await db.delete('spendings', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOldSpendings(int months) async {
    _logger.i('Deleting spendings older than $months months...');
    final db = await database;
    final dateLimit = DateTime.now().subtract(Duration(days: months * 30));
    final dateLimitStr = dateLimit.toIso8601String();

    final count = await db.delete(
      'spendings',
      where: 'date < ?',
      whereArgs: [dateLimitStr],
    );
    _logger.i('Deleted $count old entries.');
    return count;
  }
}
