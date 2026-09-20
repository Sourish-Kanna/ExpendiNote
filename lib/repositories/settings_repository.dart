import 'package:sqflite/sqflite.dart' as sql;

import '../constants/database_constants.dart';
import '../services/database_service.dart';

class SettingsRepository {
  static DatabaseService get _dbService => DatabaseService.instance;

  static Future<void> set(String key, String? value) async {
    final db = await _dbService.database;
    await db.insert(DbTables.settings, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  static Future<String?> get(String key) async {
    final db = await _dbService.database;
    final rows = await db.query(
      DbTables.settings,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<int> delete(String key) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.settings,
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  /// Convenience helper for boolean setting values
  static Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final val = await get(key);
    if (val == null) return defaultValue;
    return val.toLowerCase() == 'true';
  }

  /// Convenience helper for setting boolean values
  static Future<void> setBool(String key, bool value) async {
    await set(key, value.toString());
  }

  /// Convenience helper for integer setting values
  static Future<int?> getInt(String key) async {
    final val = await get(key);
    if (val == null) return null;
    return int.tryParse(val);
  }
}
