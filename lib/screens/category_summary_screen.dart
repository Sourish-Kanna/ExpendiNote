import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'history_screen.dart';

class CategorySummaryScreen extends StatefulWidget {
  const CategorySummaryScreen({super.key});

  @override
  State<CategorySummaryScreen> createState() => _CategorySummaryScreenState();
}

class _CategorySummaryScreenState extends State<CategorySummaryScreen> {
  Map<int, _CategoryGroup> _categoryGroups = {};
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

    Map<int, _CategoryGroup> groups = {};
    double grand = 0;
    for (var s in filtered) {
      final id = s.categoryId ?? -1;
      if (!groups.containsKey(id)) {
        groups[id] = _CategoryGroup(
          name: s.categoryName ?? 'Other',
          icon: s.categoryIcon,
          color: s.categoryColor,
          total: 0,
        );
      }
      groups[id]!.total += s.amount;
      grand += s.amount;
    }

    // Sort categories by amount descending
    final sortedGroups = Map.fromEntries(
      groups.entries.toList()..sort((a, b) => b.value.total.compareTo(a.value.total)),
    );

    setState(() {
      _categoryGroups = sortedGroups;
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
                _categoryGroups.isEmpty
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
                                itemCount: _categoryGroups.length,
                                itemBuilder: (context, index) {
                                  final entry = _categoryGroups.entries
                                      .elementAt(index);
                                  final group = entry.value;
                                  final percentage = _grandTotal > 0
                                      ? (group.total / _grandTotal) * 100
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
                                              filterCategory: group.name,
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
                                                  backgroundColor: ColorUtils.fromInt(group.color)
                                                      .withValues(alpha: 0.2),
                                                  child: Icon(
                                                    IconUtils.fromString(group.icon),
                                                    color: ColorUtils.fromInt(group.color),
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
                                                        group.name,
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
                                                  '₹${group.total.toStringAsFixed(0)}',
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
}

class _CategoryGroup {
  final String name;
  final String? icon;
  final int? color;
  double total;

  _CategoryGroup({
    required this.name,
    this.icon,
    this.color,
    required this.total,
  });
}
