import 'package:flutter/material.dart';

import '../main.dart';
import '../repositories/transaction_repository.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../theme/app_colors.dart';
import 'category_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = AppThemeScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, 'Appearance'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_medium),
                  title: const Text('Theme Mode'),
                  subtitle: Text(_getThemeModeName(themeController.themeMode)),
                  onTap: () => _showThemeModeDialog(context, themeController),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.palette_outlined),
                  title: const Text('Use Custom Theme'),
                  subtitle: const Text('Override system or dynamic colors'),
                  value: themeController.customThemeEnabled,
                  onChanged: (value) =>
                      themeController.setCustomThemeEnabled(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionHeader(context, 'Theme Color'),
          Opacity(
            opacity: themeController.customThemeEnabled ? 1.0 : 0.5,
            child: Card(
              child: AbsorbPointer(
                absorbing: !themeController.customThemeEnabled,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: AppThemeColor.values.map((themeColor) {
                          final isSelected =
                              themeController.selectedThemeColor == themeColor;
                          return InkWell(
                            onTap: () => themeController.setSelectedThemeColor(
                              themeColor,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
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
                                radius: 20,
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (!themeController.customThemeEnabled)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Enable "Use Custom Theme" to change color',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Preferences'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              subtitle: const Text('Manage your spending categories'),
              trailing: const Icon(Icons.chevron_right),
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
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Data Management'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.ios_share_outlined),
                  title: const Text('Export Data'),
                  subtitle: const Text('Export transactions to CSV'),
                  onTap: () => _exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.file_download_outlined),
                  title: const Text('Import Data'),
                  subtitle: const Text('Import transactions from JSON'),
                  onTap: () => _importData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'About'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('ExpendiNote'),
              subtitle: Text('Version 2.0.0'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final data = await TransactionRepository.getAllTransactions();

    if (data.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No data to export')));
      }
      return;
    }

    await ExportService().exportToCSV(data);
  }

  Future<void> _importData(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );

    final success = await ImportService().importFromJSON();

    if (!context.mounted) return;
    Navigator.pop(context); // Close loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Data imported successfully' : 'Import failed or cancelled',
        ),
      ),
    );
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
