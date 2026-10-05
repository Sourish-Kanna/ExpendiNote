import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../widgets/summary_card.dart';
import 'history_screen.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  Map<String, List<txmodel.Transaction>> _monthlySpendings = {};
  List<String> _sortedMonths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary();
  }

  Future<void> _loadMonthlySummary() async {
    setState(() => _isLoading = true);
    final allSpendings = await TransactionRepository.getAllTransactions();

    Map<String, List<txmodel.Transaction>> grouped = {};
    for (var s in allSpendings) {
      final monthStr = DateFormat('yyyy-MM').format(s.date);
      if (!grouped.containsKey(monthStr)) {
        grouped[monthStr] = [];
      }
      grouped[monthStr]!.add(s);
    }

    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (!mounted) return;
    setState(() {
      _monthlySpendings = grouped;
      _sortedMonths = sorted;
      _isLoading = false;
    });
  }

  double _calculateMonthlyTotal(List<txmodel.Transaction> spendings) {
    return spendings
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final grandTotal = _monthlySpendings.values
        .expand((list) => list)
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Monthly Summary',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sortedMonths.isEmpty
          ? const Center(child: Text('No spending history found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sortedMonths.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SummaryCard(
                      items: [
                        MetricItem(
                          label: 'Total Analyzed',
                          value: '₹${grandTotal.toStringAsFixed(0)}',
                        ),
                        MetricItem(
                          label: 'Months Count',
                          value: '${_sortedMonths.length}',
                        ),
                      ],
                    ),
                  );
                }

                final monthStr = _sortedMonths[index - 1];
                final spendings = _monthlySpendings[monthStr]!;
                final monthlyTotal = _calculateMonthlyTotal(spendings);
                final date = DateTime.parse('$monthStr-01');
                final filterMonthStr = DateFormat('MMM yyyy').format(date);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Icon(
                        Icons.calendar_month,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      title: Text(
                        DateFormat('MMMM yyyy').format(date),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${spendings.length} entries',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '₹${monthlyTotal.toStringAsFixed(0)}',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                HistoryScreen(filterMonth: filterMonthStr),
                          ),
                        );
                        _loadMonthlySummary();
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
