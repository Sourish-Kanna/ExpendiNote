import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart' as txmodel;

class ExportService {
  final Logger _logger = Logger();

  Future<void> exportToCSV(List<txmodel.Transaction> spendings) async {
    _logger.i('Exporting ${spendings.length} spendings to CSV...');
    try {
      final List<List<dynamic>> rows = [];

      // Add header
      rows.add([
        'ID',
        'Title',
        'Amount',
        'Date',
        'Time',
        'Day',
        'Category',
        'Description',
      ]);

      // Add data
      for (var s in spendings) {
        rows.add([
          s.id,
          s.title,
          s.amount,
          DateFormat('yyyy-MM-dd').format(s.date),
          DateFormat('HH:mm:ss').format(s.date),
          DateFormat('EEEE').format(s.date),
          s.category,
          s.description ?? '',
        ]);
      }

      // Modern csv package conversion
      final String csvString = csv.encode(rows);

      final directory = await getTemporaryDirectory();
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/spendings_$dateStamp.csv');
      await file.writeAsString(csvString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Spendings CSV - $dateStamp',
        ),
      );
      _logger.i('CSV sharing successful.');
    } catch (e) {
      _logger.e('CSV sharing failed: $e');
    }
  }
}
