import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Database Migration Tests', () {
    test('v1 -> v2 migration preserves transactions, creates normalized categories, and drops legacy table', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          // Create legacy v1 table 'spendings'
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

          // Insert legacy rows
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
            'category': null, // Missing category
            'description': null,
          });
        },
      );

      // Perform migration v1 -> v2 directly calling production DatabaseService method
      await DatabaseService.migrateV1toV2(db);

      // Verify v2 tables exist
      final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
      final tableNames = tables.map((t) => t['name'] as String).toSet();
      expect(tableNames, contains(DbTables.categories));
      expect(tableNames, contains(DbTables.transactions));
      expect(tableNames, contains(DbTables.settings));
      expect(tableNames.contains(DbTables.legacySpendings), isFalse); // Legacy table dropped

      // Verify categories were created with normalized names
      final categories = await db.query(DbTables.categories);
      final catNames = categories.map((c) => c[DbCols.name] as String).toList();
      expect(catNames, contains('Food & Dining')); // Capitalized and trimmed
      expect(catNames, contains('Others')); // Fallback for null/empty category

      // Verify transactions preserved with correct category IDs
      final transactions = await db.query(DbTables.transactions);
      expect(transactions.length, equals(2));

      final tx100 = transactions.firstWhere((t) => t[DbCols.id] == 100);
      expect(tx100[DbCols.title], equals('Coffee'));
      expect(tx100[DbCols.amount], equals(150.0));
      expect(tx100[DbCols.description], equals('Espresso'));

      final tx101 = transactions.firstWhere((t) => t[DbCols.id] == 101);
      expect(tx101[DbCols.title], equals('Unknown spend'));
      expect(tx101[DbCols.amount], equals(50.0));

      await db.close();
    });

    test('v2 -> v3 migration adds new category columns and preserves existing data', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
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

      // Perform migration v2 -> v3 directly calling production DatabaseService method
      await DatabaseService.migrateV2toV3(db);

      final catTableInfo = await db.rawQuery('PRAGMA table_info(${DbTables.categories})');
      final catCols = catTableInfo.map((c) => c['name'] as String).toSet();
      expect(catCols, contains(DbCols.icon));
      expect(catCols, contains(DbCols.color));
      expect(catCols, contains(DbCols.isPinned));
      expect(catCols, contains(DbCols.isArchived));

      // Verify category & transaction data preserved
      final cat = (await db.query(DbTables.categories)).first;
      expect(cat[DbCols.name], equals('Groceries'));
      expect(cat[DbCols.isPinned], equals(0)); // Default value

      final tx = (await db.query(DbTables.transactions)).first;
      expect(tx[DbCols.title], equals('Milk'));
      expect(tx[DbCols.amount], equals(40.0));

      await db.close();
    });

    test('v3 -> v4 migration adds includeInSpendingAnalysis and updates Investment category', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${DbTables.categories}(
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
            DbCols.name: 'Investment',
            DbCols.createdAt: '2024-01-01T00:00:00.000',
          });
        },
      );

      // Perform migration v3 -> v4 directly calling production DatabaseService method
      await DatabaseService.migrateV3toV4(db);

      final catTableInfo = await db.rawQuery('PRAGMA table_info(${DbTables.categories})');
      final catCols = catTableInfo.map((c) => c['name'] as String).toSet();
      expect(catCols, contains(DbCols.includeInSpendingAnalysis));

      final txTableInfo = await db.rawQuery('PRAGMA table_info(${DbTables.transactions})');
      final txCols = txTableInfo.map((c) => c['name'] as String).toSet();
      expect(txCols, contains(DbCols.includeInSpendingAnalysis));

      final invCat = (await db.query(DbTables.categories, where: "LOWER(name) = 'investment'")).first;
      expect(invCat[DbCols.includeInSpendingAnalysis], equals(0));

      await db.close();
    });

    test('v4 -> v5 migration converts numeric icon code points to named icon strings', () async {
      final db = await openDatabase(
        inMemoryDatabasePath,
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

          await db.insert(DbTables.categories, {
            'id': 1,
            DbCols.name: 'Dining',
            DbCols.icon: '58674', // Codepoint for restaurant
            DbCols.createdAt: '2024-01-01T00:00:00.000',
          });
          await db.insert(DbTables.categories, {
            'id': 2,
            DbCols.name: 'Shopping',
            DbCols.icon: '58778', // Codepoint for shopping_bag
            DbCols.createdAt: '2024-01-01T00:00:00.000',
          });
        },
      );

      // Perform migration v4 -> v5 directly calling production DatabaseService method
      await DatabaseService.migrateV4toV5(db);

      final cats = await db.query(DbTables.categories);
      final c1 = cats.firstWhere((c) => c['id'] == 1);
      expect(c1[DbCols.icon], equals('restaurant'));

      final c2 = cats.firstWhere((c) => c['id'] == 2);
      expect(c2[DbCols.icon], equals('shopping_bag'));

      await db.close();
    });
  });
}
