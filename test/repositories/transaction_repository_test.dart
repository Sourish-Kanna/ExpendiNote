import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync(
      'transaction_repo_test_',
    );
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
    await DatabaseService.instance.database;
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  group('TransactionRepository Tests', () {
    test(
      'insertTransaction inserts single transaction and returns ID',
      () async {
        final catId = await CategoryRepository.createCategory(
          Category(name: 'Food', icon: 'restaurant'),
        );
        final tx = Transaction(
          title: 'Lunch',
          amount: 200.0,
          date: DateTime(2025, 3, 15),
          categoryId: catId,
          description: 'Subway sandwich',
          includeInSpendingAnalysis: true,
        );

        final id = await TransactionRepository.insertTransaction(tx);
        expect(id, greaterThan(0));

        final fetched = await TransactionRepository.getById(id);
        expect(fetched, isNotNull);
        expect(fetched!.title, equals('Lunch'));
        expect(fetched.amount, equals(200.0));
        expect(fetched.categoryName, equals('Food'));
        expect(fetched.categoryIcon, equals('restaurant'));
      },
    );

    test(
      'insertTransactionsBatch inserts multiple transactions atomically',
      () async {
        final catId = await CategoryRepository.createCategory(
          Category(name: 'Shopping'),
        );
        final list = [
          Transaction(
            title: 'Shoes',
            amount: 1500.0,
            date: DateTime(2025, 3, 1),
            categoryId: catId,
          ),
          Transaction(
            title: 'Shirt',
            amount: 800.0,
            date: DateTime(2025, 3, 2),
            categoryId: catId,
          ),
        ];

        await TransactionRepository.insertTransactionsBatch(list);

        final all = await TransactionRepository.getAllTransactions();
        expect(all.length, equals(2));
        expect(all.map((t) => t.title), containsAll(['Shoes', 'Shirt']));
      },
    );

    test(
      'updateTransaction modifies transaction fields and throws when ID is null',
      () async {
        final catId = await CategoryRepository.createCategory(
          Category(name: 'Bills'),
        );
        final id = await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Electric',
            amount: 1000.0,
            date: DateTime.now(),
            categoryId: catId,
          ),
        );

        final updatedTx = Transaction(
          id: id,
          title: 'Electricity Bill',
          amount: 1250.0,
          date: DateTime.now(),
          categoryId: catId,
          description: 'March bill',
        );

        final rows = await TransactionRepository.updateTransaction(updatedTx);
        expect(rows, equals(1));

        final fetched = await TransactionRepository.getById(id);
        expect(fetched!.title, equals('Electricity Bill'));
        expect(fetched.amount, equals(1250.0));
        expect(fetched.description, equals('March bill'));

        final noIdTx = Transaction(
          title: 'No ID',
          amount: 100.0,
          date: DateTime.now(),
        );
        expect(
          () => TransactionRepository.updateTransaction(noIdTx),
          throwsArgumentError,
        );
      },
    );

    test(
      'getAllTransactions supports limit, offset, and orders by date DESC',
      () async {
        final catId = await CategoryRepository.createCategory(
          Category(name: 'Misc'),
        );

        await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Old',
            amount: 10.0,
            date: DateTime(2025, 1, 1),
            categoryId: catId,
          ),
        );
        await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Newest',
            amount: 30.0,
            date: DateTime(2025, 3, 1),
            categoryId: catId,
          ),
        );
        await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Mid',
            amount: 20.0,
            date: DateTime(2025, 2, 1),
            categoryId: catId,
          ),
        );

        final all = await TransactionRepository.getAllTransactions();
        expect(all.map((t) => t.title), equals(['Newest', 'Mid', 'Old']));

        final page = await TransactionRepository.getAllTransactions(
          limit: 1,
          offset: 1,
        );
        expect(page.length, equals(1));
        expect(page.first.title, equals('Mid'));
      },
    );

    test('handles uncategorized transaction (null categoryId)', () async {
      final id = await TransactionRepository.insertTransaction(
        Transaction(
          title: 'Cash Spend',
          amount: 50.0,
          date: DateTime.now(),
          categoryId: null,
        ),
      );

      final fetched = await TransactionRepository.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.categoryId, isNull);
      expect(fetched.categoryName, isNull);
    });

    test(
      'searchTransactions matches title, description, or category name case-insensitively',
      () async {
        final foodId = await CategoryRepository.createCategory(
          Category(name: 'Food'),
        );
        final bookId = await CategoryRepository.createCategory(
          Category(name: 'Education'),
        );

        await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Starbucks Coffee',
            amount: 250.0,
            date: DateTime.now(),
            categoryId: foodId,
            description: 'Morning espresso',
          ),
        );
        await TransactionRepository.insertTransaction(
          Transaction(
            title: 'Dart Book',
            amount: 500.0,
            date: DateTime.now(),
            categoryId: bookId,
            description: 'Programming guide',
          ),
        );

        // Match by title
        final titleResults = await TransactionRepository.searchTransactions(
          'starbucks',
        );
        expect(titleResults.length, equals(1));
        expect(titleResults.first['title'], equals('Starbucks Coffee'));

        // Match by description
        final descResults = await TransactionRepository.searchTransactions(
          'espresso',
        );
        expect(descResults.length, equals(1));

        // Match by category name
        final catResults = await TransactionRepository.searchTransactions(
          'education',
        );
        expect(catResults.length, equals(1));
        expect(catResults.first['title'], equals('Dart Book'));
      },
    );

    test('deleteTransaction removes record from database', () async {
      final id = await TransactionRepository.insertTransaction(
        Transaction(title: 'To Delete', amount: 100.0, date: DateTime.now()),
      );

      final rowsDeleted = await TransactionRepository.deleteTransaction(id);
      expect(rowsDeleted, equals(1));

      final fetched = await TransactionRepository.getById(id);
      expect(fetched, isNull);
    });

    group('Ordering Tests (date DESC, id DESC)', () {
      test(
        'Test 1 - Different dates returns descending date ordering',
        () async {
          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Older',
              amount: 10.0,
              date: DateTime(2026, 10, 4),
            ),
          );
          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Newer',
              amount: 20.0,
              date: DateTime(2026, 10, 6),
            ),
          );
          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Oldest',
              amount: 30.0,
              date: DateTime(2026, 10, 1),
            ),
          );

          final all = await TransactionRepository.getAllTransactions();
          expect(all.map((t) => t.title), equals(['Newer', 'Older', 'Oldest']));
        },
      );

      test(
        'Test 2 - Same transaction date returns highest ID first (id DESC)',
        () async {
          final sameDate = DateTime(2026, 10, 5);
          final id1 = await TransactionRepository.insertTransaction(
            Transaction(title: 'First Insert', amount: 10.0, date: sameDate),
          );
          final id2 = await TransactionRepository.insertTransaction(
            Transaction(title: 'Second Insert', amount: 20.0, date: sameDate),
          );
          final id3 = await TransactionRepository.insertTransaction(
            Transaction(title: 'Third Insert', amount: 30.0, date: sameDate),
          );

          final all = await TransactionRepository.getAllTransactions();
          expect(all.map((t) => t.id), equals([id3, id2, id1]));
          expect(
            all.map((t) => t.title),
            equals(['Third Insert', 'Second Insert', 'First Insert']),
          );
        },
      );

      test(
        'Test 3 - Older transaction entered later appears after newer transaction date',
        () async {
          // ID 1 -> transaction date 2026-10-06
          final id1 = await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Newer Date Logged First',
              amount: 100.0,
              date: DateTime(2026, 10, 6),
            ),
          );
          // ID 2 -> transaction date 2026-10-04 (inserted later)
          final id2 = await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Older Date Logged Later',
              amount: 50.0,
              date: DateTime(2026, 10, 4),
            ),
          );

          final all = await TransactionRepository.getAllTransactions();
          expect(all.first.id, equals(id1));
          expect(all.first.title, equals('Newer Date Logged First'));
          expect(all.last.id, equals(id2));
          expect(all.last.title, equals('Older Date Logged Later'));
        },
      );

      test(
        'Test 4 - Pagination LIMIT and OFFSET operate against date DESC, id DESC',
        () async {
          final dateA = DateTime(2026, 10, 6);
          final dateB = DateTime(2026, 10, 5);

          final tx1 = await TransactionRepository.insertTransaction(
            Transaction(title: 'A1', amount: 10.0, date: dateA),
          );
          final tx2 = await TransactionRepository.insertTransaction(
            Transaction(title: 'A2', amount: 20.0, date: dateA),
          );
          final tx3 = await TransactionRepository.insertTransaction(
            Transaction(title: 'B1', amount: 30.0, date: dateB),
          );
          final tx4 = await TransactionRepository.insertTransaction(
            Transaction(title: 'B2', amount: 40.0, date: dateB),
          );

          // Expected full order: tx2 (A2), tx1 (A1), tx4 (B2), tx3 (B1)
          final page1 = await TransactionRepository.getAllTransactions(
            limit: 2,
            offset: 0,
          );
          expect(page1.map((t) => t.id), equals([tx2, tx1]));

          final page2 = await TransactionRepository.getAllTransactions(
            limit: 2,
            offset: 2,
          );
          expect(page2.map((t) => t.id), equals([tx4, tx3]));
        },
      );

      test(
        'Test 5 - searchTransactions follows date DESC, id DESC ordering',
        () async {
          final sameDate = DateTime(2026, 10, 5);
          final olderDate = DateTime(2026, 10, 1);

          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Store Purchase A',
              amount: 10.0,
              date: sameDate,
            ),
          );
          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Store Purchase B',
              amount: 20.0,
              date: sameDate,
            ),
          );
          await TransactionRepository.insertTransaction(
            Transaction(
              title: 'Store Purchase C',
              amount: 30.0,
              date: olderDate,
            ),
          );

          final results = await TransactionRepository.searchTransactions(
            'store',
          );
          expect(results.length, equals(3));
          expect(
            results[0]['title'],
            equals('Store Purchase B'),
          ); // highest ID on sameDate
          expect(
            results[1]['title'],
            equals('Store Purchase A'),
          ); // lower ID on sameDate
          expect(results[2]['title'], equals('Store Purchase C')); // olderDate
        },
      );
    });
  });
}
