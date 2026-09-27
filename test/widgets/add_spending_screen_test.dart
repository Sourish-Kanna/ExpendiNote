import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/screens/add_spending_screen.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database db;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: DbConfig.databaseVersion,
      onCreate: (d, v) async {
        await d.execute('''
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

        await d.execute('''
          CREATE TABLE ${DbTables.transactions}(
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
      },
    );
    DatabaseService.setTestDatabase(db);

    // Seed test categories
    await CategoryRepository.createCategory(Category(id: 1, name: 'Food', icon: 'restaurant', includeInSpendingAnalysis: true));
    await CategoryRepository.createCategory(Category(id: 2, name: 'Investment', icon: 'trending_up', includeInSpendingAnalysis: false));
  });

  tearDown(() async {
    await db.close();
    DatabaseService.setTestDatabase(null);
  });

  Widget createWidgetUnderTest({Transaction? transaction}) {
    return MaterialApp(
      home: AddSpendingScreen(transaction: transaction),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('AddSpendingScreen Widget Tests', () {
    testWidgets('shows validation error when saving without category selection', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap save button
      final saveBtn = find.widgetWithText(FilledButton, 'Save Spending');
      expect(saveBtn, findsOneWidget);
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      // Category error message should appear
      expect(find.text('Please explicitly select a category before saving.'), findsOneWidget);
    });

    testWidgets('shows validation error when amount is empty', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Select category 'Food'
      final categoryChip = find.text('Food');
      expect(categoryChip, findsOneWidget);
      await tester.tap(categoryChip);
      await tester.pump();

      // Enter title but leave amount empty
      await tester.enterText(find.widgetWithText(TextFormField, 'What did you spend on?'), 'Test Title');

      // Tap save button
      final saveBtn = find.widgetWithText(FilledButton, 'Save Spending');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump();

      expect(find.text('Please enter an amount'), findsOneWidget);
    });

    testWidgets('pre-fills fields when editing an existing transaction', (tester) async {
      configureViewport(tester);
      final existingTx = Transaction(
        id: 10,
        title: 'Dinner Bill',
        amount: 450.0,
        date: DateTime(2025, 3, 10),
        categoryId: 1,
        description: 'Italian restaurant',
        includeInSpendingAnalysis: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(transaction: existingTx));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      expect(find.text('Edit Spending'), findsOneWidget);
      expect(find.text('450.0'), findsOneWidget);
      expect(find.text('Dinner Bill'), findsOneWidget);
      expect(find.text('Italian restaurant'), findsOneWidget);
    });

    testWidgets('prompts dialog when changing category during edit', (tester) async {
      configureViewport(tester);
      final existingTx = Transaction(
        id: 10,
        title: 'Monthly SIP',
        amount: 5000.0,
        date: DateTime(2025, 3, 10),
        categoryId: 1, // Food (included)
        includeInSpendingAnalysis: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(transaction: existingTx));
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap on 'Investment' category (default excluded)
      final invChip = find.text('Investment');
      expect(invChip, findsOneWidget);
      await tester.tap(invChip);
      await tester.pump();

      // Dialog should appear asking "Update Spending Analysis Setting?"
      expect(find.text('Update Spending Analysis Setting?'), findsOneWidget);
      expect(find.text('Keep Current'), findsOneWidget);
      expect(find.text('Apply Default'), findsOneWidget);

      // Tap 'Keep Current'
      await tester.tap(find.text('Keep Current'));
      await tester.pump();

      // Dialog dismisses
      expect(find.text('Update Spending Analysis Setting?'), findsNothing);
    });
  });
}
