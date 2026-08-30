import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';
import '../migrations/migrate_v1_to_v2.dart';
import '../utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Singleton getter
  static DatabaseService get instance => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    _database = await _initDatabase();
    await DatabaseService.debugPrintDatabase();
    return _database!;
  }

  /// Testing helper: override the internal database instance.
  static void setTestDatabase(Database db) {
    _database = db;
  }

  /// Closes the database connection and resets the singleton instance cache.
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  Future<Database> _initDatabase() async {
    AppLogger.info('Initializing database...');
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, DbConfig.databaseFile);

    return await openDatabase(
      path,
      version: DbConfig.databaseVersion,
      onConfigure: (db) async {
        // Enable foreign key support in SQLite
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        AppLogger.info(
          'Creating v2 schema (transactions, categories, settings)...',
        );
        await _createTables(db);
        await _seedDefaultCategories(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        AppLogger.info('Upgrading DB from v$oldVersion to v$newVersion...');
        if (oldVersion < DbConfig.databaseVersion &&
            newVersion >= DbConfig.databaseVersion) {
          try {
            await migrateV1toV2(db);
          } catch (e, stackTrace) {
            AppLogger.error('Migration failed', e, stackTrace);
            rethrow;
          }
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.categories}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbCols.name} TEXT NOT NULL UNIQUE COLLATE NOCASE,
        icon TEXT,
        color INTEGER,
        isPinned INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        ${DbCols.createdAt} TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.transactions}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbCols.title} TEXT NOT NULL,
        ${DbCols.amount} REAL NOT NULL,
        ${DbCols.date} TEXT NOT NULL,
        ${DbCols.categoryId} INTEGER,
        ${DbCols.description} TEXT,
        ${DbCols.createdAt} TEXT NOT NULL,
        FOREIGN KEY(${DbCols.categoryId}) REFERENCES ${DbTables.categories}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.settings}(
        key TEXT PRIMARY KEY, 
        value TEXT
      )
    ''');

    // Index creation for fast lookups
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})',
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

    final batch = db.batch();
    for (final name in defaults) {
      batch.insert(DbTables.categories, {
        DbCols.name: name,
        'icon': null,
        'color': null,
        'isPinned': 0,
        'isArchived': 0,
        DbCols.createdAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  static Future<void> debugPrintDatabase() async {
    final db = await instance.database;

    AppLogger.info('========== DATABASE DEBUG ==========');

    final tables = await db.rawQuery('''
    SELECT name, sql
    FROM sqlite_master
    WHERE type = 'table'
      AND name NOT LIKE 'sqlite_%'
    ORDER BY name
  ''');

    for (final table in tables) {
      final tableName = table['name'] as String;

      AppLogger.info('TABLE: $tableName');
      AppLogger.info('SQL: ${table['sql']}');

      final columns = await db.rawQuery('PRAGMA table_info("$tableName")');

      for (final column in columns) {
        AppLogger.info(
          '  COLUMN: ${column['name']} '
          '| type=${column['type']} '
          '| notNull=${column['notnull']} '
          '| default=${column['dflt_value']}',
        );
      }

      final rows = await db.rawQuery('SELECT * FROM "$tableName" LIMIT 10');

      AppLogger.info('  PREVIEW (${rows.length} rows):');

      for (final row in rows) {
        AppLogger.info('    $row');
      }

      AppLogger.info('');
    }

    AppLogger.info('========== END DATABASE DEBUG ==========');
  }
}
