
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';
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
    String path = join(await getDatabasesPath(), DbConfig.databaseFile);
    return await openDatabase(
      path,
      version: DbConfig.databaseVersion,
      onConfigure: (db) async {
        // Enable foreign keys before anything else
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        _logger.i('Creating v2 schema (transactions, categories, settings)...');
        await db.execute(
          'CREATE TABLE IF NOT EXISTS ${DbTables.categories}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE, icon TEXT, color INTEGER, isPinned INTEGER DEFAULT 0, isArchived INTEGER DEFAULT 0, createdAt TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS ${DbTables.transactions}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, description TEXT, createdAt TEXT NOT NULL, FOREIGN KEY(categoryId) REFERENCES ${DbTables.categories}(id))',
        );
        await db.execute(
          'CREATE TABLE IF NOT EXISTS ${DbTables.settings}(key TEXT PRIMARY KEY, value TEXT)',
        );

        // Indexes for performance
        await db.execute('CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})');

        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        _logger.i('Upgrading DB from v$oldVersion to v$newVersion...');
        if (oldVersion < DbConfig.databaseVersion && newVersion >= DbConfig.databaseVersion) {
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
        await db.insert(DbTables.categories, {
          DbCols.name: name,
          'icon': null,
          'color': null,
          'isPinned': 0,
          'isArchived': 0,
          DbCols.createdAt: now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      } catch (_) {}
    }
  }
}
