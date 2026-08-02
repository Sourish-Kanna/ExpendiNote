import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';

Future<void> migrateV1toV2(Database db, Logger logger) async {
  logger.i('Starting migration: v1 -> v2');

  // Ensure v2 tables exist
  await db.execute('''
    CREATE TABLE IF NOT EXISTS categories(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      icon TEXT,
      color INTEGER,
      isPinned INTEGER DEFAULT 0,
      isArchived INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS transactions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      amount REAL NOT NULL,
      date TEXT NOT NULL,
      categoryId INTEGER,
      description TEXT,
      createdAt TEXT NOT NULL,
      FOREIGN KEY(categoryId) REFERENCES categories(id)
    )
  ''');

  await db.execute(
    'CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT)',
  );

  // If there is no legacy table, nothing to migrate
  final legacy = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name='spendings'",
  );
  if (legacy.isEmpty) {
    logger.i('No legacy `spendings` table found; skipping migration.');
    return;
  }

  // Helper to find or create category and return its id
  Future<int> ensureCategory(String name) async {
    final found = await db.query(
      'categories',
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    if (found.isNotEmpty) return found.first['id'] as int;
    final now = DateTime.now().toIso8601String();
    return await db.insert('categories', {'name': name, 'createdAt': now});
  }

  // Read legacy rows
  final List<Map<String, dynamic>> rows = await db.query('spendings');
  logger.i('Found ${rows.length} legacy spendings to migrate');

  // Migrate each row into transactions
  final now = DateTime.now().toIso8601String();
  for (final r in rows) {
    try {
      final categoryName = (r['category'] as String?)?.trim() ?? '';
      final catNameFinal = categoryName.isEmpty ? 'Others' : categoryName;
      final categoryId = await ensureCategory(catNameFinal);

      final map = <String, dynamic>{
        if (r['id'] != null) 'id': r['id'],
        'title': r['title'] ?? '',
        'amount': (r['amount'] is int)
            ? (r['amount'] as int).toDouble()
            : r['amount'] ?? 0.0,
        'date': r['date'] ?? now,
        'categoryId': categoryId,
        'description': r['description'],
        'createdAt': now,
      };
      await db.insert(
        'transactions',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      logger.w('Failed to migrate row ${r['id']}: $e\n$st');
    }
  }

  // Drop legacy table after migration
  try {
    await db.execute('DROP TABLE IF EXISTS spendings');
    logger.i('Dropped legacy table `spendings`');
  } catch (e) {
    logger.w('Failed to drop legacy table: $e');
  }

  logger.i('Migration completed');
}
