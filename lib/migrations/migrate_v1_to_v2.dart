import 'package:sqflite/sqflite.dart';

import '../constants/database_constants.dart';
import '../utils/logger.dart';

String _normalizeCategoryName(String? raw) {
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

Future<void> migrateV1toV2(Database db) async {
  AppLogger.info('Starting database migration: v1 -> v2');

  try {
    await db.transaction((txn) async {
      AppLogger.debug('Creating v2 schema tables if they do not exist...');

      // 1. Ensure v2 schema exists
      await txn.execute('''
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

      await txn.execute('''
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

      await txn.execute(
        'CREATE TABLE IF NOT EXISTS ${DbTables.settings}(key TEXT PRIMARY KEY, value TEXT)',
      );

      AppLogger.debug('Creating database indexes...');
      // 2. Create performance indexes
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(${DbCols.date})',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(${DbCols.categoryId})',
      );
      await txn.execute(
        'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(${DbCols.name})',
      );

      // 3. Check for presence of legacy table
      final legacy = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='${DbTables.legacySpendings}'",
      );

      if (legacy.isEmpty) {
        AppLogger.info(
          'No legacy `${DbTables.legacySpendings}` table found; skipping data transfer.',
        );
        return;
      }

      // 4. Read legacy records
      final List<Map<String, dynamic>> rows = await txn.query(
        DbTables.legacySpendings,
      );
      AppLogger.info(
        'Found ${rows.length} legacy records in `${DbTables.legacySpendings}` to migrate.',
      );

      if (rows.isEmpty) {
        AppLogger.debug('Legacy table is empty. Dropping legacy table.');
        await txn.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
        return;
      }

      final now = DateTime.now().toIso8601String();

      // 5. Build in-memory map of existing categories
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
        AppLogger.debug(
          'Inserting ${pendingNewCategories.length} new categories.',
        );
        final categoryResults = await categoryBatch.commit();
        for (var i = 0; i < pendingNewCategories.length; i++) {
          final generatedId = categoryResults[i] as int;
          categoryMap[pendingNewCategories[i]] = generatedId;
        }
      }

      // 7. Transfer legacy records into transactions table batch
      AppLogger.debug('Preparing transaction batch insert...');
      final transactionBatch = txn.batch();
      for (final r in rows) {
        final rawCat = r['category'] as String?;
        final catNameFinal = _normalizeCategoryName(rawCat);
        final categoryId = categoryMap[catNameFinal.toLowerCase()];

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

      // 8. Clean up legacy spendings table
      await txn.execute('DROP TABLE IF EXISTS ${DbTables.legacySpendings}');
      AppLogger.info('Dropped legacy table `${DbTables.legacySpendings}`.');
    });

    AppLogger.info('Migration v1 -> v2 completed successfully.');
  } catch (e, stackTrace) {
    AppLogger.error('Migration v1 -> v2 failed!', e, stackTrace);
    rethrow;
  }
}
