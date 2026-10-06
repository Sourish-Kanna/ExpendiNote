import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/main.dart';
import 'package:expend_note/screens/settings_screen.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/theme/app_theme_controller.dart';
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
      'settings_widget_test_',
    );
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

  Widget createWidgetUnderTest() {
    final controller = AppThemeController();
    return AppThemeScope(
      controller: controller,
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets(
      'renders sections and filled icons for data management options',
      (tester) async {
        configureViewport(tester);
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pump();

        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Backup Data'), findsOneWidget);
        expect(find.text('Restore Data'), findsOneWidget);
        expect(find.text('Export CSV'), findsOneWidget);

        // Verify filled icons exist
        expect(find.byIcon(Icons.backup), findsOneWidget);
        expect(find.byIcon(Icons.restore), findsOneWidget);
        expect(find.byIcon(Icons.table_chart), findsOneWidget);
      },
    );
  });
}
