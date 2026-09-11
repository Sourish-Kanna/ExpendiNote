import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';
import '../utils/logger.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  /// Singleton getter
  static DatabaseService get instance => _instance;

  static Database? _database;
  static Future<Database>? _initializationFuture;

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;

    _initializationFuture ??= _initDatabase();

    try {
      final db = await _initializationFuture!;
      _database = db;
      return db;
    } catch (e) {
      // Reset the future so a subsequent call can retry initialization
      _initializationFuture = null;
      rethrow;
    }
  }

  /// Closes the database connection and resets the singleton instance cache.
  Future<void> closeDatabase() async {
    _initializationFuture = null;
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
        if (oldVersion < 2) {
          await _migrateV1toV2(db);
        }
        if (oldVersion < 3) {
          await _migrateV2toV3(db);
        }
      },
    );
  }

  static Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.categories}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ${DbCols.name} TEXT NOT NULL UNIQUE COLLATE NOCASE,
        ${DbCols.icon} TEXT,
        ${DbCols.color} INTEGER,
        ${DbCols.isPinned} INTEGER DEFAULT 0,
        ${DbCols.isArchived} INTEGER DEFAULT 0,
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
        DbCols.icon: null,
        DbCols.color: null,
        DbCols.isPinned: 0,
        DbCols.isArchived: 0,
        DbCols.createdAt: now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  /// Migrates the database from version 1 to version 2.
  static Future<void> _migrateV1toV2(Database db) async {
    AppLogger.info('Starting database migration: v1 -> v2');

    try {
      AppLogger.debug('Creating v2 schema tables for migration...');

      // Step 1: Create v2 tables (Independent of _createTables to satisfy Task 5)
      // v2 schema for categories did NOT include icon, color, pinned, or archived fields.
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DbTables.categories}(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          ${DbCols.name} TEXT NOT NULL UNIQUE COLLATE NOCASE,
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

      // Create indexes
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})',
      );

      // Step 2: Check for presence of legacy table
      final legacy = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbTables.legacySpendings}'",
      );

      if (legacy.isEmpty) {
        AppLogger.info('No legacy table found; skipping data transfer.');
        return;
      }

      // Step 3: Read legacy records
      final List<Map<String, dynamic>> rows = await db.query(
        DbTables.legacySpendings,
      );
      if (rows.isEmpty) {
        await db.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
        return;
      }

      final now = DateTime.now().toIso8601String();

      // Step 4: Build category map
      final existingCategoryRows = await db.query(
        DbTables.categories,
        columns: ['id', DbCols.name],
      );
      final categoryMap = <String, int>{
        for (final cat in existingCategoryRows)
          (cat[DbCols.name] as String).toLowerCase(): cat['id'] as int,
      };

      // Step 5: Ensure all required categories exist
      final categoryBatch = db.batch();
      final pendingNewCategories = <String>[];

      for (final r in rows) {
        final rawCat = r['category'] as String?;
        final catNameFinal = _normalizeCategoryName(rawCat);
        final lookupKey = catNameFinal.toLowerCase();

        if (!categoryMap.containsKey(lookupKey) &&
            !pendingNewCategories.contains(lookupKey)) {
          pendingNewCategories.add(lookupKey);
          categoryBatch.insert(DbTables.categories, {
            DbCols.name: catNameFinal,
            DbCols.createdAt: now,
          });
        }
      }

      if (pendingNewCategories.isNotEmpty) {
        final categoryResults = await categoryBatch.commit();
        for (var i = 0; i < pendingNewCategories.length; i++) {
          categoryMap[pendingNewCategories[i]] = categoryResults[i] as int;
        }
      }

      // Step 6: Transfer records
      final transactionBatch = db.batch();
      for (final r in rows) {
        final rawCat = r['category'] as String?;
        final catNameFinal = _normalizeCategoryName(rawCat);
        final categoryId = categoryMap[catNameFinal.toLowerCase()];

        final rawAmount = r['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

        transactionBatch.insert(DbTables.transactions, {
          if (r['id'] != null) DbCols.id: r['id'],
          DbCols.title: r['title'] ?? '',
          DbCols.amount: amount,
          DbCols.date: r['date'] ?? now,
          DbCols.categoryId: categoryId,
          DbCols.description: r['description'],
          DbCols.createdAt: now,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await transactionBatch.commit(noResult: true);

      // Step 7: Cleanup
      await db.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
      AppLogger.info('Migration v1 -> v2 completed successfully.');
    } catch (e, stackTrace) {
      AppLogger.error('Migration v1 -> v2 failed!', e, stackTrace);
      rethrow;
    }
  }

  static String _normalizeCategoryName(String? raw) {
    if (raw == null) return 'Others';
    final cleaned = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'Others';

    return cleaned
        .split(' ')
        .map((p) {
          if (p.isEmpty) return '';
          return p[0].toUpperCase() + p.substring(1).toLowerCase();
        })
        .join(' ');
  }

  /// Migrates the database from version 2 to version 3.
  /// Adds missing columns to categories table.
  static Future<void> _migrateV2toV3(Database db) async {
    AppLogger.info('Starting database migration: v2 -> v3');

    // Check existing columns to avoid duplicate column errors
    final tableInfo = await db.rawQuery(
      'PRAGMA table_info(${DbTables.categories})',
    );
    final existingColumns = tableInfo.map((c) => c['name'] as String).toSet();

    final columnsToAdd = {
      DbCols.icon: 'TEXT',
      DbCols.color: 'INTEGER',
      DbCols.isPinned: 'INTEGER DEFAULT 0',
      DbCols.isArchived: 'INTEGER DEFAULT 0',
    };

    for (final entry in columnsToAdd.entries) {
      if (!existingColumns.contains(entry.key)) {
        try {
          await db.execute(
            'ALTER TABLE ${DbTables.categories} ADD COLUMN ${entry.key} ${entry.value}',
          );
          AppLogger.info('Added column ${entry.key} to ${DbTables.categories}');
        } catch (e) {
          AppLogger.error('Failed to add column ${entry.key}: $e');
        }
      } else {
        AppLogger.debug(
          'Column ${entry.key} already exists in ${DbTables.categories}; skipping.',
        );
      }
    }
    AppLogger.info('Migration v2 -> v3 completed.');
  }
}
