import 'dart:io';

import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/migrations/migrate_v1_to_v2.dart';
import 'package:expend_note/constants/database_constants.dart';

Future<void> main() async {
  // Initialize ffi for desktop testing
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final logger = Logger();

  final dbPath = join(Directory.current.path, 'test_migration.db');
  // Clean up any existing test DB
  try {
    final f = File(dbPath);
    if (await f.exists()) await f.delete();
  } catch (e) {
    logger.w('Failed to remove existing test DB: $e');
  }

  // Create a v1 database with legacy `spendings` table
  final dbV1 = await factory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE ${DbTables.legacySpendings}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, description TEXT)',
        );
        // Insert sample rows
        await db.insert('spendings', {
          'id': 1,
          'title': 'Groceries',
          'amount': 120.5,
          'date': DateTime.now().toIso8601String(),
          'category': 'Food',
          'description': 'Weekly groceries',
        });
        await db.insert('spendings', {
          'id': 2,
          'title': 'Bus fare',
          'amount': 15.0,
          'date': DateTime.now().toIso8601String(),
          'category': 'Transport',
          'description': null,
        });
      },
    ),
  );

  await dbV1.close();
  logger.i('Created v1 test DB at $dbPath');

  // Open with version 2 and run migration helper via onUpgrade
  final db = await factory.openDatabase(
    dbPath,
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) async {
        // If fresh create, set up v2 schema
        await db.execute(
          'CREATE TABLE ${DbTables.categories}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE, icon TEXT, color INTEGER, isPinned INTEGER DEFAULT 0, isArchived INTEGER DEFAULT 0, createdAt TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE ${DbTables.transactions}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, description TEXT, createdAt TEXT NOT NULL, FOREIGN KEY(categoryId) REFERENCES ${DbTables.categories}(id))',
        );
        await db.execute(
          'CREATE TABLE ${DbTables.settings}(key TEXT PRIMARY KEY, value TEXT)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        logger.i('Test harness running onUpgrade $oldVersion->$newVersion');
        await migrateV1toV2(db, logger);
      },
    ),
  );

  // Verify migration
  final catCountRes = await db.rawQuery('SELECT COUNT(*) AS c FROM categories');
  final txCountRes = await db.rawQuery(
    'SELECT COUNT(*) AS c FROM transactions',
  );
  final catCount = catCountRes.isNotEmpty ? (catCountRes.first['c'] as int) : 0;
  final txCount = txCountRes.isNotEmpty ? (txCountRes.first['c'] as int) : 0;

  logger.i(
    'Migration verification: categories=$catCount, transactions=$txCount',
  );

  if (txCount >= 2 && catCount >= 2) {
    logger.i('Migration test succeeded');
  } else {
    logger.e('Migration test failed');
  }

  await db.close();
}
