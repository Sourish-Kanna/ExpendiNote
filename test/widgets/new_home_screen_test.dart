import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/screens/new_home_screen.dart';
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
    final tempDir = Directory.systemTemp.createTempSync(
      'new_home_widget_test_',
    );
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
    await DatabaseService.instance.database;

    final catId = await CategoryRepository.createCategory(
      Category(
        id: 1,
        name: 'Food',
        icon: 'restaurant',
        includeInSpendingAnalysis: true,
      ),
    );

    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Starbucks Coffee',
        amount: 250.0,
        date: DateTime.now(),
        categoryId: catId,
        includeInSpendingAnalysis: true,
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(home: NewHomeScreen());
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('NewHomeScreen Widget Tests', () {
    testWidgets(
      'renders AppBar title, sections, and activity item with distinct title and amount',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Expendi Note'), findsOneWidget);
        expect(find.text('Analysis'), findsOneWidget);
        expect(find.text('Recent Activity'), findsOneWidget);

        // Verify title is rendered directly and amount is rendered as trailing text
        expect(find.text('Starbucks Coffee'), findsOneWidget);
        expect(find.text('₹250'), findsOneWidget);
      },
    );

    testWidgets('normal tap navigates to SpendingDetailScreen', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Tap the transaction item
      await tester.tap(find.text('Starbucks Coffee'));
      await tester.pumpAndSettle();

      // Details screen should be displayed
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets(
      'long press opens modal bottom sheet with Edit and Delete options',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Long press the transaction item
        await tester.longPress(find.text('Starbucks Coffee'));
        await tester.pumpAndSettle();

        // Modal bottom sheet should appear with title, Edit, and Delete options
        expect(
          find.text('Starbucks Coffee'),
          findsNWidgets(2),
        ); // Card & Bottom Sheet
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Edit from long-press bottom sheet opens AddSpendingScreen in edit mode',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Long press to open bottom sheet
        await tester.longPress(find.text('Starbucks Coffee'));
        await tester.pumpAndSettle();

        // Tap Edit option
        await tester.tap(find.text('Edit'));
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Should open AddSpendingScreen in edit mode
        expect(find.text('Edit Spending'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Delete from long-press bottom sheet opens confirmation dialog and deletes transaction',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Long press to open bottom sheet
        await tester.longPress(find.text('Starbucks Coffee'));
        await tester.pumpAndSettle();

        // Tap Delete option in bottom sheet
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Existing delete confirmation dialog should appear
        expect(find.text('Delete Spending?'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete this entry?'),
          findsOneWidget,
        );

        // Confirm deletion in dialog
        final dialogDeleteButton = find.widgetWithText(TextButton, 'Delete');
        await tester.tap(dialogDeleteButton);
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Transaction should be removed from home screen
        expect(find.text('Starbucks Coffee'), findsNothing);
      },
    );
  });
}
