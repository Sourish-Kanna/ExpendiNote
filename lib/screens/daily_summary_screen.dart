import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'history_screen.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  Map<String, List<txmodel.Transaction>> _groupedSpendings = {};
  List<String> _sortedDates = [];
  List<String> _filteredDates = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSummary();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final allSpendings = await TransactionRepository.getAllTransactions();

    Map<String, List<txmodel.Transaction>> grouped = {};
    for (var s in allSpendings) {
      final dateStr = DateFormat('yyyy-MM-dd').format(s.date);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(s);
    }

    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    if (!mounted) return;
    setState(() {
      _groupedSpendings = grouped;
      _sortedDates = sorted;
      _filteredDates = sorted;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredDates = _sortedDates;
      } else {
        _filteredDates = _sortedDates.where((dateStr) {
          final spendings = _groupedSpendings[dateStr]!;
          return spendings.any((s) => s.title.toLowerCase().contains(query));
        }).toList();
      }
    });
  }

  double _calculateDailyTotal(List<txmodel.Transaction> spendings) {
    return spendings
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  _TopCategory _getTopCategory(List<txmodel.Transaction> spendings) {
    final included = spendings
        .where((s) => s.includeInSpendingAnalysis)
        .toList();
    if (included.isEmpty) {
      return _TopCategory(name: 'None', icon: null, color: null);
    }
    Map<int, double> categoryTotals = {};
    Map<int, txmodel.Transaction> sampleTransactions = {};
    for (var s in included) {
      final id = s.categoryId ?? -1;
      categoryTotals[id] = (categoryTotals[id] ?? 0) + s.amount;
      sampleTransactions[id] = s;
    }
    final topId = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final sample = sampleTransactions[topId]!;
    return _TopCategory(
      name: sample.categoryName ?? 'Other',
      icon: sample.categoryIcon,
      color: sample.categoryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalDailySpend = _groupedSpendings.values
        .expand((list) => list)
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Daily Summary',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 64,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No spending history found.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSummary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredDates.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Card(
                        elevation: 0,
                        color: colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 16,
                          ),
                          child: IntrinsicHeight(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Total Analyzed',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${totalDailySpend.toStringAsFixed(2)}',
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                VerticalDivider(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  thickness: 2,
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      Text(
                                        'Active Days',
                                        style: textTheme.labelLarge?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_sortedDates.length}',
                                        style: textTheme.headlineMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final dateStr = _filteredDates[index - 1];
                  final spendings = _groupedSpendings[dateStr]!;
                  final dailyTotal = _calculateDailyTotal(spendings);
                  final date = DateTime.parse(dateStr);
                  final isToday =
                      DateFormat('yyyy-MM-dd').format(DateTime.now()) ==
                      dateStr;
                  final topCat = _getTopCategory(spendings);

                  final catColor = topCat.color != null
                      ? ColorUtils.fromInt(topCat.color)
                      : colorScheme.primary;
                  final catIcon = IconUtils.fromString(topCat.icon);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 0,
                      color: isToday
                          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                          : catColor.withValues(alpha: 0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isToday
                            ? BorderSide(color: colorScheme.primary, width: 1.5)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  HistoryScreen(filterDate: dateStr),
                            ),
                          );
                          _loadSummary();
                        },
                        leading: Icon(catIcon, color: catColor, size: 24),
                        title: Text(
                          isToday
                              ? 'Today • ${DateFormat('MMM dd').format(date)}'
                              : DateFormat('EEEE, MMM dd').format(date),
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          '${topCat.name} • ${spendings.length} ${spendings.length == 1 ? 'item' : 'items'}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${dailyTotal.toStringAsFixed(2)}',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isToday
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.chevron_right, size: 20),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _TopCategory {
  final String name;
  final String? icon;
  final int? color;

  _TopCategory({required this.name, this.icon, this.color});
}
