import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import 'history_screen.dart';

class CategorySummaryScreen extends StatefulWidget {
  const CategorySummaryScreen({super.key});

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  Map<String, double> _categoryTotals = {};
  double _grandTotal = 0;
  bool _isLoading = true;
  String _selectedPeriod = 'This Month';

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  Future<void> _loadCategoryData() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> rawDataMaps = await TransactionRepository()
        .getAllWithCategoryName();

    final allSpendings = rawDataMaps
        .map((m) => txmodel.Transaction.fromMap(m))
        .toList();

    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);

    List<txmodel.Transaction> filtered;
    if (_selectedPeriod == 'This Month') {
      filtered = allSpendings
          .where((s) => DateFormat('yyyy-MM').format(s.date) == monthStr)
          .toList();
    } else {
      filtered = allSpendings;
    }

    Map<String, double> totals = {};
    double grand = 0;
    for (var s in filtered) {
      totals[s.category] = (totals[s.category] ?? 0) + s.amount;
      grand += s.amount;
    }

    // Sort categories by amount descending
    final sortedTotals = Map.fromEntries(
      totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );

    setState(() {
      _categoryTotals = sortedTotals;
      _grandTotal = grand;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Category Spending'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'This Month',
                        label: Text('This Month'),
                        icon: Icon(Icons.calendar_month),
                      ),
                      ButtonSegment(
                        value: 'All Time',
                        label: Text('All Time'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                    ],
                    selected: {_selectedPeriod},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        _selectedPeriod = newSelection.first;
                      });
                      _loadCategoryData();
                    },
                  ),
                ),
                _categoryTotals.isEmpty
                    ? const Expanded(
                        child: Center(child: Text('No data for this period.')),
                      )
                    : Expanded(
                        child: Column(
                          children: [
                            _buildOverviewCard(colorScheme),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _categoryTotals.length,
                                itemBuilder: (context, index) {
                                  final entry = _categoryTotals.entries
                                      .elementAt(index);
                                  final percentage = _grandTotal > 0
                                      ? (entry.value / _grandTotal) * 100
                                      : 0.0;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: InkWell(
                                      onTap: () async {
                                        final now = DateTime.now();
                                        final filterMonth =
                                            _selectedPeriod == 'This Month'
                                            ? DateFormat('MMM yyyy').format(now)
                                            : null;

                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => HistoryScreen(
                                              filterCategory: entry.key,
                                              filterMonth: filterMonth,
                                            ),
                                          ),
                                        );
                                        _loadCategoryData();
                                      },
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  backgroundColor: colorScheme
                                                      .secondaryContainer,
                                                  child: Icon(
                                                    _getCategoryIcon(entry.key),
                                                    color: colorScheme
                                                        .onSecondaryContainer,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        entry.key,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${percentage.toStringAsFixed(1)}% of total',
                                                        style: Theme.of(
                                                          context,
                                                        ).textTheme.bodySmall,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Text(
                                                  '₹${entry.value.toStringAsFixed(0)}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: colorScheme.primary,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  size: 16,
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            LinearProgressIndicator(
                                              value: percentage / 100,
                                              backgroundColor: colorScheme
                                                  .surfaceContainerHighest,
                                              color: colorScheme.primary,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _buildOverviewCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            'Total Spending ($_selectedPeriod)',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${_grandTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Health':
        return Icons.medical_services;
      case 'Other':
        return Icons.more_horiz;
      default:
        return Icons.receipt;
    }
  }
}
