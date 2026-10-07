import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/repositories/category_repository.dart';
import 'package:expend_note/repositories/transaction_repository.dart';
import 'package:expend_note/screens/search_screen.dart';
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
    final tempDir = Directory.systemTemp.createTempSync('search_widget_test_');
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

    await TransactionRepository.insertTransaction(
      Transaction(
        title: 'Dinner Pizza',
        amount: 250.0,
        date: DateTime.now(),
        categoryId: catId,
      ),
    );
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  testWidgets('SearchScreen renders amount only once per transaction item', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    // The amount "₹250" should appear exactly once in the title, not repeated in trailing widget
    expect(find.textContaining('₹250'), findsOneWidget);
  });
}
