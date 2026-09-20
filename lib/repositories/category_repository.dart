import 'package:sqflite/sqflite.dart' as sql;

import '../constants/database_constants.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class CategoryRepository {
  static DatabaseService get _dbService => DatabaseService.instance;

  static Future<int> createCategory(Category category) async {
    final db = await _dbService.database;
    return await db.insert(
      DbTables.categories,
      category.toMap(),
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  static Future<int> updateCategory(Category category) async {
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

  static Future<List<Category>> getAllCategories({
    bool includeArchived = false,
  }) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      DbTables.categories,
      where: includeArchived ? null : '${DbCols.isArchived} = 0',
      orderBy: '${DbCols.isPinned} DESC, ${DbCols.name} COLLATE NOCASE ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  static Future<List<Map<String, dynamic>>> getCategoriesWithStats() async {
    final db = await _dbService.database;
    return await db.rawQuery('''
      SELECT 
        c.*,
        COUNT(t.${DbCols.id}) AS transactionCount,
        SUM(t.${DbCols.amount}) AS totalAmount
      FROM ${DbTables.categories} c
      LEFT JOIN ${DbTables.transactions} t ON c.${DbCols.id} = t.${DbCols.categoryId}
      WHERE c.${DbCols.isArchived} = 0
      GROUP BY c.${DbCols.id}
      ORDER BY c.${DbCols.isPinned} DESC, c.${DbCols.name} COLLATE NOCASE ASC
    ''');
  }

  static Future<Category?> getById(int id) async {
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

  static Future<bool> isNameTaken(String name, {int? excludeId}) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> found = await db.query(
      DbTables.categories,
      where: 'LOWER(${DbCols.name}) = LOWER(?) AND ${DbCols.id} != ?',
      whereArgs: [name.trim(), excludeId ?? -1],
      limit: 1,
    );
    return found.isNotEmpty;
  }

  static Future<int> ensureCategoryByName(String name) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> found = await db.query(
      DbTables.categories,
      where: 'LOWER(${DbCols.name}) = LOWER(?)',
      whereArgs: [name.trim()],
      limit: 1,
    );
    if (found.isNotEmpty) return found.first[DbCols.id] as int;

    final now = DateTime.now().toIso8601String();
    return await db.insert(DbTables.categories, {
      DbCols.name: name.trim(),
      DbCols.createdAt: now,
      DbCols.isPinned: 0,
      DbCols.isArchived: 0,
    });
  }

  static Future<void> mergeCategories(int sourceId, int destinationId) async {
    final db = await _dbService.database;
    await db.transaction((txn) async {
      // 1. Reassign all transactions
      await txn.update(
        DbTables.transactions,
        {DbCols.categoryId: destinationId},
        where: '${DbCols.categoryId} = ?',
        whereArgs: [sourceId],
      );

      // 2. Delete source category
      await txn.delete(
        DbTables.categories,
        where: '${DbCols.id} = ?',
        whereArgs: [sourceId],
      );
    });
  }

  static Future<int> deleteCategory(int id) async {
    final db = await _dbService.database;
    // Prevent deleting categories that are currently referenced by transactions
    final inUse = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM ${DbTables.transactions} WHERE ${DbCols.categoryId} = ?',
      [id],
    );
    final count = inUse.isNotEmpty ? (inUse.first['c'] as int? ?? 0) : 0;
    if (count > 0) {
      throw StateError(
        'Categories cannot be deleted because they may be used by existing transactions. You can rename or merge a category instead.',
      );
    }
    return await db.delete(
      DbTables.categories,
      where: '${DbCols.id} = ?',
      whereArgs: [id],
    );
  }
}
