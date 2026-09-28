import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync('category_repo_test_');
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

  group('CategoryRepository Tests', () {
    test('createCategory inserts and returns generated ID', () async {
      final category = Category(name: 'Subscriptions', icon: 'movie', color: 12345);
      final id = await CategoryRepository.createCategory(category);

      expect(id, isA<int>());
      expect(id, greaterThan(0));

      final fetched = await CategoryRepository.getById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, equals('Subscriptions'));
      expect(fetched.icon, equals('movie'));
      expect(fetched.color, equals(12345));
    });

    test('updateCategory modifies category or throws if ID is null', () async {
      final category = Category(name: 'Health', icon: 'medical_services');
      final id = await CategoryRepository.createCategory(category);

      final toUpdate = Category(id: id, name: 'Healthcare & Wellness', icon: 'medical_services');
      final rowsUpdated = await CategoryRepository.updateCategory(toUpdate);
      expect(rowsUpdated, equals(1));

      final fetched = await CategoryRepository.getById(id);
      expect(fetched!.name, equals('Healthcare & Wellness'));

      final invalidCat = Category(name: 'No ID');
      expect(() => CategoryRepository.updateCategory(invalidCat), throwsArgumentError);
    });

    test('getAllCategories respects includeArchived and sorting order', () async {
      final cat1 = Category(name: 'Zulu', isPinned: false, isArchived: false);
      final cat2 = Category(name: 'Alpha', isPinned: true, isArchived: false);
      final cat3 = Category(name: 'Archived Cat', isPinned: false, isArchived: true);

      await CategoryRepository.createCategory(cat1);
      await CategoryRepository.createCategory(cat2);
      await CategoryRepository.createCategory(cat3);

      final unarchived = await CategoryRepository.getAllCategories(includeArchived: false);
      expect(unarchived.map((c) => c.name), containsAllInOrder(['Alpha', 'Zulu']));
      expect(unarchived.any((c) => c.name == 'Archived Cat'), isFalse);

      final all = await CategoryRepository.getAllCategories(includeArchived: true);
      expect(all.any((c) => c.name == 'Archived Cat'), isTrue);
    });

    test('isNameTaken performs case-insensitive check and respects excludeId', () async {
      final id1 = await CategoryRepository.createCategory(Category(name: 'Dining'));

      expect(await CategoryRepository.isNameTaken('dining'), isTrue);
      expect(await CategoryRepository.isNameTaken('DINING'), isTrue);
      expect(await CategoryRepository.isNameTaken('Dining', excludeId: id1), isFalse);
      expect(await CategoryRepository.isNameTaken('Groceries'), isFalse);
    });

    test('ensureCategoryByName finds existing or creates new trimmed category', () async {
      final existingId = await CategoryRepository.createCategory(Category(name: 'Utilities'));

      final foundId = await CategoryRepository.ensureCategoryByName('  utilities  ');
      expect(foundId, equals(existingId));

      final newCatId = await CategoryRepository.ensureCategoryByName('  Gym Membership  ');
      expect(newCatId, isNot(equals(existingId)));

      final newCat = await CategoryRepository.getById(newCatId);
      expect(newCat!.name, equals('Gym Membership'));
    });

    test('getCategoriesWithStats computes transaction count and total amount', () async {
      final catId = await CategoryRepository.createCategory(Category(name: 'Travel'));

      await TransactionRepository.insertTransaction(
        Transaction(title: 'Flight', amount: 5000.0, date: DateTime.now(), categoryId: catId),
      );
      await TransactionRepository.insertTransaction(
        Transaction(title: 'Hotel', amount: 3000.0, date: DateTime.now(), categoryId: catId),
      );

      final stats = await CategoryRepository.getCategoriesWithStats();
      final travelStats = stats.firstWhere((s) => s['id'] == catId);

      expect(travelStats['transactionCount'], equals(2));
      expect(travelStats['totalAmount'], equals(8000.0));
    });

    test('deleteCategory succeeds when unused and throws StateError when in use', () async {
      final catId = await CategoryRepository.createCategory(Category(name: 'Unused'));
      final inUseCatId = await CategoryRepository.createCategory(Category(name: 'In Use'));

      await TransactionRepository.insertTransaction(
        Transaction(title: 'Item', amount: 100.0, date: DateTime.now(), categoryId: inUseCatId),
      );

      // Deleting in-use category should throw StateError
      expect(() => CategoryRepository.deleteCategory(inUseCatId), throwsStateError);

      // Deleting unused category should succeed
      final count = await CategoryRepository.deleteCategory(catId);
      expect(count, equals(1));
      expect(await CategoryRepository.getById(catId), isNull);
    });

    test('mergeCategories reassigns transactions and deletes source category', () async {
      final sourceId = await CategoryRepository.createCategory(Category(name: 'Fast Food'));
      final targetId = await CategoryRepository.createCategory(Category(name: 'Restaurants'));

      final tx1Id = await TransactionRepository.insertTransaction(
        Transaction(title: 'Burger', amount: 200.0, date: DateTime.now(), categoryId: sourceId),
      );
      final tx2Id = await TransactionRepository.insertTransaction(
        Transaction(title: 'Fries', amount: 100.0, date: DateTime.now(), categoryId: sourceId),
      );

      await CategoryRepository.mergeCategories(sourceId, targetId);

      // Source category deleted
      expect(await CategoryRepository.getById(sourceId), isNull);
      // Target category exists
      expect(await CategoryRepository.getById(targetId), isNotNull);

      // Transactions reassigned to target
      final tx1 = await TransactionRepository.getById(tx1Id);
      final tx2 = await TransactionRepository.getById(tx2Id);
      expect(tx1!.categoryId, equals(targetId));
      expect(tx2!.categoryId, equals(targetId));
    });
  });
}
