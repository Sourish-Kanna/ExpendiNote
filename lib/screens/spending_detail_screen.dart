import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

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

              // Correct guard for State.context inside a StatefulWidget
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Details'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSpendingScreen(transaction: _currentSpending),
                ),
              );
              if (result == true) {
                // Refresh data
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
            icon: const Icon(Icons.delete_outline),
            color: colorScheme.error,
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: ColorUtils.fromInt(
                      _currentSpending.categoryColor,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      IconUtils.fromString(_currentSpending.categoryIcon),
                      size: 40,
                      color: ColorUtils.fromInt(_currentSpending.categoryColor),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '₹${_currentSpending.amount.toStringAsFixed(2)}',
                    style: textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentSpending.title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildDetailRow(
              context,
              Icons.category_outlined,
              'Category',
              _currentSpending.categoryName ?? 'Other',
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              Icons.calendar_today_outlined,
              'Date',
              DateFormat('EEEE, MMM dd, yyyy').format(_currentSpending.date),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              Icons.access_time,
              'Time',
              DateFormat('hh:mm a').format(_currentSpending.date),
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              Icons.analytics_outlined,
              'Spending Analysis',
              _currentSpending.includeInSpendingAnalysis
                  ? 'Included'
                  : 'Excluded',
            ),
            if (_currentSpending.description != null &&
                _currentSpending.description!.isNotEmpty) ...[
              const Divider(height: 32),
              _buildDetailRow(
                context,
                Icons.description_outlined,
                'Description',
                _currentSpending.description!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colorScheme.primary, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
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
