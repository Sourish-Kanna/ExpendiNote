import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/transaction.dart';
import '../repositories/category_repository.dart';
import '../repositories/transaction_repository.dart';
import '../utils/logger.dart';

class ImportService {
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  ImportService({
    CategoryRepository? categoryRepository,
    TransactionRepository? transactionRepository,
  }) : _categoryRepository = categoryRepository ?? CategoryRepository(),
       _transactionRepository =
           transactionRepository ?? TransactionRepository();

  Future<bool> importFromJSON() async {
    try {
      // Use FileType.any because some Android versions fail to filter .json correctly
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result.isEmpty || result.first.path == null) {
        return false;
      }

      final fileInfo = result.first;

      // Strict check for .json extension only
      if (!fileInfo.name.toLowerCase().endsWith('.json')) {
        AppLogger.warning('Selected file is not a JSON file: ${fileInfo.name}');
        return false;
      }

      final file = File(fileInfo.path!);
      final content = await file.readAsString();
      final List<dynamic> jsonList = json.decode(content);

      AppLogger.info('Importing ${jsonList.length} transactions from JSON...');

      final List<Transaction> transactionsToImport = [];
      for (final item in jsonList) {
        if (item is Map<String, dynamic>) {
          final title = item['title'] as String? ?? '';
          final amount = (item['amount'] as num?)?.toDouble() ?? 0.0;
          final dateStr = item['date'] as String?;
          final categoryName = item['category'] as String? ?? 'Others';
          final description = item['description'] as String?;

          if (dateStr == null) continue;
          final date = DateTime.tryParse(dateStr) ?? DateTime.now();

          // 1. Ensure category exists (this is still one by one, but usually categories are few)
          final categoryId = await _categoryRepository.ensureCategoryByName(
            categoryName,
          );

          // 2. Prepare transaction
          transactionsToImport.add(
            Transaction(
              title: title,
              amount: amount,
              date: date,
              categoryId: categoryId,
              description: description,
            ),
          );
        }
      }

      if (transactionsToImport.isNotEmpty) {
        await _transactionRepository.insertTransactionsBatch(
          transactionsToImport,
        );
      }

      AppLogger.info(
        'Import completed. Imported ${transactionsToImport.length} items.',
      );
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('JSON import failed', e, stackTrace);
      return false;
    }
  }
}
