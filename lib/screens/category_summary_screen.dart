import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import '../widgets/summary_card.dart';
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
    final allSpendings = await TransactionRepository.getAllTransactions();

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
      groups.entries.toList()
        ..sort((a, b) => b.value.total.compareTo(a.value.total)),
    );

    if (!mounted) return;
    setState(() {
      _categoryGroups = sortedGroups;
      _grandTotal = grand;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Category Spending',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
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
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: SummaryCard(
                                items: [
                                  MetricItem(
                                    label: 'Total Spending ($_selectedPeriod)',
                                    value: '₹${_grandTotal.toStringAsFixed(0)}',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                itemCount: _categoryGroups.length,
                                itemBuilder: (context, index) {
                                  final entry = _categoryGroups.entries
                                      .elementAt(index);
                                  final group = entry.value;
                                  final percentage = _grandTotal > 0
                                      ? (group.total / _grandTotal) * 100
                                      : 0.0;
                                  final catColor = ColorUtils.fromInt(
                                    group.color,
                                  );
                                  final catIcon = IconUtils.fromString(
                                    group.icon,
                                  );

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Card(
                                      elevation: 0,
                                      color: catColor.withValues(alpha: 0.12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: InkWell(
                                        onTap: () async {
                                          final now = DateTime.now();
                                          final filterMonth =
                                              _selectedPeriod == 'This Month'
                                              ? DateFormat(
                                                  'MMM yyyy',
                                                ).format(now)
                                              : null;

                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  HistoryScreen(
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
                                                  Icon(
                                                    catIcon,
                                                    color: catColor,
                                                    size: 24,
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
                                                          style: textTheme
                                                              .titleMedium
                                                              ?.copyWith(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: colorScheme
                                                                    .onSurface,
                                                              ),
                                                        ),
                                                        Text(
                                                          '${percentage.toStringAsFixed(1)}% of total',
                                                          style: textTheme
                                                              .bodySmall
                                                              ?.copyWith(
                                                                color: colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                    '₹${group.total.toStringAsFixed(0)}',
                                                    style: textTheme.titleMedium
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: colorScheme
                                                              .onSurface,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons.chevron_right,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              LinearProgressIndicator(
                                                value: percentage / 100,
                                                backgroundColor: catColor
                                                    .withValues(alpha: 0.2),
                                                color: catColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ],
                                          ),
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
