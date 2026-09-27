import '../../constants/app_constants.dart';
import '../../utils/logger.dart';

class UnsupportedExportVersionException implements Exception {
  final int version;
  UnsupportedExportVersionException(this.version);

  @override
  String toString() =>
      'Unsupported backup version\nThis backup was created with a newer version of ExpendiNote. Please update the app to import this backup.';
}

class InvalidBackupFormatException implements Exception {
  final String message;
  InvalidBackupFormatException(this.message);

  @override
  String toString() => message;
}

class ExportMigrationService {
  static int get currentSupportedVersion =>
      ExportConstants.currentExportVersion;

  /// Takes decoded JSON object (List or Map) and migrates it to the latest Export Version 1 structure.
  /// Throws [UnsupportedExportVersionException] if export_version > currentSupportedVersion.
  /// Throws [InvalidBackupFormatException] if structure is invalid.
  static Map<String, dynamic> migrateToLatest(dynamic rawJson) {
    if (rawJson == null) {
      throw InvalidBackupFormatException(
        'Backup file is empty or invalid JSON.',
      );
    }

    // Case 1: Legacy Flat JSON Array [...]
    if (rawJson is List) {
      AppLogger.info(
        'Detected legacy flat JSON array. Migrating to Export Version 1...',
      );
      return _migrateLegacyFlatListToV1(rawJson);
    }

    // Case 2: JSON Map
    if (rawJson is Map) {
      final map = Map<String, dynamic>.from(rawJson);

      // Check export_version if present
      final rawVersion = map['export_version'];
      if (rawVersion != null) {
        final version = (rawVersion is int)
            ? rawVersion
            : int.tryParse(rawVersion.toString()) ?? 0;

        if (version > currentSupportedVersion) {
          AppLogger.warning(
            'Backup export_version $version is higher than supported version $currentSupportedVersion',
          );
          throw UnsupportedExportVersionException(version);
        }

        if (version == 1) {
          return map;
        }
      }

      // If version is missing or 0: check if it's an unversioned map (e.g. {"transactions": [...]})
      if (map.containsKey('transactions') ||
          map.containsKey('spendings') ||
          map.containsKey('data')) {
        AppLogger.info(
          'Detected unversioned JSON map. Migrating to Export Version 1...',
        );
        return _migrateUnversionedMapToV1(map);
      }

      throw InvalidBackupFormatException('Unrecognized backup JSON format.');
    }

    throw InvalidBackupFormatException('Invalid backup data format.');
  }

  /// Converts legacy flat JSON list into Export Version 1 backup structure.
  static Map<String, dynamic> _migrateLegacyFlatListToV1(List rawList) {
    final transactions = <Map<String, dynamic>>[];
    final categoryNamesSeen = <String>{};
    final categoryList = <Map<String, dynamic>>[];

    int nextCatId = 1;

    for (final item in rawList) {
      if (item is Map) {
        final itemMap = Map<String, dynamic>.from(item);
        final rawCatName = (itemMap['category'] as String? ?? 'Others').trim();
        final catNameClean = rawCatName.isEmpty ? 'Others' : rawCatName;
        final catKey = catNameClean.toLowerCase();

        if (!categoryNamesSeen.contains(catKey)) {
          categoryNamesSeen.add(catKey);
          final isInvestment = catKey == 'investment';
          categoryList.add({
            'id': nextCatId,
            'name': catNameClean,
            'icon': null,
            'color': null,
            'is_pinned': false,
            'is_archived': false,
            'include_in_spending_analysis': isInvestment ? false : true,
            'created_at': DateTime.now().toIso8601String(),
          });
          nextCatId++;
        }

        final catId =
            categoryList.firstWhere(
                  (c) => (c['name'] as String).toLowerCase() == catKey,
                )['id']
                as int;

        final title = (itemMap['title'] as String? ?? '').trim();
        final rawAmount = itemMap['amount'];
        final amount = (rawAmount is num)
            ? rawAmount.toDouble()
            : double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;

        final dateStr =
            itemMap['date'] as String? ?? DateTime.now().toIso8601String();
        final description = itemMap['description'] as String?;

        final rawInclude =
            itemMap['includeInSpendingAnalysis'] ??
            itemMap['include_in_spending_analysis'];
        final bool includeInSpendingAnalysis = rawInclude is bool
            ? rawInclude
            : (rawInclude is num ? rawInclude == 1 : true);

        transactions.add({
          if (itemMap['id'] != null) 'id': itemMap['id'],
          'title': title,
          'amount': amount,
          'date': dateStr,
          'category_id': catId,
          'category_name': catNameClean,
          'description': description,
          'include_in_spending_analysis': includeInSpendingAnalysis,
          'created_at': itemMap['createdAt'] as String? ?? dateStr,
        });
      }
    }

    return {
      'format': ExportConstants.backupFormatName,
      'export_version': 1,
      'app_version': AppConstants.appVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'data': {
        'categories': categoryList,
        'transactions': transactions,
        'settings': [],
      },
    };
  }

  /// Migrates unversioned map into Export Version 1 format.
  static Map<String, dynamic> _migrateUnversionedMapToV1(
    Map<String, dynamic> map,
  ) {
    dynamic dataObj = map['data'] ?? map;
    List rawTransactions = [];
    List rawCategories = [];
    List rawSettings = [];

    if (dataObj is Map) {
      rawTransactions =
          (dataObj['transactions'] ?? dataObj['spendings']) as List? ?? [];
      rawCategories = dataObj['categories'] as List? ?? [];
      rawSettings = dataObj['settings'] as List? ?? [];
    }

    if (rawCategories.isEmpty && rawTransactions.isNotEmpty) {
      return _migrateLegacyFlatListToV1(rawTransactions);
    }

    return {
      'format': ExportConstants.backupFormatName,
      'export_version': 1,
      'app_version': AppConstants.appVersion,
      'exported_at':
          map['exported_at'] as String? ?? DateTime.now().toIso8601String(),
      'data': {
        'categories': rawCategories,
        'transactions': rawTransactions,
        'settings': rawSettings,
      },
    };
  }

  /// Validates the structure of Export Version 1 backup map.
  /// Returns null if valid, or an error message string if invalid.
  static String? validateBackupData(Map<String, dynamic> backupMap) {
    if (!backupMap.containsKey('data') || backupMap['data'] is! Map) {
      return 'Missing or invalid "data" field in backup.';
    }

    final data = Map<String, dynamic>.from(backupMap['data'] as Map);

    final rawCategories = data['categories'];
    if (rawCategories != null && rawCategories is! List) {
      return '"categories" must be a list.';
    }

    final rawTransactions = data['transactions'];
    if (rawTransactions != null && rawTransactions is! List) {
      return '"transactions" must be a list.';
    }

    final rawSettings = data['settings'];
    if (rawSettings != null && rawSettings is! List) {
      return '"settings" must be a list.';
    }

    // Validate categories items
    if (rawCategories is List) {
      for (var i = 0; i < rawCategories.length; i++) {
        final cat = rawCategories[i];
        if (cat is! Map) {
          return 'Category at index $i is not a valid object.';
        }
        final name = cat['name'];
        if (name == null || name.toString().trim().isEmpty) {
          return 'Category at index $i is missing a name.';
        }
      }
    }

    // Validate transactions items
    if (rawTransactions is List) {
      for (var i = 0; i < rawTransactions.length; i++) {
        final tx = rawTransactions[i];
        if (tx is! Map) {
          return 'Transaction at index $i is not a valid object.';
        }
        final title = tx['title'];
        if (title == null) {
          return 'Transaction at index $i is missing a title.';
        }
        final rawAmount = tx['amount'];
        if (rawAmount == null) {
          return 'Transaction at index $i is missing an amount.';
        }
        if (rawAmount is! num &&
            double.tryParse(rawAmount.toString()) == null) {
          return 'Transaction at index $i has an invalid amount value.';
        }
        final dateStr = tx['date'];
        if (dateStr == null || DateTime.tryParse(dateStr.toString()) == null) {
          return 'Transaction at index $i has an invalid or missing date.';
        }
      }
    }

    return null; // Valid!
  }
}
