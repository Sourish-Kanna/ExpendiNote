import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync('migration_test_');
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DbConfig.databaseFile);
    await databaseFactory.deleteDatabase(path);
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, DbConfig.databaseFile);
    await databaseFactory.deleteDatabase(path);
  });

  group('Database Migration Tests via DatabaseService Public API', () {
    test(
      'migrates database from v1 to latest version (v5) preserving transactions and normalizing categories',
      () async {
        final dbPath = await getDatabasesPath();
        final path = p.join(dbPath, DbConfig.databaseFile);

        // Create initial v1 database
        final v1db = await openDatabase(
          path,
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE spendings (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT,
              amount REAL,
              date TEXT,
              category TEXT,
              description TEXT
            )
          ''');

            await db.insert('spendings', {
              'id': 100,
              'title': 'Coffee',
              'amount': 150.0,
              'date': '2024-01-15T10:00:00.000',
              'category': '  food & dining  ',
              'description': 'Espresso',
            });
            await db.insert('spendings', {
              'id': 101,
              'title': 'Unknown spend',
              'amount': 50.0,
              'date': '2024-01-16T10:00:00.000',
              'category': null,
              'description': null,
            });
          },
        );
        await v1db.close();

        // Open database via DatabaseService, triggering production migration onUpgrade
        final migratedDb = await DatabaseService.instance.database;

        // Verify v5 tables exist
        final tables = await migratedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();
        expect(tableNames, contains(DbTables.categories));
        expect(tableNames, contains(DbTables.transactions));
        expect(tableNames, contains(DbTables.settings));
        expect(
          tableNames.contains(DbTables.legacySpendings),
          isFalse,
        ); // Legacy table dropped

        // Verify categories were created with normalized names
        final categories = await migratedDb.query(DbTables.categories);
        final catNames = categories
            .map((c) => c[DbCols.name] as String)
            .toList();
        expect(catNames, contains('Food & Dining'));
        expect(catNames, contains('Others'));

        // Verify transactions preserved
        final transactions = await migratedDb.query(DbTables.transactions);
        expect(transactions.length, equals(2));

        final tx100 = transactions.firstWhere((t) => t[DbCols.id] == 100);
        expect(tx100[DbCols.title], equals('Coffee'));
        expect(tx100[DbCols.amount], equals(150.0));
        expect(tx100[DbCols.description], equals('Espresso'));
      },
    );

    test(
      'migrates database from v2 to latest version (v5) adding missing category columns and metadata',
      () async {
        final dbPath = await getDatabasesPath();
        final path = p.join(dbPath, DbConfig.databaseFile);

        // Create initial v2 database
        final v2db = await openDatabase(
          path,
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE ${DbTables.categories}(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbCols.name} TEXT NOT NULL UNIQUE COLLATE NOCASE,
              ${DbCols.createdAt} TEXT NOT NULL
            )
          ''');
            await db.execute('''
            CREATE TABLE ${DbTables.transactions}(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbCols.title} TEXT NOT NULL,
              ${DbCols.amount} REAL NOT NULL,
              ${DbCols.date} TEXT NOT NULL,
              ${DbCols.categoryId} INTEGER,
              ${DbCols.description} TEXT,
              ${DbCols.createdAt} TEXT NOT NULL
            )
          ''');

            await db.insert(DbTables.categories, {
              'id': 1,
              DbCols.name: 'Groceries',
              DbCols.createdAt: '2024-01-01T00:00:00.000',
            });
            await db.insert(DbTables.transactions, {
              'id': 10,
              DbCols.title: 'Milk',
              DbCols.amount: 40.0,
              DbCols.date: '2024-01-02T00:00:00.000',
              DbCols.categoryId: 1,
              DbCols.createdAt: '2024-01-02T00:00:00.000',
            });
          },
        );
        await v2db.close();

        // Open via DatabaseService, executing migrations v2->v3, v3->v4, v4->v5
        final migratedDb = await DatabaseService.instance.database;

        final catTableInfo = await migratedDb.rawQuery(
          'PRAGMA table_info(${DbTables.categories})',
        );
        final catCols = catTableInfo.map((c) => c['name'] as String).toSet();
        expect(catCols, contains(DbCols.icon));
        expect(catCols, contains(DbCols.color));
        expect(catCols, contains(DbCols.isPinned));
        expect(catCols, contains(DbCols.isArchived));
        expect(catCols, contains(DbCols.includeInSpendingAnalysis));

        // Verify existing data preserved
        final cat = (await migratedDb.query(
          DbTables.categories,
          where: 'id = 1',
        )).first;
        expect(cat[DbCols.name], equals('Groceries'));

        final tx = (await migratedDb.query(
          DbTables.transactions,
          where: 'id = 10',
        )).first;
        expect(tx[DbCols.title], equals('Milk'));
        expect(tx[DbCols.amount], equals(40.0));
      },
    );

    test(
      'migrates database from v4 to v5 converting numeric codepoints to icon names',
      () async {
        final dbPath = await getDatabasesPath();
        final path = p.join(dbPath, DbConfig.databaseFile);

        // Create v4 database
        final v4db = await openDatabase(
          path,
          version: 4,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE ${DbTables.categories}(
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
            CREATE TABLE ${DbTables.transactions}(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              ${DbCols.title} TEXT NOT NULL,
              ${DbCols.amount} REAL NOT NULL,
              ${DbCols.date} TEXT NOT NULL,
              ${DbCols.categoryId} INTEGER,
              ${DbCols.description} TEXT,
              ${DbCols.includeInSpendingAnalysis} INTEGER DEFAULT 1,
              ${DbCols.createdAt} TEXT NOT NULL
            )
          ''');

            await db.insert(DbTables.categories, {
              'id': 1,
              DbCols.name: 'Dining',
              DbCols.icon: '58674', // restaurant
              DbCols.createdAt: '2024-01-01T00:00:00.000',
            });
          },
        );
        await v4db.close();

        // Open via DatabaseService, executing v4->v5 migration
        final migratedDb = await DatabaseService.instance.database;

        final cat = (await migratedDb.query(
          DbTables.categories,
          where: 'id = 1',
        )).first;
        expect(cat[DbCols.icon], equals('restaurant'));
      },
    );
  });
}
