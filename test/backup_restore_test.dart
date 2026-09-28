import 'package:expend_note/constants/app_constants.dart';
import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/services/export_migrations/export_migration_service.dart';
import 'package:expend_note/services/import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('ExportMigrationService Tests', () {
    test('Migrates legacy flat JSON list into Export Version 1 structure', () {
      final legacyList = [
        {
          'id': 180,
          'title': 'Bus Pass',
          'amount': 45.0,
          'date': '2026-09-25T10:00:00Z',
          'category': 'Transport',
          'description': 'Monthly pass',
          'includeInSpendingAnalysis': true,
        },
        {
          'id': 181,
          'title': 'Groceries',
          'amount': 120.5,
          'date': '2026-09-26T14:30:00Z',
          'category': 'Food',
          'description': 'Supermarket',
          'includeInSpendingAnalysis': true,
        },
      ];

      final migrated = ExportMigrationService.migrateToLatest(legacyList);

      expect(migrated['format'], equals('ExpendiNote Backup'));
      expect(migrated['export_version'], equals(1));
      expect(migrated['app_version'], equals(AppConstants.appVersion));
      expect(migrated['data'], isA<Map>());

      final data = migrated['data'] as Map;
      final categories = data['categories'] as List;
      final transactions = data['transactions'] as List;

      expect(categories.length, equals(2));
      expect(transactions.length, equals(2));

      expect(transactions[0]['title'], equals('Bus Pass'));
      expect(transactions[0]['amount'], equals(45.0));
      expect(transactions[0]['category_name'], equals('Transport'));

      expect(transactions[1]['title'], equals('Groceries'));
      expect(transactions[1]['amount'], equals(120.5));
      expect(transactions[1]['category_name'], equals('Food'));

      final validationError = ExportMigrationService.validateBackupData(
        migrated,
      );
      expect(validationError, isNull);
    });

    test(
      'Throws UnsupportedExportVersionException when export_version > current supported version',
      () {
        final futureBackup = {
          'format': 'ExpendiNote Backup',
          'export_version': 99,
          'app_version': '99.0.0',
          'exported_at': '2030-01-01T00:00:00Z',
          'data': {'categories': [], 'transactions': [], 'settings': []},
        };

        expect(
          () => ExportMigrationService.migrateToLatest(futureBackup),
          throwsA(isA<UnsupportedExportVersionException>()),
        );
      },
    );

    test('Validates backup data structure correctly', () {
      final validMap = {
        'format': 'ExpendiNote Backup',
        'export_version': 1,
        'app_version': AppConstants.appVersion,
        'exported_at': '2026-09-25T10:00:00Z',
        'data': {
          'categories': [
            {'id': 1, 'name': 'Food'},
          ],
          'transactions': [
            {
              'id': 1,
              'title': 'Lunch',
              'amount': 12.0,
              'date': '2026-09-25T10:00:00Z',
              'category_id': 1,
            },
          ],
          'settings': [],
        },
      };

      expect(ExportMigrationService.validateBackupData(validMap), isNull);

      final invalidMap = {
        'format': 'ExpendiNote Backup',
        'export_version': 1,
        'data': {'categories': 'not_a_list', 'transactions': []},
      };

      expect(
        ExportMigrationService.validateBackupData(invalidMap),
        contains('"categories" must be a list'),
      );
    });
  });

  group('Database Restore Logic Tests', () {
    late Database db;

    setUp(() async {
      await DatabaseService.instance.closeDatabase();
      db = await openDatabase(
        inMemoryDatabasePath,
        version: DbConfig.databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ${DbTables.categories}(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbCols.name} TEXT NOT NULL UNIQUE COLLATE NOCASE,
              ${DbCols.icon} TEXT,
              ${DbCols.color} INTEGER,
              ${DbCols.isPinned} INTEGER DEFAULT 0,
              ${DbCols.isArchived} INTEGER DEFAULT 0,
              ${DbCols.includeInSpendingAnalysis} INTEGER DEFAULT 1,
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
              ${DbCols.includeInSpendingAnalysis} INTEGER DEFAULT 1,
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
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'Repeated restore does not create duplicate transactions or categories',
      () async {
        final backup = {
          'format': 'ExpendiNote Backup',
          'export_version': 1,
          'app_version': AppConstants.appVersion,
          'exported_at': '2026-09-25T10:00:00Z',
          'data': {
            'categories': [
              {'id': 1, 'name': 'Dining'},
            ],
            'transactions': [
              {
                'id': 100,
                'title': 'Dinner',
                'amount': 35.0,
                'date': '2026-09-25T19:00:00Z',
                'category_id': 1,
                'category_name': 'Dining',
              },
            ],
            'settings': [
              {'key': 'theme_mode', 'value': 'dark'},
            ],
          },
        };

        final migrated1 = ExportMigrationService.migrateToLatest(backup);
        final data = Map<String, dynamic>.from(migrated1['data'] as Map);
        final rawCategories = data['categories'] as List;
        final rawTransactions = data['transactions'] as List;

        await db.transaction((txn) async {
          await txn.delete(DbTables.transactions);
          await txn.delete(DbTables.categories);

          for (final cat in rawCategories) {
            await txn.insert(DbTables.categories, {
              DbCols.id: cat['id'],
              DbCols.name: cat['name'],
              DbCols.createdAt: DateTime.now().toIso8601String(),
            });
          }
          for (final tx in rawTransactions) {
            await txn.insert(DbTables.transactions, {
              DbCols.id: tx['id'],
              DbCols.title: tx['title'],
              DbCols.amount: tx['amount'],
              DbCols.date: tx['date'],
              DbCols.categoryId: tx['category_id'],
              DbCols.createdAt: DateTime.now().toIso8601String(),
            });
          }
        });

        var catCount =
            (await db.rawQuery(
                  'SELECT COUNT(*) FROM ${DbTables.categories}',
                )).first.values.first
                as int;
        var txCount =
            (await db.rawQuery(
                  'SELECT COUNT(*) FROM ${DbTables.transactions}',
                )).first.values.first
                as int;
        expect(catCount, equals(1));
        expect(txCount, equals(1));

        // Second restore of exact same backup
        await db.transaction((txn) async {
          await txn.delete(DbTables.transactions);
          await txn.delete(DbTables.categories);

          for (final cat in rawCategories) {
            await txn.insert(DbTables.categories, {
              DbCols.id: cat['id'],
              DbCols.name: cat['name'],
              DbCols.createdAt: DateTime.now().toIso8601String(),
            });
          }
          for (final tx in rawTransactions) {
            await txn.insert(DbTables.transactions, {
              DbCols.id: tx['id'],
              DbCols.title: tx['title'],
              DbCols.amount: tx['amount'],
              DbCols.date: tx['date'],
              DbCols.categoryId: tx['category_id'],
              DbCols.createdAt: DateTime.now().toIso8601String(),
            });
          }
        });

        catCount =
            (await db.rawQuery(
                  'SELECT COUNT(*) FROM ${DbTables.categories}',
                )).first.values.first
                as int;
        txCount =
            (await db.rawQuery(
                  'SELECT COUNT(*) FROM ${DbTables.transactions}',
                )).first.values.first
                as int;
        expect(catCount, equals(1));
        expect(txCount, equals(1));
      },
    );
  });

    Future<void> seedDefaultCategories() async {
      const names = [
        'Food',
        'Transport',
        'Shopping',
        'Bills',
        'Entertainment',
        'Healthcare',
        'Investment',
        'Others',
      ];
      for (final name in names) {
        await db.insert(DbTables.categories, {
          DbCols.name: name,
          DbCols.createdAt: DateTime.now().toIso8601String(),
        });
      }
    }

    test('Merge preserves existing transactions and default categories', () async {
      await seedDefaultCategories();
      final foodId = (await db.query(
        DbTables.categories,
        where: '${DbCols.name} = ?',
        whereArgs: ['Food'],
      )).first[DbCols.id] as int;

      await db.insert(DbTables.categories, {
        DbCols.name: 'Old Custom',
        DbCols.createdAt: DateTime.now().toIso8601String(),
      });
      await db.insert(DbTables.transactions, {
        DbCols.title: 'Existing',
        DbCols.amount: 10.0,
        DbCols.date: '2026-09-01T10:00:00Z',
        DbCols.categoryId: foodId,
        DbCols.createdAt: DateTime.now().toIso8601String(),
      });

      final backup = ExportMigrationService.migrateToLatest([
        {
          'id': 100,
          'title': 'Imported',
          'amount': 20.0,
          'date': '2026-09-02T10:00:00Z',
          'category': 'Food',
        },
      ]);

      final restored = await ImportService().restoreMigratedData(
        backup,
        mode: RestoreMode.merge,
        database: db,
      );

      expect(restored, equals(1));
      expect((await db.query(DbTables.transactions)).length, equals(2));
      expect(
        (await db.query(
          DbTables.categories,
          where: '${DbCols.name} = ?',
          whereArgs: ['Food'],
        )).length,
        equals(1),
      );
      expect(
        (await db.query(
          DbTables.categories,
          where: '${DbCols.name} = ?',
          whereArgs: ['Old Custom'],
        )).length,
        equals(1),
      );
    });

    test(
      'Replace removes existing transactions and custom categories but preserves defaults',
      () async {
        await seedDefaultCategories();
        final foodId = (await db.query(
          DbTables.categories,
          where: '${DbCols.name} = ?',
          whereArgs: ['Food'],
        )).first[DbCols.id] as int;

        await db.insert(DbTables.categories, {
          DbCols.name: 'Old Custom',
          DbCols.createdAt: DateTime.now().toIso8601String(),
        });
        await db.insert(DbTables.transactions, {
          DbCols.title: 'Existing',
          DbCols.amount: 10.0,
          DbCols.date: '2026-09-01T10:00:00Z',
          DbCols.categoryId: foodId,
          DbCols.createdAt: DateTime.now().toIso8601String(),
        });

        final backup = ExportMigrationService.migrateToLatest([
          {
            'id': 200,
            'title': 'Imported',
            'amount': 25.0,
            'date': '2026-09-03T10:00:00Z',
            'category': 'Food',
          },
        ]);

        final restored = await ImportService().restoreMigratedData(
          backup,
          mode: RestoreMode.replaceExistingTransactions,
          database: db,
        );

        expect(restored, equals(1));
        expect((await db.query(DbTables.transactions)).length, equals(1));
        expect(
          (await db.query(
            DbTables.transactions,
            where: '${DbCols.title} = ?',
            whereArgs: ['Imported'],
          )).length,
          equals(1),
        );
        expect(
          (await db.query(
            DbTables.categories,
            where: '${DbCols.name} = ?',
            whereArgs: ['Old Custom'],
          )).isEmpty,
          isTrue,
        );
        expect((await db.query(DbTables.categories)).length, equals(8));
      },
    );

    test(
      'Legacy backup with incomplete category list keeps default categories',
      () async {
        await seedDefaultCategories();

        final backup = ExportMigrationService.migrateToLatest([
          {
            'id': 300,
            'title': 'Legacy Food',
            'amount': 30.0,
            'date': '2026-09-04T10:00:00Z',
            'category': 'Food',
          },
        ]);

        await ImportService().restoreMigratedData(
          backup,
          mode: RestoreMode.replaceExistingTransactions,
          database: db,
        );

        final names = (await db.query(
          DbTables.categories,
          columns: [DbCols.name],
        )).map((row) => row[DbCols.name]).toSet();

        expect(
          names.containsAll({
            'Food',
            'Transport',
            'Shopping',
            'Bills',
            'Entertainment',
            'Healthcare',
            'Investment',
            'Others',
          }),
          isTrue,
        );
      },
    );

}
