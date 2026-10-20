import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/screens/category_management_screen.dart';
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
      'cat_mgmt_widget_test_',
    );
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
    await DatabaseService.instance.database;

    final cat1Id = await CategoryRepository.createCategory(
      Category(id: 1, name: 'Groceries', icon: 'shopping_bag', isPinned: true),
    );
    await CategoryRepository.createCategory(
      Category(id: 2, name: 'Entertainment', icon: 'movie', isPinned: false),
    );

    // Insert a transaction for Groceries so txCount > 0
    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Apples',
        amount: 100.0,
        date: DateTime.now(),
        categoryId: cat1Id,
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(home: CategoryManagementScreen());
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CategoryManagementScreen Widget Tests', () {
    testWidgets(
      'renders list of categories with pinned indicator and floating action button',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Manage Categories'), findsOneWidget);
        expect(find.text('Groceries'), findsOneWidget);
        expect(find.text('Entertainment'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsOneWidget);
      },
    );

    testWidgets('does not use three-dot popup menu', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // PopupMenuButton should not exist
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets(
      'long pressing a category opens modal bottom sheet with Edit, Merge, Delete',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        await tester.longPress(find.text('Entertainment'));
        await tester.pumpAndSettle();

        expect(
          find.text('Entertainment'),
          findsNWidgets(2),
        ); // Card & Bottom Sheet
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Merge'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Edit from long-press bottom sheet opens EditCategoryScreen',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        await tester.longPress(find.text('Entertainment'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit'));
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Edit Category'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Merge from long-press bottom sheet opens MergeCategoryScreen',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        await tester.longPress(find.text('Entertainment'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Merge'));
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Merge Category'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting Delete for a category with 0 transactions triggers delete confirmation',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Entertainment has 0 transactions
        await tester.longPress(find.text('Entertainment'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        expect(find.text('Delete Category?'), findsOneWidget);
        expect(
          find.text('Are you sure you want to delete "Entertainment"?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Delete option is disabled and untappable for a category with transactions',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Groceries has 1 transaction
        await tester.longPress(find.text('Groceries'));
        await tester.pumpAndSettle();

        // Delete should be visible but disabled
        final deleteListTile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, 'Delete'),
        );
        expect(deleteListTile.enabled, isFalse);

        // Tap disabled delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Should NOT trigger delete confirmation
        expect(find.text('Delete Category?'), findsNothing);
      },
    );

    testWidgets(
      'renders long-press discoverability hint icon on category items',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        // Should find hint icon for category items
        final hintIconFinder = find.byIcon(Icons.more_vert);
        expect(hintIconFinder, findsWidgets);

        // Tapping hint icon directly opens edit category screen
        await tester.tap(hintIconFinder.first);
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(find.text('Edit Category'), findsOneWidget);
      },
    );

    testWidgets(
      'long pressing hint icon directly opens category options bottom sheet',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        final hintIconFinder = find.byIcon(Icons.more_vert);
        await tester.longPress(hintIconFinder.first);
        await tester.pumpAndSettle();

        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Merge'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      },
    );
  });
}
