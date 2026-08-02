import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/services/database_service.dart';
import 'package:expend_note/repositories/settings_repository.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  group('SettingsRepository', () {
    late String dbPath;

    setUp(() async {
      final tmp = Directory.systemTemp.createTempSync('settings_test_');
      dbPath = join(tmp.path, 'settings_test.db');
      final db = await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, v) async {
            await db.execute(
              'CREATE TABLE settings(key TEXT PRIMARY KEY, value TEXT)',
            );
          },
        ),
      );
      DatabaseService.setTestDatabase(db);
    });

    tearDown(() async {
      try {
        final db = await DatabaseService().database;
        await db.close();
      } catch (_) {}
    });

    test('set, get and delete', () async {
      final repo = SettingsRepository();
      await repo.set('k1', 'v1');
      expect(await repo.get('k1'), 'v1');

      await repo.set('k1', null);
      expect(await repo.get('k1'), isNull);

      await repo.set('k2', 'v2');
      final del = await repo.delete('k2');
      expect(del, greaterThanOrEqualTo(0));
      expect(await repo.get('k2'), isNull);
    });
  });
}
