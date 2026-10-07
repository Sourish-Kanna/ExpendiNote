import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:material_ui/material_ui.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/settings_repository.dart';
import 'package:expend_note/theme/app_theme_controller.dart';
import 'package:expend_note/theme/app_colors.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    await DatabaseService.instance.closeDatabase();
    final dbPath = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(dbPath, DbConfig.databaseFile));

    // Ensure database tables exist
    await DatabaseService.instance.database;

    // Pre-seed custom_theme_enabled so DynamicColorPlugin platform channel is bypassed
    await SettingsRepository.setBool('custom_theme_enabled', true);
  });

  tearDown(() async {
    await DatabaseService.instance.closeDatabase();
  });

  group('AppThemeController Tests', () {
    test('initializes state from SettingsRepository', () async {
      await SettingsRepository.set('theme_mode', 'dark');
      await SettingsRepository.setBool('custom_theme_enabled', true);
      await SettingsRepository.set('selected_theme_color', 'Purple');

      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.themeMode, equals(ThemeMode.dark));
      expect(controller.customThemeEnabled, isTrue);
      expect(controller.selectedThemeColor, equals(AppThemeColor.purple));
    });

    test('setThemeMode updates state, notifies listeners, and persists choice', () async {
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
    });

    test('setCustomThemeEnabled updates state and persists setting', () async {
      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.setCustomThemeEnabled(false);
      expect(controller.customThemeEnabled, isFalse);
      expect(await SettingsRepository.getBool('custom_theme_enabled'), isFalse);

      await controller.setCustomThemeEnabled(true);
      expect(controller.customThemeEnabled, isTrue);
      expect(await SettingsRepository.getBool('custom_theme_enabled'), isTrue);
    });

    test('setSelectedThemeColor updates color and preserves it when custom theme is disabled', () async {
      final controller = AppThemeController();
      await Future.delayed(const Duration(milliseconds: 50));

      await controller.setSelectedThemeColor(AppThemeColor.orange);
      expect(controller.selectedThemeColor, equals(AppThemeColor.orange));
      expect(await SettingsRepository.get('selected_theme_color'), equals('Orange'));

      // Disable custom theme
      await controller.setCustomThemeEnabled(false);

      // Selected color is preserved in state and persistence
      expect(controller.selectedThemeColor, equals(AppThemeColor.orange));
      expect(await SettingsRepository.get('selected_theme_color'), equals('Orange'));
    });

    test('AppThemeColor.fromName handles all 4 color options and fallback', () {
      expect(AppThemeColor.fromName('Blue'), equals(AppThemeColor.blue));
      expect(AppThemeColor.fromName('Green'), equals(AppThemeColor.green));
      expect(AppThemeColor.fromName('Purple'), equals(AppThemeColor.purple));
      expect(AppThemeColor.fromName('Orange'), equals(AppThemeColor.orange));
      expect(AppThemeColor.fromName('InvalidColor'), equals(AppThemeColor.green)); // fallback
      expect(AppThemeColor.fromName(null), equals(AppThemeColor.green)); // fallback
    });
  });
}
