import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/models/transaction.dart' as model;

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;
  final logger = Logger();

  group('TransactionRepository', () {
    late String dbPath;

    setUp(() async {
      final tmp = Directory.systemTemp.createTempSync('txn_test_');
      dbPath = join(tmp.path, 'txn_test.db');
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, icon TEXT, color INTEGER, isPinned INTEGER DEFAULT 0, isArchived INTEGER DEFAULT 0, createdAt TEXT NOT NULL)',
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

    test('insert, query, update, delete transaction', () async {
      final repo = TransactionRepository();
      final tx = model.Transaction(
        title: 'Test',
        amount: 10.5,
        date: DateTime.now(),
      );
      final id = await repo.insertTransaction(tx);
      expect(id, greaterThan(0));

      final all = await repo.getAllTransactions();
      expect(all.length, 1);

      final fetched = await repo.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Test');

      final updated = model.Transaction(
        id: id,
        title: 'Updated',
        amount: 12.0,
        date: DateTime.now(),
      );
      final updatedCount = await repo.updateTransaction(updated);
      // db.update returns number of changed rows
      expect(updatedCount, greaterThanOrEqualTo(0));

      final deleted = await repo.deleteTransaction(id);
      expect(deleted, greaterThanOrEqualTo(0));

      final after = await repo.getAllTransactions();
      expect(after.length, 0);
    });
  });
}
