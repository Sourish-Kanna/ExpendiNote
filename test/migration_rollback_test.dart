import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expend_note/constants/database_constants.dart';

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfi;

  test('migration rollback on exception preserves original DB', () async {
    final tmp = Directory.systemTemp.createTempSync('rollback_test_');
    final dbPath = join(tmp.path, 'rollback_test.db');
    final f = File(dbPath);
    if (await f.exists()) await f.delete();

    // create v1 legacy DB
    final dbV1 = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE ${DbTables.legacySpendings}(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, amount REAL, date TEXT, category TEXT, description TEXT)',
          );
          await db.insert(DbTables.legacySpendings, {
            'title': 'KeepMe',
            'amount': 42.0,
            'date': DateTime.now().toIso8601String(),
            'category': 'Test',
          });
        },
      ),
    );
    await dbV1.close();

    // Attempt upgrade that will throw inside a transaction
    try {
      await factory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 2,
          onUpgrade: (db, oldV, newV) async {
            await db.transaction((txn) async {
              await txn.execute('CREATE TABLE temp_changes(x INTEGER)');
              await txn.insert('temp_changes', {'x': 1});
              throw Exception('Simulated migration failure');
            });
          },
        ),
      );
      fail('Upgrade should have thrown');
    } catch (_) {
      // expected
    }

    // Reopen DB as v1 to inspect contents — upgrade should have rolled back
    final db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(version: 1),
    );

    // legacy table should still exist and contain the inserted row
    final res = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.legacySpendings}',
    );
    final count = res.isNotEmpty ? (res.first['c'] as int) : 0;
    expect(count, 1);

    // temp_changes table should NOT exist
    final idxs = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='temp_changes'",
    );
    expect(idxs, isEmpty);

    await db.close();
    await tmp.delete(recursive: true);
  });
}
