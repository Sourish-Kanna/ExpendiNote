import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';
import '../utils/logger.dart'; // Adjust path if necessary

String _normalizeCategoryName(String? raw) {
  if (raw == null) return 'Others';
  final s = raw.trim();
  if (s.isEmpty) return 'Others';

  // Collapse multiple spaces and Title Case each word efficiently
  return s
      .replaceAll(RegExp(r'\s+'), ' ')
      .split(' ')
      .map((p) {
        if (p.isEmpty) return '';
        final lower = p.toLowerCase();
        return lower[0].toUpperCase() + lower.substring(1);
      })
      .join(' ');
}

// Removed the Logger parameter since we now use the global AppLogger
Future<void> migrateV1toV2(Database db) async {
  AppLogger.info('Starting database migration: v1 -> v2');

  try {
    await db.transaction((txn) async {
      AppLogger.debug('Creating v2 tables if they do not exist...');
      // 1. Ensure v2 tables exist
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

      AppLogger.debug('Creating database indexes...');
      // 2. Create Indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})',
      );

      // 3. Check for legacy table using single quotes for string literal
      final legacy = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbTables.legacySpendings}'",
      );

      if (legacy.isEmpty) {
        AppLogger.info(
          'No legacy `${DbTables.legacySpendings}` table found; skipping data transfer.',
        );
        return;
      }

      // 4. Read legacy rows
      final List<Map<String, dynamic>> rows = await txn.query(
        DbTables.legacySpendings,
      );
      AppLogger.info(
        'Found ${rows.length} legacy records in ${DbTables.legacySpendings} to migrate.',
      );

      if (rows.isEmpty) {
        AppLogger.debug('Legacy table is empty. Dropping table.');
        await txn.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
        return;
      }

      final now = DateTime.now().toIso8601String();

      // 5. Pre-fetch existing categories into an in-memory map
      final existingCategoryRows = await txn.query(
        DbTables.categories,
        columns: ['id', DbCols.name],
      );
      final categoryMap = <String, int>{
        for (final cat in existingCategoryRows)
          (cat[DbCols.name] as String).toLowerCase(): cat['id'] as int,
      };

      AppLogger.debug(
        'Loaded ${categoryMap.length} existing categories from v2.',
      );

      // 6. Ensure all required categories exist
      final categoryBatch = txn.batch();
      final pendingNewCategories = <String>[];

      for (final r in rows) {
        final rawCat = r['category'] as String?;
        final normalized = _normalizeCategoryName(rawCat);
        final catNameFinal = normalized.isEmpty ? 'Others' : normalized;
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
        AppLogger.debug(
          'Inserting ${pendingNewCategories.length} new categories.',
        );
        final categoryResults = await categoryBatch.commit();
        for (var i = 0; i < pendingNewCategories.length; i++) {
          final generatedId = categoryResults[i] as int;
          categoryMap[pendingNewCategories[i]] = generatedId;
        }
      }

      // 7. Insert all transactions in a single batch
      AppLogger.debug('Preparing transaction batch insert...');
      final transactionBatch = txn.batch();
      for (final r in rows) {
        final rawCat = r['category'] as String?;
        final normalized = _normalizeCategoryName(rawCat);
        final catNameFinal = normalized.isEmpty ? 'Others' : normalized;
        final categoryId = categoryMap[catNameFinal.toLowerCase()];

        // Safe amount parsing handles legacy text, int, or real values
        final rawAmount = r['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

        final map = <String, dynamic>{
          if (r['id'] != null) DbCols.id: r['id'],
          DbCols.title: r['title'] ?? '',
          DbCols.amount: amount,
          DbCols.date: r['date'] ?? now,
          DbCols.categoryId: categoryId,
          DbCols.description: r['description'],
          DbCols.createdAt: now,
        };

        transactionBatch.insert(
          DbTables.transactions,
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await transactionBatch.commit(noResult: true);
      AppLogger.info('Successfully migrated ${rows.length} transactions.');

      // 8. Drop legacy table
      await txn.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
      AppLogger.info('Dropped legacy table `${DbTables.legacySpendings}`.');
    });

    AppLogger.info('Migration v1 -> v2 completed successfully.');
  } catch (e, stackTrace) {
    AppLogger.error('Migration v1 -> v2 failed!', e, stackTrace);
    rethrow;
  }
}
