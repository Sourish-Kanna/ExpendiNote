import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../utils/file_export_helper.dart';
import '../utils/logger.dart';

class ExportResult {
  final File file;
  final String displayPath;

  const ExportResult({required this.file, required this.displayPath});
}

class ExportService {
  Future<ExportResult> exportToCSV(
    List<txmodel.Transaction> transactions,
  ) async {
    AppLogger.info('Exporting ${transactions.length} transactions to CSV...');
    try {
      final List<List<dynamic>> rows = [];

      // CSV Header Row
      rows.add([
        'ID',
        'Title',
        'Amount',
        'Date',
        'Time',
        'Category',
        'Description',
        'Include in Spending Analysis',
        'Created At',
      ]);

      final dateFormat = DateFormat('yyyy-MM-dd');
      final timeFormat = DateFormat('HH:mm:ss');
      final dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

      // Populate rows using normalized Transaction schema fields
      for (final t in transactions) {
        rows.add([
          t.id ?? '',
          t.title,
          t.amount,
          dateFormat.format(t.date),
          timeFormat.format(t.date),
          t.categoryName ?? 'Uncategorized',
          t.description ?? '',
          t.includeInSpendingAnalysis ? 'Yes' : 'No',
          dateTimeFormat.format(t.createdAt),
        ]);
      }

      final String csvString = csv.encode(rows);

      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'expendinote_transactions_$dateStamp.csv';

      final file = await FileExportHelper.saveToDownloads(fileName, csvString);

      AppLogger.info('CSV export completed successfully at ${file.path}');
      return ExportResult(
        file: file,
        displayPath: 'Downloads/ExpendiNote/$fileName',
      );
    } catch (e, stackTrace) {
      AppLogger.error('CSV export failed', e, stackTrace);
      rethrow;
    }
  }
}
