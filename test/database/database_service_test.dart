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
    final tempDir = Directory.systemTemp.createTempSync('db_service_test_');
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  group('DatabaseService Fresh Installation & Schema Tests', () {
    test(
      'creates required tables for v5 schema directly on fresh install',
      () async {
        final db = await DatabaseService.instance.database;

        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
        );
        final tableNames = tables.map((t) => t['name'] as String).toSet();

        expect(tableNames, contains(DbTables.categories));
        expect(tableNames, contains(DbTables.transactions));
        expect(tableNames, contains(DbTables.settings));
      },
    );

    test('categories table contains all expected v5 columns', () async {
      final db = await DatabaseService.instance.database;

      final columns = await db.rawQuery(
        "PRAGMA table_info(${DbTables.categories})",
      );
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      expect(columnNames, contains(DbCols.id));
      expect(columnNames, contains(DbCols.name));
      expect(columnNames, contains(DbCols.icon));
      expect(columnNames, contains(DbCols.color));
      expect(columnNames, contains(DbCols.isPinned));
      expect(columnNames, contains(DbCols.isArchived));
      expect(columnNames, contains(DbCols.includeInSpendingAnalysis));
      expect(columnNames, contains(DbCols.createdAt));
    });

    test('transactions table contains all expected v5 columns', () async {
      final db = await DatabaseService.instance.database;

      final columns = await db.rawQuery(
        "PRAGMA table_info(${DbTables.transactions})",
      );
      final columnNames = columns.map((c) => c['name'] as String).toSet();

      expect(columnNames, contains(DbCols.id));
      expect(columnNames, contains(DbCols.title));
      expect(columnNames, contains(DbCols.amount));
      expect(columnNames, contains(DbCols.date));
      expect(columnNames, contains(DbCols.categoryId));
      expect(columnNames, contains(DbCols.description));
      expect(columnNames, contains(DbCols.includeInSpendingAnalysis));
      expect(columnNames, contains(DbCols.createdAt));
    });

    test('creates required performance indexes', () async {
      final db = await DatabaseService.instance.database;

      final indexes = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='index'",
      );
      final indexNames = indexes.map((i) => i['name'] as String).toSet();

      expect(indexNames, contains('idx_transactions_date'));
      expect(indexNames, contains('idx_transactions_categoryId'));
      expect(indexNames, contains('idx_categories_name'));
    });

    test(
      'seeds default categories with correct spending analysis settings on fresh install',
      () async {
        final db = await DatabaseService.instance.database;

        final categories = await db.query(DbTables.categories);
        final names = categories.map((c) => c[DbCols.name] as String).toList();

        expect(
          names,
          containsAll([
            'Food',
            'Transport',
            'Shopping',
            'Bills',
            'Entertainment',
            'Healthcare',
            'Investment',
            'Others',
          ]),
        );

        // Verify Investment has includeInSpendingAnalysis set to 0, Food set to 1
        final investment = categories.firstWhere(
          (c) => c[DbCols.name] == 'Investment',
        );
        expect(investment[DbCols.includeInSpendingAnalysis], equals(0));

        final food = categories.firstWhere((c) => c[DbCols.name] == 'Food');
        expect(food[DbCols.includeInSpendingAnalysis], equals(1));
      },
    );

    test('enforces NOCASE uniqueness on category names', () async {
      final db = await DatabaseService.instance.database;

      await expectLater(
        db.insert(DbTables.categories, {
          DbCols.name: 'food', // lowercase duplicate of 'Food'
          DbCols.createdAt: DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test('enforces foreign key constraints on transactions', () async {
      final db = await DatabaseService.instance.database;

      await expectLater(
        db.insert(DbTables.transactions, {
          DbCols.title: 'Test FK',
          DbCols.amount: 100.0,
          DbCols.date: DateTime.now().toIso8601String(),
          DbCols.categoryId: 99999, // Non-existent category ID
          DbCols.createdAt: DateTime.now().toIso8601String(),
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'supports transaction CRUD operations via DatabaseService instance',
      () async {
        final db = await DatabaseService.instance.database;

        final catId =
            (await db.query(DbTables.categories, limit: 1)).first['id'] as int;
        final nowStr = DateTime.now().toIso8601String();

        // Insert
        final id = await db.insert(DbTables.transactions, {
          DbCols.title: 'Dinner',
          DbCols.amount: 500.0,
          DbCols.date: nowStr,
          DbCols.categoryId: catId,
          DbCols.description: 'Fancy restaurant',
          DbCols.includeInSpendingAnalysis: 1,
          DbCols.createdAt: nowStr,
        });

        // Retrieve
        final rows = await db.query(
          DbTables.transactions,
          where: 'id = ?',
          whereArgs: [id],
        );
        expect(rows.length, equals(1));
        expect(rows.first[DbCols.title], equals('Dinner'));
        expect(rows.first[DbCols.amount], equals(500.0));

        // Update
        await db.update(
          DbTables.transactions,
          {DbCols.amount: 550.0},
          where: 'id = ?',
          whereArgs: [id],
        );
        final updatedRows = await db.query(
          DbTables.transactions,
          where: 'id = ?',
          whereArgs: [id],
        );
        expect(updatedRows.first[DbCols.amount], equals(550.0));

        // Delete
        await db.delete(
          DbTables.transactions,
          where: 'id = ?',
          whereArgs: [id],
        );
        final deletedRows = await db.query(
          DbTables.transactions,
          where: 'id = ?',
          whereArgs: [id],
        );
        expect(deletedRows, isEmpty);
      },
    );
  });
}
