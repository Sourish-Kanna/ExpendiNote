import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:expend_note/constants/database_constants.dart';

import 'package:expend_note/migrations/migrate_v1_to_v2.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final logger = Logger();

  group('migrate_v1_to_v2', () {
    late String dbPath;

    setUp(() async {
      final tmp = Directory.systemTemp.createTempSync('expend_note_test_');
      dbPath = join(tmp.path, 'test_migration.db');
      // Ensure clean
      final f = File(dbPath);
      if (await f.exists()) await f.delete();

      // Create v1 DB
      final dbV1 = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE ${DbTables.legacySpendings}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, description TEXT)',
            );
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
    });

    tearDown(() async {
      try {
        final f = File(dbPath);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    });

    test('migrates spendings into transactions and creates categories', () async {
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            // create v2 schema
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
          onUpgrade: (db, oldV, newV) async {
            await migrateV1toV2(db, logger);
          },
        ),
      );

      final catCountRes = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM categories',
      );
      final txCountRes = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM transactions',
      );
      final catCount = catCountRes.isNotEmpty
          ? (catCountRes.first['c'] as int)
          : 0;
      final txCount = txCountRes.isNotEmpty
          ? (txCountRes.first['c'] as int)
          : 0;

      expect(txCount, greaterThanOrEqualTo(2));
      expect(catCount, greaterThanOrEqualTo(2));

      await db.close();
    });
  });
}
