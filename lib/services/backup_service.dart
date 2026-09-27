import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';

import '../constants/app_constants.dart';
import '../constants/database_constants.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../services/database_service.dart';
import '../utils/file_export_helper.dart';
import '../utils/logger.dart';

class BackupExportResult {
  final File file;
  final String displayPath;

  const BackupExportResult({required this.file, required this.displayPath});
}

class BackupService {
  /// Builds the Export Version 1 backup map structure from current database contents.
  Future<Map<String, dynamic>> buildBackupData() async {
    final categories = await CategoryRepository.getAllCategories(
      includeArchived: true,
    );
    final transactions = await TransactionRepository.getAllTransactions();

    final db = await DatabaseService.instance.database;
    final settingsRows = await db.query(DbTables.settings);

    final categoriesJson = categories.map((c) {
      final map = c.toMap();
      return {
        'id': map[DbCols.id],
        'name': map[DbCols.name],
        'icon': map[DbCols.icon],
        'color': map[DbCols.color],
        'is_pinned': map[DbCols.isPinned] == 1,
        'is_archived': map[DbCols.isArchived] == 1,
        'include_in_spending_analysis':
            map[DbCols.includeInSpendingAnalysis] == 1,
        'created_at': map[DbCols.createdAt],
      };
    }).toList();

    final transactionsJson = transactions.map((t) {
      return {
        'id': t.id,
        'title': t.title,
        'amount': t.amount,
        'date': t.date.toIso8601String(),
        'category_id': t.categoryId,
        'category_name': t.categoryName,
        'description': t.description,
        'include_in_spending_analysis': t.includeInSpendingAnalysis,
        'created_at': t.createdAt.toIso8601String(),
      };
    }).toList();

    final settingsJson = settingsRows.map((r) {
      return {'key': r['key'] as String, 'value': r['value'] as String?};
    }).toList();

    return {
      'format': ExportConstants.backupFormatName,
      'export_version': ExportConstants.currentExportVersion,
      'app_version': await AppConstants.getAppVersion(),
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'data': {
        'categories': categoriesJson,
        'transactions': transactionsJson,
        'settings': settingsJson,
      },
    };
  }

  /// Creates a timestamped JSON backup file in Downloads/ExpendiNote.
  Future<BackupExportResult> createBackupFile() async {
    AppLogger.info('Generating JSON backup file...');
    final backupData = await buildBackupData();
    const encoder = JsonEncoder.withIndent('  ');
    final jsonString = encoder.convert(backupData);

    final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'expendinote_backup_$dateStamp.json';

    final file = await FileExportHelper.saveToDownloads(fileName, jsonString);

    AppLogger.info('JSON backup created at ${file.path}');
    return BackupExportResult(
      file: file,
      displayPath: 'Downloads/ExpendiNote/$fileName',
    );
  }
}
