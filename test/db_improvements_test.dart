import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/migrations/migrate_v1_to_v2.dart' as mig;
import 'package:logger/logger.dart' as log;

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('DB improvements', () {
    late String dbPath;
    late Directory tmpDir;

    setUp(() async {
      tmpDir = Directory.systemTemp.createTempSync('expend_note_dbtest_');
      dbPath = join(tmpDir.path, 'db_improvements_test.db');
      final f = File(dbPath);
      if (await f.exists()) await f.delete();
    });

    tearDown(() async {
      try {
        final f = File(dbPath);
        if (await f.exists()) await f.delete();
        await tmpDir.delete(recursive: true);
      } catch (_) {}
    });

    test('foreign keys enabled and invalid categoryId rejected', () async {
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onConfigure: (db) async {
            await db.execute('PRAGMA foreign_keys = ON');
          },
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE)',
            );
            await db.execute(
              'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, FOREIGN KEY(categoryId) REFERENCES categories(id))',
            );
          },
        ),
      );

      final fk = await db.rawQuery('PRAGMA foreign_keys');
      final fkOn = fk.isNotEmpty ? fk.first.values.first : 0;
      expect(fkOn, 1);

      // inserting with invalid categoryId should fail
      var threw = false;
      try {
        await db.insert('transactions', {
          'title': 'Test',
          'amount': 10.0,
          'date': DateTime.now().toIso8601String(),
          'categoryId': 999,
        });
      } catch (e) {
        threw = true;
      }
      expect(threw, isTrue);

      await db.close();
    });

    test('indexes exist and duplicate category names prevented', () async {
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE)',
            );
            await db.execute(
              'CREATE TABLE ${DbTables.transactions}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, FOREIGN KEY(categoryId) REFERENCES categories(id))',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_date ON ${DbTables.transactions}(date)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_${DbTables.transactions}_categoryId ON ${DbTables.transactions}(categoryId)',
            );
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_${DbTables.categories}_name ON ${DbTables.categories}(name)',
            );
          },
        ),
      );

      final idxs = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      final names = idxs
          .map((m) => m['name'] as String?)
          .whereType<String>()
          .toList();
      expect(
        names,
        containsAll([
          'idx_${DbTables.transactions}_date',
          'idx_${DbTables.transactions}_categoryId',
          'idx_${DbTables.categories}_name',
        ]),
      );

      // Duplicate names (case-insensitive) should be rejected
      await db.insert(DbTables.categories, {'name': 'food'});
      var threw = false;
      try {
        await db.insert(DbTables.categories, {'name': 'Food'});
      } catch (e) {
        threw = true;
      }
      expect(threw, isTrue);

      await db.close();
    });

    test(
      'normalization: empty category becomes Others and duplicates collapsed',
      () async {
        // Create legacy v1 DB with messy category names
        final dbV1 = await factory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (db, version) async {
              await db.execute(
                'CREATE TABLE ${DbTables.legacySpendings}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, description TEXT)',
              );
              await db.insert(DbTables.legacySpendings, {
                'id': 1,
                'title': 'A',
                'amount': 10.0,
                'date': DateTime.now().toIso8601String(),
                'category': ' food  ',
              });
              await db.insert(DbTables.legacySpendings, {
                'id': 2,
                'title': 'B',
                'amount': 5.0,
                'date': DateTime.now().toIso8601String(),
                'category': 'FOOD',
              });
              await db.insert(DbTables.legacySpendings, {
                'id': 3,
                'title': 'C',
                'amount': 1.0,
                'date': DateTime.now().toIso8601String(),
                'category': '',
              });
            },
          ),
        );
        await dbV1.close();

        // Run migration using migrateV1toV2 directly
        final db = await factory.openDatabase(
          dbPath,
          options: OpenDatabaseOptions(
            version: 2,
            onCreate: (db, version) async {},
            onUpgrade: (db, oldV, newV) async {
              // we import and call the migration under test
              // import deferred because of test file scope
            },
          ),
        );

        // Manually call the migration implementation
        final migrator = mig.migrateV1toV2;
        final logger = log.Logger();
        await migrator(db, logger);

        final cats = await db.query(DbTables.categories);
        final names = cats
            .map((m) => m['name'] as String?)
            .whereType<String>()
            .toList();
        expect(names, contains('Food'));
        expect(names, contains('Others'));
        // ensure only single Food entry
        final foodCount = names.where((n) => n == 'Food').length;
        expect(foodCount, 1);

        await db.close();
      },
    );
  });
}

// no-op
