import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/screens/unified_summary_screen.dart';
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
      'unified_summary_test_',
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

    // Insert transaction with very large amount to test overflow handling
    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Massive Expense',
        amount: 999999999.00,
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
    return MaterialApp(
      home: UnifiedSummaryScreen(refreshNotifier: ValueNotifier<int>(0)),
    );
  }

  void configureNarrowViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 800); // Narrow phone width
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('UnifiedSummaryScreen Overflow & Overview Tests', () {
    testWidgets(
      'renders overview card at narrow width with long values without overflow',
      (tester) async {
        configureNarrowViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Analysis'), findsOneWidget);
        expect(find.text('Total Spending'), findsOneWidget);
        expect(find.text('Total Entries'), findsOneWidget);
        expect(find.text('₹999999999.00'), findsOneWidget);
        expect(find.text('1'), findsOneWidget);

        // Verify no overflow exception was thrown
        expect(tester.takeException(), isNull);

        // Verify text widget properties for singleLine and ellipsis
        final spendingTextWidget = tester.widget<Text>(
          find.text('₹999999999.00'),
        );
        expect(spendingTextWidget.maxLines, equals(1));
        expect(spendingTextWidget.overflow, equals(TextOverflow.ellipsis));

        final totalSpendingLabel = tester.widget<Text>(
          find.text('Total Spending'),
        );
        expect(totalSpendingLabel.maxLines, equals(1));
        expect(totalSpendingLabel.overflow, equals(TextOverflow.ellipsis));
      },
    );
  });
}
