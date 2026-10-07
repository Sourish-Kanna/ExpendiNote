import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/settings_repository.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final tempDir = Directory.systemTemp.createTempSync('settings_repo_test_');
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

  group('SettingsRepository Tests', () {
    test('set and get store and retrieve string values', () async {
      await SettingsRepository.set('user_name', 'Alice');
      final val = await SettingsRepository.get('user_name');
      expect(val, equals('Alice'));
    });

    test('get returns null for non-existent setting keys', () async {
      final val = await SettingsRepository.get('non_existent_key');
      expect(val, isNull);
    });

    test('set updates existing key value on conflict', () async {
      await SettingsRepository.set('theme_mode', 'light');
      expect(await SettingsRepository.get('theme_mode'), equals('light'));

      await SettingsRepository.set('theme_mode', 'dark');
      expect(await SettingsRepository.get('theme_mode'), equals('dark'));
    });

    test('delete removes key from settings table', () async {
      await SettingsRepository.set('temp_key', 'temp_val');
      expect(await SettingsRepository.get('temp_key'), equals('temp_val'));

      final count = await SettingsRepository.delete('temp_key');
      expect(count, equals(1));
      expect(await SettingsRepository.get('temp_key'), isNull);
    });

    test(
      'getBool and setBool handle boolean conversion and default values',
      () async {
        expect(
          await SettingsRepository.getBool('custom_theme', defaultValue: true),
          isTrue,
        );
        expect(
          await SettingsRepository.getBool('custom_theme', defaultValue: false),
          isFalse,
        );

        await SettingsRepository.setBool('custom_theme', true);
        expect(await SettingsRepository.getBool('custom_theme'), isTrue);

        await SettingsRepository.setBool('custom_theme', false);
        expect(await SettingsRepository.getBool('custom_theme'), isFalse);
      },
    );

    test(
      'getInt parses integer values or returns null if invalid/missing',
      () async {
        expect(await SettingsRepository.getInt('page_size'), isNull);

        await SettingsRepository.set('page_size', '25');
        expect(await SettingsRepository.getInt('page_size'), equals(25));

        await SettingsRepository.set('page_size', 'invalid_int');
        expect(await SettingsRepository.getInt('page_size'), isNull);
      },
    );

    test('theme settings store and retrieve theme configuration', () async {
      await SettingsRepository.set('theme_mode', 'dark');
      await SettingsRepository.setBool('custom_theme_enabled', true);
      await SettingsRepository.set('selected_theme_color', 'Purple');

      expect(await SettingsRepository.get('theme_mode'), equals('dark'));
      expect(await SettingsRepository.getBool('custom_theme_enabled'), isTrue);
      expect(
        await SettingsRepository.get('selected_theme_color'),
        equals('Purple'),
      );
    });
  });
}
