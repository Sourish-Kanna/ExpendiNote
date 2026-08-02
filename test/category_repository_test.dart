import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:expend_note/constants/database_constants.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart' as txn;

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('CategoryRepository', () {
    late String dbPath;

    setUp(() async {
      final tmp = Directory.systemTemp.createTempSync('cat_test_');
      dbPath = join(tmp.path, 'cat_test.db');
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE ${DbTables.categories}(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE COLLATE NOCASE, icon TEXT, color INTEGER, isPinned INTEGER DEFAULT 0, isArchived INTEGER DEFAULT 0, createdAt TEXT NOT NULL)'
            );
            await db.execute(
              'CREATE TABLE transactions(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT NOT NULL, amount REAL NOT NULL, date TEXT NOT NULL, categoryId INTEGER, description TEXT, createdAt TEXT NOT NULL, FOREIGN KEY(categoryId) REFERENCES categories(id))',
            );
            await db.execute(
              'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)',
            );
          },
        ),
      );
      DatabaseService.setTestDatabase(db);
    });

    tearDown(() async {
      try {
        final db = await DatabaseService().database;
        await db.close();
      } catch (_) {}
    });

    test('create, ensure, prevent delete when in use', () async {
      final repo = CategoryRepository();
      final repoTx = TransactionRepository();

      final id = await repo.createCategory(Category(name: 'MyCat'));
      expect(id, greaterThan(0));

      final ensured = await repo.ensureCategoryByName('MyCat');
      expect(ensured, id);

      final all = await repo.getAllCategories();
      expect(all.any((c) => c.name == 'MyCat'), isTrue);

      // insert a transaction using this category
      final txId = await repoTx.insertTransaction(
        txn.Transaction(
          title: 'T',
          amount: 1.0,
          date: DateTime.now(),
          categoryId: id,
        ),
      );
      expect(txId, greaterThan(0));

      // attempt to delete category should throw
      expect(() => repo.deleteCategory(id), throwsA(isA<StateError>()));

      // delete transaction and then delete category
      await repoTx.deleteTransaction(txId);
      final del = await repo.deleteCategory(id);
      expect(del, greaterThanOrEqualTo(0));
    });
  });
}
