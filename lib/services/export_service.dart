import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../models/spending.dart';
import 'database_service.dart';

class ExportService {
  final Logger _logger = Logger();

  // --- 1. EXPORT TO JSON & SHARE ---
  Future<void> exportToJSON(List<Spending> spendings) async {
    _logger.i('Exporting ${spendings.length} spendings to JSON...');
    try {
      final List<Map<String, dynamic>> jsonList =
      spendings.map((s) => s.toMap()).toList();

      final String jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      final directory = await getTemporaryDirectory();
      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/spendings_backup_$dateStamp.json');
      await file.writeAsString(jsonString);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Spendings JSON Backup - $dateStamp',
        ),
      );
      _logger.i('JSON sharing successful.');
    } catch (e) {
      _logger.e('JSON export failed: $e');
    }
  }

  // --- 2. SAVE JSON TO DEVICE DOWNLOADS ---
  Future<bool> saveJSONToDevice(List<Spending> spendings) async {
    _logger.i('Saving JSON backup to device storage...');
    try {
      final List<Map<String, dynamic>> jsonList =
      spendings.map((s) => s.toMap()).toList();
      final String jsonString = const JsonEncoder.withIndent('  ').convert(jsonList);

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      if (targetDir == null) return false;

      final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupPath = join(targetDir.path, 'spending_backup_$dateStamp.json');

      final file = File(backupPath);
      await file.writeAsString(jsonString);
      _logger.i('JSON backup saved to: $backupPath');
      return true;
    } catch (e) {
      _logger.e('Failed to save JSON to device: $e');
      return false;
    }
  }

  // --- 3. IMPORT FROM JSON STRING / RAW DATA ---
  Future<bool> importFromJSONString(String jsonContent) async {
    _logger.i('Parsing and restoring from JSON string...');
    try {
      final dynamic decoded = jsonDecode(jsonContent);
      if (decoded is! List) {
        _logger.e('Invalid JSON format: Expected a JSON array.');
        return false;
      }

      final db = await DatabaseService().database;

      await db.transaction((txn) async {
        // Clear current entries before restoring
        await txn.delete('spendings');

        for (var item in decoded) {
          if (item is Map<String, dynamic>) {
            await txn.insert(
              'spendings',
              {
                'title': item['title'],
                'amount': item['amount'],
                'date': item['date'],
                'category': item['category'],
                'description': item['description'],
              },
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          }
        }
      });

      _logger.i('JSON restoration completed successfully.');
      return true;
    } catch (e) {
      _logger.e('Failed to import JSON: $e');
      return false;
    }
  }

  // --- 4. IMPORT FROM FILE PATH ---
  Future<bool> importFromJSONFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;
      final content = await file.readAsString();
      return await importFromJSONString(content);
    } catch (e) {
      _logger.e('Failed to read JSON file: $e');
      return false;
    }
  }

  // Existing CSV & DB export methods below...
  Future<void> exportToCSV(List<Spending> spendings) async {
    _logger.i('Exporting ${spendings.length} spendings to CSV...');
    try {
      final List<List<dynamic>> rows = [];
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
    } catch (e) {
      _logger.e('CSV sharing failed: $e');
    }
  }
}