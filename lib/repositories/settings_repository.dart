import 'package:sqflite/sqflite.dart' as sql;

import '../services/database_service.dart';

class SettingsRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<void> set(String key, String? value) async {
    final db = await _dbService.database;
    await db.insert('settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
  }

  Future<String?> get(String key) async {
    final db = await _dbService.database;
    final rows = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<int> delete(String key) async {
    final db = await _dbService.database;
    return await db.delete('settings', where: 'key = ?', whereArgs: [key]);
  }
}
