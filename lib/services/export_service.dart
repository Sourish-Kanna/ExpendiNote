import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart' as txmodel;
import '../utils/logger.dart';

class ExportService {
  Future<void> exportToCSV(List<txmodel.Transaction> transactions) async {
    AppLogger.info(
      'Exporting ${transactions.length} v2 transactions to CSV...',
    );
    try {
      final List<List<dynamic>> rows = [];

      // CSV Header Row
      rows.add([
        'ID',
        'Title',
        'Amount',
        'Date',
        'Time',
        'Day',
        'Category ID',
        'Category Name',
        'Description',
        'Include In Spending Analysis',
      ]);

      // Populate rows using v2 Transaction schema fields
      for (final t in transactions) {
        rows.add([
          t.id,
          t.title,
          t.amount,
          DateFormat('yyyy-MM-dd').format(t.date),
          DateFormat('HH:mm:ss').format(t.date),
          DateFormat('EEEE').format(t.date),
          t.categoryId ?? '',
          t.categoryName ?? 'Uncategorized',
          t.description ?? '',
          t.includeInSpendingAnalysis,
        ]);
      }

      final String csvString = csv.encode(rows);

      final directory = await getTemporaryDirectory();
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/transactions_$dateStamp.csv');
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Transactions Export - $dateStamp',
          subject: 'Transactions Export',
        ),
      );

      AppLogger.info('CSV export completed successfully.');
    } catch (e, stackTrace) {
      AppLogger.error('CSV export failed', e, stackTrace);
      rethrow;
    }
  }
}
