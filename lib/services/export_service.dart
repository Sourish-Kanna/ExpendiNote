import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import '../models/spending.dart';
import 'package:intl/intl.dart';

class ExportService {
  final Logger _logger = Logger();

  Future<void> exportToJSON(List<Spending> spendings) async {
    _logger.i('Exporting ${spendings.length} spendings to JSON...');
    try {
      final List<Map<String, dynamic>> jsonList = spendings
          .map((s) => s.toJson())
          .toList();
      final String jsonString = jsonEncode(jsonList);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spendings.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported Spendings (JSON)');
      _logger.i('JSON export successful.');
    } catch (e) {
      _logger.e('JSON export failed: $e');
    }
  }

  Future<void> exportToCSV(List<Spending> spendings) async {
    _logger.i('Exporting ${spendings.length} spendings to CSV...');
    try {
      final List<List<dynamic>> rows = [];

      // Add header
      rows.add(['ID', 'Title', 'Amount', 'Date', 'Category', 'Description']);

      // Add data
      for (var s in spendings) {
        rows.add([
          s.id,
          s.title,
          s.amount,
          DateFormat('yyyy-MM-dd HH:mm').format(s.date),
          s.category,
          s.description ?? '',
        ]);
      }

      final String csvString = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spendings.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Exported Spendings (CSV)');
      _logger.i('CSV export successful.');
    } catch (e) {
      _logger.e('CSV export failed: $e');
    }
  }
}
