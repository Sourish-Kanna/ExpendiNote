import 'dart:convert';
import 'dart:io';
import 'dart:math' show Random;

import 'package:file_picker/file_picker.dart';
import 'package:sqflite/sqflite.dart' as sql;

import '../constants/database_constants.dart';
import '../repositories/category_repository.dart';
import '../services/database_service.dart';
import '../services/export_migrations/export_migration_service.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import '../utils/logger.dart';

enum RestoreMode { merge, replaceExistingTransactions }

class RestoreResult {
  final bool isSuccess;
  final bool isCancelled;
  final int transactionsRestored;
  final String? errorMessage;
  final bool isUnsupportedVersion;

  const RestoreResult.success({required this.transactionsRestored})
    : isSuccess = true,
      isCancelled = false,
      errorMessage = null,
      isUnsupportedVersion = false;

  const RestoreResult.cancelled()
    : isSuccess = false,
      isCancelled = true,
      transactionsRestored = 0,
      errorMessage = null,
      isUnsupportedVersion = false;

  const RestoreResult.failure(
    this.errorMessage, {
    this.isUnsupportedVersion = false,
  }) : isSuccess = false,
       isCancelled = false,
       transactionsRestored = 0;
}

class ImportService {
  static const _defaultCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Healthcare',
    'Investment',
    'Others',
  ];

  Future<int> getCurrentTransactionCount() async {
    final db = await DatabaseService.instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM ${DbTables.transactions}',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  /// Prompts user to pick a JSON backup file and restores it atomically.
  Future<RestoreResult> restoreFromJSON() async {
    try {
      // Ensure system/default categories exist before any restore operation.
      for (final name in _defaultCategories) {
        await CategoryRepository.ensureCategoryByName(name);
      }

      // 1. Pick JSON backup file
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result.isEmpty || result.first.path == null) {
        AppLogger.info('Restore cancelled: no file selected.');
        return const RestoreResult.cancelled();
      }

      final fileInfo = result.first;

      if (!fileInfo.name.toLowerCase().endsWith('.json')) {
        AppLogger.warning('Selected file is not a JSON file: ${fileInfo.name}');
        return const RestoreResult.failure(
          'Selected file is not a JSON backup file (.json).',
        );
      }

      final file = File(fileInfo.path!);
      final content = await file.readAsString();

      dynamic parsedJson;
      try {
        parsedJson = json.decode(content);
      } catch (e) {
        AppLogger.warning('Failed to parse JSON file: $e');
        return const RestoreResult.failure(
          'Failed to parse file: Invalid JSON format.',
        );
      }

      // 2. Migrate JSON to latest Export Version format
      Map<String, dynamic> migratedData;
      try {
        migratedData = ExportMigrationService.migrateToLatest(parsedJson);
      } on UnsupportedExportVersionException catch (e) {
        AppLogger.warning('Unsupported export version: ${e.version}');
        return RestoreResult.failure(e.toString(), isUnsupportedVersion: true);
      } catch (e) {
        AppLogger.warning('Migration error: $e');
        return RestoreResult.failure('Backup format error: $e');
      }

      // 3. Validate backup data structure
      final validationError = ExportMigrationService.validateBackupData(
        migratedData,
      );
      if (validationError != null) {
        AppLogger.warning('Validation failed: $validationError');
        return RestoreResult.failure(
          'Invalid backup structure: $validationError',
        );
      }

      // 4. Perform atomic database restore
      final restoredCount = await _executeDatabaseRestore(migratedData, mode);

      AppLogger.info(
        'Restore completed successfully. $restoredCount transactions restored.',
      );
      return RestoreResult.success(transactionsRestored: restoredCount);
    } catch (e, stackTrace) {
      AppLogger.error('Restore failed unexpectedly', e, stackTrace);
      return RestoreResult.failure('Restore failed: ${e.toString()}');
    }
  }

  /// Restores already-migrated backup data using the selected restore mode.
  Future<int> restoreMigratedData(
    Map<String, dynamic> backupDataMap, {
    RestoreMode mode = RestoreMode.replaceExistingTransactions,
    sql.Database? database,
  }) {
    return _executeDatabaseRestore(backupDataMap, mode, database: database);
  }

  /// Executes atomic restore inside a single SQLite transaction.
  Future<int> _executeDatabaseRestore(
    Map<String, dynamic> backupDataMap,
    RestoreMode mode, {
    sql.Database? database,
  }) async {
    final db = database ?? await DatabaseService.instance.database;

    final data = Map<String, dynamic>.from(backupDataMap['data'] as Map);
    final rawCategories = data['categories'] as List? ?? [];
    final rawTransactions = data['transactions'] as List? ?? [];
    final rawSettings = data['settings'] as List? ?? [];

    int restoredCount = 0;

    await db.transaction((txn) async {
      // Step A: Preserve default categories and apply the selected transaction mode.
      final defaultCategoryNames = _defaultCategories
          .map((name) => name.toLowerCase())
          .toSet();

      if (mode == RestoreMode.replaceExistingTransactions) {
        await txn.delete(DbTables.transactions);
        await txn.delete(
          DbTables.categories,
          where:
              'LOWER(${DbCols.name}) NOT IN (?, ?, ?, ?, ?, ?, ?, ?)',
          whereArgs: defaultCategoryNames.toList(),
        );
      }

      // Step B: Build category lookup maps from categories that remain.
      final categoryIdMap = <int, int>{};
      final categoryNameMap = <String, int>{};
      final existingCategories = await txn.query(DbTables.categories);
      for (final category in existingCategories) {
        final id = category[DbCols.id] as int;
        final name = (category[DbCols.name] as String).trim();
        categoryIdMap[id] = id;
        categoryNameMap[name.toLowerCase()] = id;
      }

      final random = Random();
      final availableIcons = IconUtils.getAvailableIcons();
      final availableColors = ColorUtils.getAvailableColors();

      for (final rawCat in rawCategories) {
        if (rawCat is! Map) continue;
        final catMap = Map<String, dynamic>.from(rawCat);

        final oldId = catMap['id'] as int?;
        final name = (catMap['name'] as String? ?? 'Others').trim();

        var icon = catMap['icon'] as String?;
        if (icon == null || icon.trim().isEmpty) {
          icon = IconUtils.iconToString(
            availableIcons[random.nextInt(availableIcons.length)],
          );
        }

        var color = catMap['color'] as int?;
        color ??= ColorUtils.colorToInt(
          availableColors[random.nextInt(availableColors.length)],
        );

        final isPinnedVal = catMap['is_pinned'] ?? catMap['isPinned'];
        final isPinned = isPinnedVal == true || isPinnedVal == 1;

        final isArchivedVal = catMap['is_archived'] ?? catMap['isArchived'];
        final isArchived = isArchivedVal == true || isArchivedVal == 1;

        final rawInclude =
            catMap['include_in_spending_analysis'] ??
            catMap['includeInSpendingAnalysis'];
        final includeInSpendingAnalysis = rawInclude == null
            ? true
            : (rawInclude == true || rawInclude == 1);

        final createdAt =
            catMap['created_at'] as String? ??
            catMap['createdAt'] as String? ??
            DateTime.now().toIso8601String();

        final existingCategoryId = categoryNameMap[name.toLowerCase()];
        final finalCatId = existingCategoryId ??
            await txn.insert(DbTables.categories, {
          DbCols.id: null,
          DbCols.name: name,
          DbCols.icon: icon,
          DbCols.color: color,
          DbCols.isPinned: isPinned ? 1 : 0,
          DbCols.isArchived: isArchived ? 1 : 0,
          DbCols.includeInSpendingAnalysis: includeInSpendingAnalysis ? 1 : 0,
          DbCols.createdAt: createdAt,
        }, conflictAlgorithm: sql.ConflictAlgorithm.ignore);
        if (oldId != null) {
          categoryIdMap[oldId] = finalCatId;
        }
        categoryNameMap[name.toLowerCase()] = finalCatId;
      }

      // Step C: Insert transactions
      for (final rawTx in rawTransactions) {
        if (rawTx is! Map) continue;
        final txMap = Map<String, dynamic>.from(rawTx);

        final title = (txMap['title'] as String? ?? '').trim();

        final rawAmount = txMap['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

        final dateStr =
            txMap['date'] as String? ?? DateTime.now().toIso8601String();

        final rawCatId = txMap['category_id'] ?? txMap['categoryId'];
        final rawCatName =
            txMap['category_name'] ??
            txMap['categoryName'] ??
            txMap['category'];

        int? categoryId;
        if (rawCatId != null &&
            rawCatId is int &&
            categoryIdMap.containsKey(rawCatId)) {
          categoryId = categoryIdMap[rawCatId];
        } else if (rawCatName != null &&
            rawCatName is String &&
            categoryNameMap.containsKey(rawCatName.trim().toLowerCase())) {
          categoryId = categoryNameMap[rawCatName.trim().toLowerCase()];
        }

        // Dynamically create category if transaction specifies a category name missing from category table
        if (categoryId == null &&
            rawCatName != null &&
            rawCatName is String &&
            rawCatName.trim().isNotEmpty) {
          final catNameClean = rawCatName.trim();
          final catKey = catNameClean.toLowerCase();
          if (categoryNameMap.containsKey(catKey)) {
            categoryId = categoryNameMap[catKey];
          } else {
            final nowStr = DateTime.now().toIso8601String();
            final randomIcon = IconUtils.iconToString(
              availableIcons[random.nextInt(availableIcons.length)],
            );
            final randomColor = ColorUtils.colorToInt(
              availableColors[random.nextInt(availableColors.length)],
            );
            final newCatId = await txn.insert(DbTables.categories, {
              DbCols.name: catNameClean,
              DbCols.icon: randomIcon,
              DbCols.color: randomColor,
              DbCols.createdAt: nowStr,
              DbCols.includeInSpendingAnalysis: catKey == 'investment' ? 0 : 1,
            }, conflictAlgorithm: sql.ConflictAlgorithm.ignore);
            categoryId = newCatId;
            categoryNameMap[catKey] = newCatId;
          }
        }

        final description = txMap['description'] as String?;

        final rawInclude =
            txMap['include_in_spending_analysis'] ??
            txMap['includeInSpendingAnalysis'];
        final includeInSpendingAnalysis = rawInclude == null
            ? true
            : (rawInclude == true || rawInclude == 1);

        final createdAt =
            txMap['created_at'] as String? ??
            txMap['createdAt'] as String? ??
            DateTime.now().toIso8601String();

        await txn.insert(DbTables.transactions, {
                    DbCols.title: title,
          DbCols.amount: amount,
          DbCols.date: dateStr,
          DbCols.categoryId: categoryId,
          DbCols.description: description,
          DbCols.includeInSpendingAnalysis: includeInSpendingAnalysis ? 1 : 0,
          DbCols.createdAt: createdAt,
        }, conflictAlgorithm: sql.ConflictAlgorithm.abort);

        restoredCount++;
      }

      // Step D: Update settings if provided
      if (rawSettings.isNotEmpty) {
        for (final rawSetting in rawSettings) {
          if (rawSetting is! Map) continue;
          final settingMap = Map<String, dynamic>.from(rawSetting);
          final key = settingMap['key'] as String?;
          final value = settingMap['value'] as String?;

          if (key != null && key.trim().isNotEmpty) {
            await txn.insert(DbTables.settings, {
              'key': key.trim(),
              'value': value,
            }, conflictAlgorithm: sql.ConflictAlgorithm.replace);
          }
        }
      }
    });

    return restoredCount;
  }
}
