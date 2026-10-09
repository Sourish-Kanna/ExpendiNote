import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../widgets/summary_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/transaction_options_bottom_sheet.dart';
import 'add_spending_screen.dart';
import 'spending_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String? filterDate; // yyyy-MM-dd
  final String? filterCategory;
  final String? filterMonth; // MMM yyyy

  const HistoryScreen({
    super.key,
    this.filterDate,
    this.filterCategory,
    this.filterMonth,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, List<txmodel.Transaction>> _groupedSpendings = {};
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final allSpendings = await TransactionRepository.getAllTransactions();

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    Map<String, List<txmodel.Transaction>> grouped = {};
    for (var s in allSpendings) {
      final dateStr = DateFormat('yyyy-MM-dd').format(s.date);
      final monthStr = DateFormat('MMM yyyy').format(s.date);

      // Filtering logic
      if (widget.filterDate != null && dateStr != widget.filterDate) continue;
      if (widget.filterCategory != null &&
          s.categoryName != widget.filterCategory) {
        continue;
      }
      if (widget.filterMonth != null && monthStr != widget.filterMonth) {
        continue;
      }

      // If no filter, skip today (standard history view)
      if (widget.filterDate == null &&
          widget.filterCategory == null &&
          widget.filterMonth == null &&
          dateStr == todayStr) {
        continue;
      }

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(s);
    }

    if (!mounted) return;
    setState(() {
      _groupedSpendings = grouped;
      _isLoading = false;
    });
  }

  void _deleteSpending(int id) async {
    await TransactionRepository.deleteTransaction(id);
    _hasChanged = true;
    _loadHistory();
  }

  void _confirmDelete(txmodel.Transaction spending) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Spending?'),
        content: const Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteSpending(spending.id!);
              Navigator.pop(context);
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

  double _calculateDailyTotal(List<txmodel.Transaction> spendings) {
    return spendings
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final sortedDates = _groupedSpendings.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final totalFilteredAmount = sortedDates
        .expand((d) => _groupedSpendings[d]!)
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);
    final totalEntriesCount = sortedDates
        .expand((d) => _groupedSpendings[d]!)
        .length;

    String title = 'Spending History';
    if (widget.filterDate != null) {
      title = DateFormat(
        'EEEE, MMM dd',
      ).format(DateTime.parse(widget.filterDate!));
    } else if (widget.filterCategory != null) {
      title = widget.filterCategory!;
    } else if (widget.filterMonth != null) {
      title = widget.filterMonth!;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          title,
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedDates.isEmpty
          ? const Center(child: Text('No entries found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SummaryCard(
                      items: [
                        MetricItem(
                          label: 'Filtered Spending',
                          value: '₹${totalFilteredAmount.toStringAsFixed(2)}',
                        ),
                        MetricItem(
                          label: 'Total Entries',
                          value: '$totalEntriesCount',
                        ),
                      ],
                    ),
                  );
                }

                final dateStr = sortedDates[index - 1];
                final spendings = _groupedSpendings[dateStr]!;
                final dailyTotal = _calculateDailyTotal(spendings);
                final date = DateTime.parse(dateStr);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMM dd').format(date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total: ₹${dailyTotal.toStringAsFixed(2)}',
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...spendings.map((s) {
                      return TransactionCard(
                        transaction: s,
                        subtitle:
                            s.description != null && s.description!.isNotEmpty
                            ? s.description
                            : s.categoryName ?? 'Other',
                        amountText: '₹${s.amount.toStringAsFixed(2)}',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SpendingDetailScreen(transaction: s),
                            ),
                          );
                          if (result == true) {
                            _hasChanged = true;
                            _loadHistory();
                          }
                        },
                        onLongPress: () async {
                          final navigator = Navigator.of(context);
                          final action =
                              await showTransactionOptionsBottomSheet(
                                context: context,
                                transaction: s,
                              );
                          if (!mounted || action == null) return;
                          if (action == TransactionOption.edit) {
                            final result = await navigator.push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddSpendingScreen(transaction: s),
                              ),
                            );
                            if (result == true) {
                              _hasChanged = true;
                              _loadHistory();
                            }
                          } else if (action == TransactionOption.delete) {
                            _confirmDelete(s);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
    );
  }
}
