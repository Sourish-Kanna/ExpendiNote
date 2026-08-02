import 'package:sqflite/sqflite.dart' as sql;

import '../constants/database_constants.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryRepository {
  final DatabaseService _dbService = DatabaseService();

  Future<int> createCategory(Category category) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.categories,
      category.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCategory(Category category) async {
    if (category.id == null) {
      throw ArgumentError('Category id is required for update');
    }
    final db = await _dbService.database;
    return await db.update(
      DbTables.categories,
      category.toMap(),
      where: '${DbCols.id} = ?',
      whereArgs: [category.id],
    );
  }

  Future<List<Category>> getAllCategories() async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.categories,
      orderBy: '${DbCols.name} COLLATE NOCASE ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.categories,
      where: '${DbCols.id} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> ensureCategoryByName(String name) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> found = await db.query(
      DbTables.categories,
      where: 'LOWER(${DbCols.name}) = LOWER(?)',
      whereArgs: [name],
      limit: 1,
    );
    if (found.isNotEmpty) return found.first['id'] as int;
    final now = DateTime.now().toIso8601String();
    return await db.insert(DbTables.categories, {
      DbCols.name: name,
      DbCols.createdAt: now,
    });
  }

  Future<int> deleteCategory(int id) async {
    final db = await _dbService.database;
    // Prevent deleting categories that are in use
    final inUse = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.transactions} WHERE ${DbCols.categoryId} = ?',
      [id],
    );
    final count = inUse.isNotEmpty ? (inUse.first['c'] as int) : 0;
    if (count > 0) {
      throw StateError('Cannot delete category that has $count transactions');
    }
    return await db.delete(
      DbTables.categories,
      where: '${DbCols.id} = ?',
      whereArgs: [id],
    );
  }
}
