import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../theme/app_shapes.dart';
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
    return spendings.fold(0, (sum, item) => sum + item.amount);
  }

  _TopCategory _getTopCategory(List<txmodel.Transaction> spendings) {
    if (spendings.isEmpty) {
      return _TopCategory(name: 'None', icon: null, color: null);
    }
    Map<int, double> categoryTotals = {};
    Map<int, txmodel.Transaction> sampleTransactions = {};
    for (var s in spendings) {
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

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Daily Summary'),
        backgroundColor: colorScheme.surfaceContainer,
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
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: AppShapes.smallRadius,
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
                hintStyle: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withAlpha(150),
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
          ? const Center(child: Text('No spending history found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredDates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final dateStr = _filteredDates[index];
                final spendings = _groupedSpendings[dateStr]!;
                final dailyTotal = _calculateDailyTotal(spendings);
                final date = DateTime.parse(dateStr);
                final isToday =
                    DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateStr;
                final topCat = _getTopCategory(spendings);

                return Card(
                  elevation: 0,
                  color: isToday
                      ? colorScheme.primaryContainer.withAlpha(50)
                      : null,
                  shape: AppShapes.mediumShape.copyWith(
                    side: BorderSide(
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isToday ? 1 : 0.5,
                    ),
                  ),
                  child: ListTile(
                    onTap: () async {
                      // Navigate to detail view
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryScreen(filterDate: dateStr),
                        ),
                      );
                      _loadSummary();
                    },
                    leading: CircleAvatar(
                      backgroundColor: isToday
                          ? colorScheme.primary
                          : colorScheme.secondaryContainer,
                      child: Text(
                        DateFormat('dd').format(date),
                        style: textTheme.labelLarge?.copyWith(
                          color: isToday
                              ? colorScheme.onPrimary
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      isToday
                          ? 'Today'
                          : DateFormat('EEEE, MMM dd').format(date),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          IconUtils.fromString(topCat.icon),
                          size: 14,
                          color: ColorUtils.fromInt(topCat.color),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${topCat.name} • ${spendings.length} items',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${dailyTotal.toStringAsFixed(2)}',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                );
              },
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
