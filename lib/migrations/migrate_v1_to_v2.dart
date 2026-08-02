import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';

String _normalizeCategoryName(String? raw) {
  if (raw == null) return 'Others';
  var s = raw.trim();
  if (s.isEmpty) return 'Others';
  // collapse multiple spaces
  s = s.replaceAll(RegExp(r'\s+'), ' ');
  // Title case each word
  final parts = s.split(' ');
  final titled = parts
      .map((p) {
        final lower = p.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
      })
      .join(' ');
  return titled;
}

Future<void> migrateV1toV2(Database db, Logger logger) async {
  logger.i('Starting migration: v1 -> v2');

  // Run migration inside a transaction to ensure atomicity
  await db.transaction((txn) async {
    // Ensure v2 tables exist
    await txn.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.categories}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE COLLATE NOCASE,
        icon TEXT,
        color INTEGER,
        isPinned INTEGER DEFAULT 0,
        isArchived INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    await txn.execute('''
      CREATE TABLE IF NOT EXISTS ${DbTables.transactions}(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        categoryId INTEGER,
        description TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES ${DbTables.categories}(id)
      )
    ''');

    await txn.execute(
      'CREATE TABLE IF NOT EXISTS ${DbTables.settings}(key TEXT PRIMARY KEY, value TEXT)',
    );

    // Indexes
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})',
    );
    await txn.execute(
      'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})',
    );

    // If there is no legacy table, nothing to migrate
    final legacy = await txn.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbTables.legacySpendings}'",
    );
    if (legacy.isEmpty) {
      logger.i(
        'No legacy `${DbTables.legacySpendings}` table found; skipping migration.',
      );
      return;
    }

    // Helper to find or create category and return its id
    Future<int> ensureCategory(String name) async {
      final found = await txn.query(
        DbTables.categories,
        where: 'LOWER(${DbCols.name}) = LOWER(?)',
        whereArgs: [name],
        limit: 1,
      );
      if (found.isNotEmpty) return found.first['id'] as int;
      final now = DateTime.now().toIso8601String();
      return await txn.insert(DbTables.categories, {
        DbCols.name: name,
        DbCols.createdAt: now,
      });
    }

    // Read legacy rows
    final List<Map<String, dynamic>> rows = await txn.query(
      DbTables.legacySpendings,
    );
    logger.i(
      'Found ${rows.length} legacy ${DbTables.legacySpendings} to migrate',
    );

    // Migrate each row into transactions
    final now = DateTime.now().toIso8601String();
    for (final r in rows) {
      // Do not let one bad row fail the whole migration; still transaction ensures consistency.
      final rawCat = r['category'] as String?;
      final normalized = _normalizeCategoryName(rawCat);
      final catNameFinal = normalized.isEmpty ? 'Others' : normalized;
      final categoryId = await ensureCategory(catNameFinal);

      final map = <String, dynamic>{
        if (r['id'] != null) DbCols.id: r['id'],
        DbCols.title: r['title'] ?? '',
        DbCols.amount: (r['amount'] is int)
            ? (r['amount'] as int).toDouble()
            : r['amount'] ?? 0.0,
        DbCols.date: r['date'] ?? now,
        DbCols.categoryId: categoryId,
        DbCols.description: r['description'],
        DbCols.createdAt: now,
      };
      await txn.insert(
        DbTables.transactions,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Drop legacy table after migration
    try {
      await txn.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
      logger.i('Dropped legacy table `${DbTables.legacySpendings}`');
    } catch (e) {
      logger.w('Failed to drop legacy table: $e');
      rethrow;
    }
  });

  logger.i('Migration completed');
}
