import 'package:sqflite/sqflite.dart' as sql;

import '../constants/database_constants.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';

class TransactionRepository {
  final DatabaseService _dbService;

  TransactionRepository({DatabaseService? dbService})
    : _dbService = dbService ?? DatabaseService();

  Future<int> insertTransaction(Transaction tx) async {
    final db = await _dbService.database;
    final map = tx.toMap();
    return await db.insert(
      DbTables.transactions,
      map,
      conflictAlgorithm: sql.ConflictAlgorithm.replace,
    );
  }

  Future<int> updateTransaction(Transaction tx) async {
    if (tx.id == null) {
      throw ArgumentError('Transaction id is required for update');
    }
    final db = await _dbService.database;
    final map = tx.toMap();
    return await db.update(
      DbTables.transactions,
      map,
      where: '${DbCols.id} = ?',
      whereArgs: [tx.id],
    );
  }

  Future<List<Transaction>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    final db = await _dbService.database;
    final q = StringBuffer('''
      SELECT t.*, 
             c.${DbCols.name} AS categoryName,
             c.${DbCols.icon} AS categoryIcon,
             c.${DbCols.color} AS categoryColor
      FROM ${DbTables.transactions} t 
      LEFT JOIN ${DbTables.categories} c ON t.${DbCols.categoryId} = c.${DbCols.id} 
      ORDER BY t.${DbCols.date} DESC
      ''');
    if (limit != null) q.write(' LIMIT $limit');
    if (offset != null) q.write(' OFFSET $offset');

    final List<Map<String, dynamic>> maps = await db.rawQuery(q.toString());
    return maps.map((m) => Transaction.fromMap(m)).toList();
  }

  /// Returns raw maps joined with category name for legacy UI components
  Future<List<Map<String, dynamic>>> getAllWithCategoryName({
    int? limit,
    int? offset,
  }) async {
    final db = await _dbService.database;
    final q = StringBuffer('''
      SELECT t.*, 
             c.${DbCols.name} AS categoryName,
             c.${DbCols.icon} AS categoryIcon,
             c.${DbCols.color} AS categoryColor
      FROM ${DbTables.transactions} t 
      LEFT JOIN ${DbTables.categories} c ON t.${DbCols.categoryId} = c.${DbCols.id} 
      ORDER BY t.${DbCols.date} DESC
      ''');
    if (limit != null) q.write(' LIMIT $limit');
    if (offset != null) q.write(' OFFSET $offset');

    final List<Map<String, dynamic>> maps = await db.rawQuery(q.toString());
    return maps;
  }

  Future<Transaction?> getById(int id) async {
    final db = await _dbService.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT t.*, 
             c.${DbCols.name} AS categoryName,
             c.${DbCols.icon} AS categoryIcon,
             c.${DbCols.color} AS categoryColor
      FROM ${DbTables.transactions} t 
      LEFT JOIN ${DbTables.categories} c ON t.${DbCols.categoryId} = c.${DbCols.id} 
      WHERE t.${DbCols.id} = ? 
      LIMIT 1
      ''',
      [id],
    );
    if (maps.isEmpty) return null;
    return Transaction.fromMap(maps.first);
  }

  Future<int> deleteTransaction(int id) async {
    final db = await _dbService.database;
    return await db.delete(
      DbTables.transactions,
      where: '${DbCols.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> searchTransactions(String keyword) async {
    final db = await _dbService.database;
    final searchPattern = '%${keyword.trim().toLowerCase()}%';

    return await db.rawQuery(
      '''
      SELECT t.${DbCols.id}, t.${DbCols.title}, t.${DbCols.amount}, 
             t.${DbCols.date}, COALESCE(c.${DbCols.name}, '') AS category, 
             t.${DbCols.description} 
      FROM ${DbTables.transactions} t 
      LEFT JOIN ${DbTables.categories} c ON t.${DbCols.categoryId} = c.${DbCols.id} 
      WHERE LOWER(t.${DbCols.title}) LIKE ? 
         OR LOWER(t.${DbCols.description}) LIKE ? 
         OR LOWER(c.${DbCols.name}) LIKE ? 
      ORDER BY t.${DbCols.date} DESC
      ''',
      [searchPattern, searchPattern, searchPattern],
    );
  }
}
