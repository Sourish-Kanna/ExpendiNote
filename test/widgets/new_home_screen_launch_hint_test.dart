import 'dart:io';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/repositories/settings_repository.dart';
import 'package:expend_note/screens/new_home_screen.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync(
      'new_home_screen_hint_test_',
    );
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    NewHomeScreen.resetLaunchSessionForTesting();
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));
    await DatabaseService.instance.database;
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

  group('NewHomeScreen First-Five-Launch Hint Tests', () {
    testWidgets(
      'shows launch hint SnackBar and persists launch count = 1 on first app launch',
      (tester) async {
        configureViewport(tester);
        expect(
          await SettingsRepository.getInt(SettingsRepository.launchCountKey),
          isNull,
        );

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(
          find.text('Long-press a transaction for more options.'),
          findsOneWidget,
        );

        final storedCount = await SettingsRepository.getInt(
          SettingsRepository.launchCountKey,
        );
        expect(storedCount, equals(1));
      },
    );

    testWidgets(
      'counts across launches and shows hint for launches 1 through 5',
      (tester) async {
        configureViewport(tester);

        for (int launch = 1; launch <= 5; launch++) {
          NewHomeScreen.resetLaunchSessionForTesting();

          await tester.pumpWidget(createWidgetUnderTest());
          await tester.runAsync(() async {
            await Future.delayed(const Duration(milliseconds: 100));
          });
          await tester.pump();

          expect(
            find.text('Long-press a transaction for more options.'),
            findsOneWidget,
          );

          final count = await SettingsRepository.getInt(
            SettingsRepository.launchCountKey,
          );
          expect(count, equals(launch));
        }
      },
    );

    testWidgets(
      'suppresses launch hint SnackBar on sixth and subsequent launches',
      (tester) async {
        configureViewport(tester);

        // Set initial launch count to 5
        await SettingsRepository.set(SettingsRepository.launchCountKey, '5');

        NewHomeScreen.resetLaunchSessionForTesting();

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(
          find.text('Long-press a transaction for more options.'),
          findsNothing,
        );

        final count = await SettingsRepository.getInt(
          SettingsRepository.launchCountKey,
        );
        expect(count, equals(6));

        // Next launch (7th)
        NewHomeScreen.resetLaunchSessionForTesting();

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(
          find.text('Long-press a transaction for more options.'),
          findsNothing,
        );

        final count7 = await SettingsRepository.getInt(
          SettingsRepository.launchCountKey,
        );
        expect(count7, equals(7));
      },
    );

    testWidgets(
      'prevents duplicate display and duplicate count increment within the same launch',
      (tester) async {
        configureViewport(tester);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        expect(
          find.text('Long-press a transaction for more options.'),
          findsOneWidget,
        );

        final initialCount = await SettingsRepository.getInt(
          SettingsRepository.launchCountKey,
        );
        expect(initialCount, equals(1));

        // Trigger rebuild or re-pump without resetting session flag
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        final countAfterRebuild = await SettingsRepository.getInt(
          SettingsRepository.launchCountKey,
        );
        expect(countAfterRebuild, equals(1));
      },
    );
  });
}
