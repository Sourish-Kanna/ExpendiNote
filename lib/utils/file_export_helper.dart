import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'logger.dart';

class FileExportHelper {
  static const String folderName = 'ExpendiNote';

  /// Returns the target Directory for saving user exports (`Downloads/ExpendiNote`).
  /// Throws [FileSystemException] if the directory cannot be created.
  static Future<Directory> getExpendiNoteDownloadsDirectory() async {
    Directory? downloadsDir;

    if (Platform.isAndroid) {
      // Primary public Download path on Android devices
      final publicDownloadDir = Directory('/storage/emulated/0/Download');
      if (await publicDownloadDir.exists()) {
        downloadsDir = publicDownloadDir;
      } else {
        try {
          downloadsDir = await getDownloadsDirectory();
        } catch (_) {}
        downloadsDir ??= await getExternalStorageDirectory();
      }
    } else {
      // Desktop / iOS / macOS
      try {
        downloadsDir = await getDownloadsDirectory();
      } catch (_) {}
      downloadsDir ??= await getApplicationDocumentsDirectory();
    }

    if (downloadsDir == null) {
      throw const FileSystemException(
        'Could not locate Downloads directory on this device.',
      );
    }

    final targetDir = Directory('${downloadsDir.path}/$folderName');

    if (!await targetDir.exists()) {
      try {
        await targetDir.create(recursive: true);
        AppLogger.info('Created export folder at ${targetDir.path}');
      } catch (e) {
        AppLogger.error('Failed to create folder at ${targetDir.path}', e);
        throw FileSystemException(
          'Could not create ExpendiNote folder in Downloads: $e',
          targetDir.path,
        );
      }
    }

    return targetDir;
  }

  /// Saves content string to a file in `Downloads/ExpendiNote/<fileName>`.
  static Future<File> saveToDownloads(String fileName, String content) async {
    final dir = await getExpendiNoteDownloadsDirectory();
    final file = File('${dir.path}/$fileName');

    try {
      await file.writeAsString(content);
      AppLogger.info('Saved file successfully to ${file.path}');
      return file;
    } catch (e, stack) {
      AppLogger.error('Failed to write file to Downloads', e, stack);
      throw FileSystemException(
        'Failed to save $fileName to Downloads/ExpendiNote: $e',
        file.path,
      );
    }
  }
}
