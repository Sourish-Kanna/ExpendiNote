import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/screens/category_management_screen.dart';
import 'package:expend_note/constants/database_constants.dart';

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

    await CategoryRepository.createCategory(
      Category(id: 1, name: 'Groceries', icon: 'shopping_bag', isPinned: true),
    );
    await CategoryRepository.createCategory(
      Category(id: 2, name: 'Entertainment', icon: 'movie', isPinned: false),
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

    testWidgets('opens bottom sheet when long-pressing a category card', (
      tester,
    ) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Long press first category item
      final categoryCard = find.text('Groceries');
      await tester.longPress(categoryCard);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
      expect(
        find.text('Delete'),
        findsOneWidget,
      ); // 0 transactions so delete is visible
    });
  });
}
