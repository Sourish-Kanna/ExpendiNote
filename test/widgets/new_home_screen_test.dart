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

    testWidgets('long press on transaction card opens bottom sheet with Edit and Delete', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      await tester.longPress(find.text('Starbucks Coffee'));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });
  });
}
