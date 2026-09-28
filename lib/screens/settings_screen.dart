import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../main.dart';
import '../repositories/transaction_repository.dart';
import '../services/backup_service.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../theme/app_colors.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeScope.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeName(themeController.themeMode)),
                  onTap: () => _showThemeModeDialog(context, themeController),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.palette),
                  title: const Text('Use Custom Theme'),
                  subtitle: const Text('Override system or dynamic colors'),
                  value: themeController.customThemeEnabled,
                  onChanged: (value) =>
                      themeController.setCustomThemeEnabled(value),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, 'Theme Color'),
          Opacity(
            opacity: themeController.customThemeEnabled ? 1.0 : 0.5,
            child: Card(
              elevation: 0,
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: AbsorbPointer(
                absorbing: !themeController.customThemeEnabled,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: AppThemeColor.values.map((themeColor) {
                          final isSelected =
                              themeController.selectedThemeColor == themeColor;
                          return InkWell(
                            onTap: () => themeController.setSelectedThemeColor(
                              themeColor,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: themeColor.seed,
                                radius: 22,
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color:
                                            themeColor.seed.computeLuminance() >
                                                0.5
                                            ? Colors.black
                                            : Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (!themeController.customThemeEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            'Enable "Use Custom Theme" to change color',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.outline,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(context, 'Preferences'),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Categories'),
              subtitle: const Text('Manage your spending categories'),
              trailing: const Icon(Icons.chevron_right),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CategoryManagementScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(context, 'Data Management'),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Create and share a JSON backup file'),
                  onTap: () => _backupData(context),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore data from a JSON backup file'),
                  onTap: () => _restoreData(context),
                ),
                Divider(
                  height: 1,
                  indent: 56,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text('Export CSV'),
                  subtitle: const Text('Export transactions to CSV file'),
                  onTap: () => _exportCSV(context),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _buildSectionHeader(context, 'About'),
          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: ListTile(
              leading: const Icon(Icons.info),
              title: const Text('ExpendiNote'),
              subtitle: FutureBuilder<String>(
                future: AppConstants.getAppVersion(),
                builder: (context, snapshot) {
                  final version = snapshot.data ?? AppConstants.appVersion;
                  return Text('Version $version');
                },
              ),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final result = await BackupService().createBackupFile();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup created successfully\nSaved to ${result.displayPath}',
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(result.file.path)],
                  subject: 'ExpendiNote Backup',
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    final importService = ImportService();
    final existingCount = await importService.getCurrentTransactionCount();

    if (!context.mounted) return;

    RestoreMode mode = RestoreMode.replaceExistingTransactions;

    if (existingCount > 0) {
      final formattedCount = NumberFormat('#,##0').format(existingCount);
      final selectedMode = await showDialog<RestoreMode>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Existing Transactions Found'),
          content: Text(
            'You currently have \${formattedCount} transactions. Choose how to restore the backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, RestoreMode.merge),
              child: const Text('Merge'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                RestoreMode.replaceExistingTransactions,
              ),
              child: const Text('Remove & Restore'),
            ),
          ],
        ),
      );

      if (selectedMode == null || !context.mounted) return;
      mode = selectedMode;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Data?'),
          content: const Text(
            'Your backup will be restored while keeping ExpendiNote default categories.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true || !context.mounted) return;
    }

    final restoreResult = await importService.restoreFromJSON(mode: mode);

    if (!context.mounted || restoreResult.isCancelled) return;

    if (restoreResult.isSuccess) {
      final formattedCount = NumberFormat(
        '#,##0',
      ).format(restoreResult.transactionsRestored);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Backup Restored Successfully'),
          content: Text(
            '\${formattedCount} \${restoreResult.transactionsRestored == 1 ? "transaction" : "transactions"} imported.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else if (restoreResult.isUnsupportedVersion) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsupported backup version'),
          content: const Text(
            'This backup was created with a newer version of ExpendiNote. Please update the app to import this backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore Failed'),
          content: Text(
            restoreResult.errorMessage ?? 'An unknown error occurred.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _exportCSV(BuildContext context) async {
    final data = await TransactionRepository.getAllTransactions();

    if (data.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final result = await ExportService().exportToCSV(data);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV exported successfully\nSaved to ${result.displayPath}',
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  files: [XFile(result.file.path)],
                  subject: 'Transactions Export',
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('CSV export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void _showThemeModeDialog(BuildContext context, dynamic controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Theme Mode'),
        content: RadioGroup<ThemeMode>(
          groupValue: controller.themeMode,
          onChanged: (value) {
            if (value != null) {
              controller.setThemeMode(value);
              Navigator.pop(context);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(_getThemeModeName(mode)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
