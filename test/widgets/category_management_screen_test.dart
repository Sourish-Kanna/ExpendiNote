import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/screens/category_management_screen.dart';
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

    await CategoryRepository.createCategory(Category(id: 1, name: 'Groceries', icon: 'shopping_bag', isPinned: true));
    await CategoryRepository.createCategory(Category(id: 2, name: 'Entertainment', icon: 'movie', isPinned: false));
  });

  tearDown(() async {
    await db.close();
    DatabaseService.setTestDatabase(null);
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: CategoryManagementScreen(),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CategoryManagementScreen Widget Tests', () {
    testWidgets('renders list of categories with pinned indicator and floating action button', (tester) async {
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
    });

    testWidgets('opens popup menu when tapping popup button', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Find popup menu button
      final menuBtn = find.byType(PopupMenuButton<String>).first;
      await tester.tap(menuBtn);
      await tester.pump();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget); // 0 transactions so delete is visible
    });
  });
}
