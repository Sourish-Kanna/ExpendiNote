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
    final db = await DatabaseService.instance.database;
    await db.delete(DbTables.settings);
    await db.delete(DbTables.transactions);
  });

  tearDownAll(() async {
    await DatabaseService.instance.closeDatabase();
  });

  Widget createWidgetUnderTest({Key? key}) {
    return MaterialApp(home: NewHomeScreen(key: key ?? UniqueKey()));
  }

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<int?> getLaunchCount(WidgetTester tester) async {
    int? count;
    await tester.runAsync(() async {
      count = await SettingsRepository.getInt(
        SettingsRepository.launchCountKey,
      );
    });
    return count;
  }

  Future<void> setLaunchCount(WidgetTester tester, int count) async {
    await tester.runAsync(() async {
      await SettingsRepository.set(
        SettingsRepository.launchCountKey,
        count.toString(),
      );
    });
  }

  Future<void> pumpHomeScreen(WidgetTester tester, {Key? key}) async {
    await tester.pumpWidget(createWidgetUnderTest(key: key));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('NewHomeScreen First-Five-Launch Hint Tests', () {
    testWidgets(
      'shows launch hint SnackBar and persists launch count = 1 on first app launch',
      (tester) async {
        configureViewport(tester);

        expect(await getLaunchCount(tester), isNull);

        await pumpHomeScreen(tester);

        expect(
          find.text('Long-press a transaction for more options.'),
          findsOneWidget,
        );

        final storedCount = await getLaunchCount(tester);
        expect(storedCount, equals(1));
      },
    );

    testWidgets(
      'counts across launches and shows hint for launches 1 through 5',
      (tester) async {
        configureViewport(tester);

        for (int launch = 1; launch <= 5; launch++) {
          NewHomeScreen.resetLaunchSessionForTesting();

          await pumpHomeScreen(tester);

          expect(
            find.text('Long-press a transaction for more options.'),
            findsOneWidget,
          );

          final count = await getLaunchCount(tester);
          expect(count, equals(launch));
        }
      },
    );

    testWidgets(
      'suppresses launch hint SnackBar on sixth and subsequent launches',
      (tester) async {
        configureViewport(tester);

        await setLaunchCount(tester, 5);

        NewHomeScreen.resetLaunchSessionForTesting();

        await pumpHomeScreen(tester);

        expect(
          find.text('Long-press a transaction for more options.'),
          findsNothing,
        );

        final count6 = await getLaunchCount(tester);
        expect(count6, equals(6));

        // Subsequent launch (7th)
        NewHomeScreen.resetLaunchSessionForTesting();

        await pumpHomeScreen(tester);

        expect(
          find.text('Long-press a transaction for more options.'),
          findsNothing,
        );

        final count7 = await getLaunchCount(tester);
        expect(count7, equals(7));
      },
    );

    testWidgets(
      'prevents duplicate launch count increment within the same launch',
      (tester) async {
        configureViewport(tester);

        final testKey = UniqueKey();
        await pumpHomeScreen(tester, key: testKey);

        final initialCount = await getLaunchCount(tester);
        expect(initialCount, equals(1));

        // Trigger rebuild / re-pump using same widget instance & key without resetting launch session flag
        await tester.pumpWidget(createWidgetUnderTest(key: testKey));
        await tester.pump();
        await tester.runAsync(() async {
          await Future.delayed(const Duration(milliseconds: 100));
        });
        await tester.pump();

        final countAfterRebuild = await getLaunchCount(tester);
        expect(countAfterRebuild, equals(1));
      },
    );
  });
}
