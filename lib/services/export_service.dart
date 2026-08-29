import 'dart:io';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../models/spending.dart';

class ExportService {
  final Logger _logger = Logger();

  Future<void> exportToCSV(List<Spending> spendings) async {
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

  Future<void> exportDatabaseFile() async {
    _logger.i('Exporting SQLite database file...');
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = join(dbDir, 'spending_database.db');
      final dbFile = File(dbPath);

      if (await dbFile.exists()) {
        final dateStamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(dbFile.path)],
            text: 'ExpendiNote DB Backup - $dateStamp',
          ),
        );
        _logger.i('Database export successful.');
      } else {
        _logger.w('Database file does not exist at $dbPath');
      }
    } catch (e) {
      _logger.e('Database export failed: $e');
    }
  }

  Future<bool> saveDatabaseToDevice() async {
    _logger.i('Saving SQLite database to device storage...');
    try {
      final dbDir = await getDatabasesPath();
      final dbPath = join(dbDir, 'spending_database.db');
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        _logger.w('Database file does not exist at $dbPath');
        return false;
      }

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
      final backupPath = join(targetDir.path, 'spending_backup_$dateStamp.db');

      await dbFile.copy(backupPath);
      _logger.i('Database copied to: $backupPath');
      return true;
    } catch (e) {
      _logger.e('Failed to save database to device: $e');
      return false;
    }
  }

  // // --- IMPORT DB & VERIFY INTEGRITY ---
  // Future<bool> importDatabase() async {
  //   _logger.i('Picking backup database file...');
  //   try {
  //     final result = await FilePicker.platform.pickFiles(type: FileType.any);
  //
  //     if (result == null ||
  //         result.files.isEmpty ||
  //         result.files.single.path == null) {
  //       _logger.i('File picking canceled.');
  //       return false;
  //     }
  //
  //     final pickedFilePath = result.files.single.path!;
  //     final pickedFile = File(pickedFilePath);
  //
  //     // Validate selected file by opening it temporarily
  //     try {
  //       final tempDb = await openReadOnlyDatabase(pickedFile.path);
  //       final tables = await tempDb.rawQuery(
  //         "SELECT name FROM sqlite_master WHERE type='table' AND name='spendings';",
  //       );
  //
  //       if (tables.isEmpty) {
  //         _logger.e('Selected database does not contain spendings table.');
  //         await tempDb.close();
  //         return false;
  //       }
  //       await tempDb.close();
  //     } catch (e) {
  //       _logger.e('Invalid SQLite database file: $e');
  //       return false;
  //     }
  //
  //     // 1. Close active connection and clear reference
  //     await DatabaseService().resetDatabaseConnection();
  //
  //     // 2. Overwrite current DB file with chosen backup
  //     final dbDir = await getDatabasesPath();
  //     final dbPath = join(dbDir, 'spending_database.db');
  //     await pickedFile.copy(dbPath);
  //
  //     // 3. Re-initialize database connection
  //     await DatabaseService().database;
  //
  //     _logger.i('Database restored successfully from ${pickedFile.path}');
  //     return true;
  //   } catch (e) {
  //     _logger.e('Failed to import database: $e');
  //     return false;
  //   }
  // }
}
