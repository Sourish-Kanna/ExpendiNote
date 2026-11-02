import 'dart:io';
import 'dart:typed_data';

import 'package:expend_note/constants/database_constants.dart';
import 'package:expend_note/repositories/settings_repository.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/theme/app_colors.dart';
import 'package:expend_note/theme/app_theme_controller.dart';
import 'package:flutter/services.dart';
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
      'theme_controller_test_',
    );
    databaseFactory.setDatabasesPath(tempDir.path);
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));

    // Reset default binary messenger mock handler for dynamic_color plugin
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('io.material.plugins/dynamic_color'),
          (MethodCall call) async => null,
        );

    await DatabaseService.instance.database;
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  group('AppThemeController Tests', () {
    test('loads and retains a saved theme mode', () async {
      await SettingsRepository.set('theme_mode', 'dark');

      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.themeMode, equals(ThemeMode.dark));
    });

    test('loads a saved custom-theme preference when true', () async {
      await SettingsRepository.setBool('custom_theme_enabled', true);

      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.customThemeEnabled, isTrue);
    });

    test('loads a saved custom-theme preference when false', () async {
      await SettingsRepository.setBool('custom_theme_enabled', false);

      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.customThemeEnabled, isFalse);
    });

    test('loads a saved theme color', () async {
      await SettingsRepository.set('selected_theme_color', 'Purple');

      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.selectedThemeColor, equals(AppThemeColor.purple));
    });

    test('applies default settings when saved settings are absent', () async {
      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.themeMode, equals(ThemeMode.system));
      expect(controller.selectedThemeColor, equals(AppThemeColor.blue));
      // When corePalette is null (no dynamic colors), default customThemeEnabled is true and persisted
      expect(controller.customThemeEnabled, isTrue);
      expect(await SettingsRepository.getBool('custom_theme_enabled'), isTrue);
    });

    test(
      'applies defaults when saved theme mode or color are invalid',
      () async {
        await SettingsRepository.set('theme_mode', 'invalid_mode');
        await SettingsRepository.set('selected_theme_color', 'InvalidColor');

        final controller = AppThemeController();
        await Future.delayed(const Duration(milliseconds: 50));

        expect(controller.themeMode, equals(ThemeMode.system));
        expect(controller.selectedThemeColor, equals(AppThemeColor.blue));
      },
    );

    test(
      'applies customThemeEnabled = false default when dynamic color core palette is available',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              const MethodChannel('io.material.plugins/dynamic_color'),
              (MethodCall call) async {
                if (call.method == 'getCorePalette') {
                  return Int32List.fromList(List<int>.filled(65, 0xFF123456));
                }
                return null;
              },
            );

        final controller = AppThemeController();
        await Future.delayed(const Duration(milliseconds: 50));

        expect(controller.customThemeEnabled, isFalse);
        expect(
          await SettingsRepository.getBool('custom_theme_enabled'),
          isFalse,
        );
      },
    );

    test(
      'setThemeMode updates state, notifies listeners, and persists choice',
      () async {
        await SettingsRepository.setBool('custom_theme_enabled', true);
        final controller = AppThemeController();
        await Future.delayed(const Duration(milliseconds: 50));

        bool listenerNotified = false;
        controller.addListener(() {
          listenerNotified = true;
        });

        await controller.setThemeMode(ThemeMode.light);

        expect(controller.themeMode, equals(ThemeMode.light));
        expect(listenerNotified, isTrue);
        expect(await SettingsRepository.get('theme_mode'), equals('light'));
      },
    );

    test(
      'setCustomThemeEnabled updates state, notifies listeners, and persists choice',
      () async {
        await SettingsRepository.setBool('custom_theme_enabled', false);
        final controller = AppThemeController();
        await Future.delayed(const Duration(milliseconds: 50));

        bool listenerNotified = false;
        controller.addListener(() {
          listenerNotified = true;
        });

        await controller.setCustomThemeEnabled(true);

        expect(controller.customThemeEnabled, isTrue);
        expect(listenerNotified, isTrue);
        expect(
          await SettingsRepository.getBool('custom_theme_enabled'),
          isTrue,
        );
      },
    );

    test(
      'setSelectedThemeColor updates color, notifies listeners, and persists choice',
      () async {
        await SettingsRepository.setBool('custom_theme_enabled', true);
        final controller = AppThemeController();
        await Future.delayed(const Duration(milliseconds: 50));

        bool listenerNotified = false;
        controller.addListener(() {
          listenerNotified = true;
        });

        await controller.setSelectedThemeColor(AppThemeColor.orange);

        expect(controller.selectedThemeColor, equals(AppThemeColor.orange));
        expect(listenerNotified, isTrue);
        expect(
          await SettingsRepository.get('selected_theme_color'),
          equals('Orange'),
        );
      },
    );

    test('AppThemeColor.fromName handles all 4 color options and fallback', () {
      expect(AppThemeColor.fromName('Blue'), equals(AppThemeColor.blue));
      expect(AppThemeColor.fromName('Green'), equals(AppThemeColor.green));
      expect(AppThemeColor.fromName('Purple'), equals(AppThemeColor.purple));
      expect(AppThemeColor.fromName('Orange'), equals(AppThemeColor.orange));
      expect(
        AppThemeColor.fromName('InvalidColor'),
        equals(AppThemeColor.blue),
      );
      expect(AppThemeColor.fromName(null), equals(AppThemeColor.blue));
    });
  });
}
