
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../migrations/migrate_v1_to_v2.dart';

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

  /// Testing helper: override the internal database instance.
  /// Use this in tests to point the service to an in-memory or temp DB.
  static void setTestDatabase(Database db) {
    _database = db;
  }

  Future<Database> _initDatabase() async {
    _logger.i('Initializing database...');
    String path = join(await getDatabasesPath(), 'spending_database.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        _logger.i('Creating v2 schema (transactions, categories, settings)...');
        await db.execute(
          'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, icon TEXT, color INTEGER, isPinned INTEGER DEFAULT 0, isArchived INTEGER DEFAULT 0, createdAt TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, description TEXT, createdAt TEXT NOT NULL, FOREIGN KEY(categoryId) REFERENCES categories(id))',
        );
        await db.execute(
          'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)',
        );
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        _logger.i('Upgrading DB from v$oldVersion to v$newVersion...');
        if (oldVersion < 2 && newVersion >= 2) {
          try {
            await migrateV1toV2(db, _logger);
          } catch (e) {
            _logger.e('Migration failed: $e');
            rethrow;
          }
        }
      },
    );
  }

  static Future<void> _seedDefaultCategories(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      'Food',
      'Transport',
      'Shopping',
      'Bills',
      'Entertainment',
      'Education',
      'Healthcare',
      'Housing',
      'Investment',
      'Income',
      'Others',
    ];
    for (final name in defaults) {
      try {
        await db.insert('categories', {
          'name': name,
          'icon': null,
          'color': null,
          'isPinned': 0,
          'isArchived': 0,
          'createdAt': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (_) {}
    }
  }

  Future<int> _ensureCategory(Database db, String name) async {
    final List<Map<String, dynamic>> found = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    if (found.isNotEmpty) return found.first['id'] as int;
    final now = DateTime.now().toIso8601String();
    return await db.insert('categories', {'name': name, 'createdAt': now});
  }

  Future<bool> _hasTable(Database db, String tableName) async {
    final res = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [tableName],
    );
    return res.isNotEmpty;
  }
}
