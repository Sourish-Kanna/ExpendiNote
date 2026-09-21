import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'add_spending_screen.dart';

class SpendingDetailScreen extends StatefulWidget {
  final txmodel.Transaction transaction;
  const SpendingDetailScreen({super.key, required this.transaction});

  @override
  State<SpendingDetailScreen> createState() => _SpendingDetailScreenState();
}

class _SpendingDetailScreenState extends State<SpendingDetailScreen> {
  late txmodel.Transaction _currentSpending;

  @override
  void initState() {
    super.initState();
    _currentSpending = widget.transaction;
  }

  void _confirmDelete() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Spending?'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              await TransactionRepository.deleteTransaction(
                _currentSpending.id!,
              );

              if (mounted) {
                Navigator.pop(context, true);
              }
            },
            child: Text(
              'Delete',
              style: textTheme.labelLarge?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final catColor = ColorUtils.fromInt(_currentSpending.categoryColor);
    final catIcon = IconUtils.fromString(_currentSpending.categoryIcon);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Details',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSpendingScreen(transaction: _currentSpending),
                ),
              );
              if (result == true) {
                final updated = await TransactionRepository.getById(
                  _currentSpending.id!,
                );
                if (updated != null) {
                  setState(() => _currentSpending = updated);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            color: colorScheme.error,
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Primary Amount Card (Matches Home/Add Spending layout but using Category Color matching theme)
            Card(
              elevation: 0,
              color: catColor.withValues(alpha: 0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                child: Column(
                  children: [
                    Text(
                      _currentSpending.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: catColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.currency_rupee, size: 38, color: catColor),
                        Text(
                          _currentSpending.amount.toStringAsFixed(2),
                          style: textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Info Grid / Section Container
            Card(
              elevation: 0,
              color: catColor.withValues(alpha: 0.05),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Category row matching standard plain row layout
                    _buildDetailItem(
                      context: context,
                      icon: catIcon,
                      label: 'Category',
                      value: _currentSpending.categoryName ?? 'Other',
                    ),
                    Divider(
                      height: 32,
                      thickness: 1,
                      color: catColor.withValues(alpha: 0.15),
                    ),

                    // Date row
                    _buildDetailItem(
                      context: context,
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat(
                        'EEEE, MMM dd, yyyy',
                      ).format(_currentSpending.date),
                    ),
                    Divider(
                      height: 32,
                      thickness: 1,
                      color: catColor.withValues(alpha: 0.15),
                    ),

                    // Time row
                    _buildDetailItem(
                      context: context,
                      icon: Icons.access_time,
                      label: 'Time',
                      value: DateFormat(
                        'hh:mm a',
                      ).format(_currentSpending.date),
                    ),
                    Divider(
                      height: 32,
                      thickness: 1,
                      color: catColor.withValues(alpha: 0.15),
                    ),

                    // Spending Analysis row matching standard plain row layout
                    _buildDetailItem(
                      context: context,
                      icon: Icons.analytics,
                      label: 'Spending Analysis',
                      value: _currentSpending.includeInSpendingAnalysis
                          ? 'Included'
                          : 'Excluded',
                    ),

                    // Optional Description block
                    if (_currentSpending.description != null &&
                        _currentSpending.description!.trim().isNotEmpty) ...[
                      Divider(
                        height: 32,
                        thickness: 1,
                        color: catColor.withValues(alpha: 0.15),
                      ),
                      _buildDetailItem(
                        context: context,
                        icon: Icons.description,
                        label: 'Description',
                        value: _currentSpending.description!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    String? value,
    Widget? customValueWidget,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final catColor = ColorUtils.fromInt(_currentSpending.categoryColor);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: catColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: catColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: catColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (customValueWidget != null)
                customValueWidget
              else
                Text(
                  value ?? '',
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
