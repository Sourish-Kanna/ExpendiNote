import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/screens/history_screen.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync('history_widget_test_');
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
    await DatabaseService.instance.database;

    final catId = await CategoryRepository.createCategory(
      Category(id: 1, name: 'Dining', icon: 'restaurant'),
    );

    // Transaction without description
    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Lunch',
        amount: 150.0,
        date: DateTime.parse('2026-09-01T12:00:00Z'),
        categoryId: catId,
        categoryName: 'Dining',
        description: null,
      ),
    );

    // Transaction with description
    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Coffee',
        amount: 50.0,
        date: DateTime.parse('2026-09-01T15:00:00Z'),
        categoryId: catId,
        categoryName: 'Dining',
        description: 'Espresso with biscuit',
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  testWidgets(
    'HistoryScreen displays category name when description is null and description when present',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HistoryScreen(filterDate: '2026-09-01')),
      );
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // "Lunch" has no description, so category name "Dining" should be displayed as subtitle
      expect(find.text('Dining'), findsOneWidget);

      // "Coffee" has description, so "Espresso with biscuit" should be displayed as subtitle
      expect(find.text('Espresso with biscuit'), findsOneWidget);
    },
  );
}
