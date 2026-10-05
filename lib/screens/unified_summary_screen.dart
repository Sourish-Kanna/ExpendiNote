import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../services/export_service.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'category_summary_screen.dart';
import 'daily_summary_screen.dart';
import 'history_screen.dart';
import 'monthly_summary_screen.dart';

class UnifiedSummaryScreen extends StatefulWidget {
  final ValueNotifier<int> refreshNotifier;
  const UnifiedSummaryScreen({super.key, required this.refreshNotifier});

  @override
  State<UnifiedSummaryScreen> createState() => _UnifiedSummaryScreenState();
}

class _UnifiedSummaryScreenState extends State<UnifiedSummaryScreen> {
  List<txmodel.Transaction> _allSpendings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.refreshNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await TransactionRepository.getAllTransactions();
    if (!mounted) return;
    setState(() {
      _allSpendings = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final totalAnalysisSpending = _allSpendings
        .where((s) => s.includeInSpendingAnalysis)
        .fold(0.0, (sum, item) => sum + item.amount);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Analysis',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              if (_allSpendings.isEmpty) {
                messenger.showSnackBar(
                  const SnackBar(content: Text('No data to export')),
                );
                return;
              }
              try {
                final result = await ExportService().exportToCSV(_allSpendings);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'CSV exported successfully\nSaved to ${result.displayPath}',
                    ),
                    duration: const Duration(seconds: 6),
                    behavior: SnackBarBehavior.floating,
                    action: SnackBarAction(
                      label: 'Share',
                      onPressed: () {
                        SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(result.file.path)],
                            subject: 'Transactions Export',
                          ),
                        );
                      },
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('CSV export failed: $e'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                children: [
                  // Overview Primary Metric Card
                  Card(
                    elevation: 0,
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Total Spending',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${totalAnalysisSpending.toStringAsFixed(2)}',
                                    style: textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            VerticalDivider(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              thickness: 2,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Total Entries',
                                    style: textTheme.labelLarge?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_allSpendings.length}',
                                    style: textTheme.headlineMedium?.copyWith(
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
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, 'Categories', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategorySummaryScreen(),
                      ),
                    );
                    _loadData();
                  }),
                  _buildCategoryOverview(colorScheme, textTheme),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, 'Monthly Trends', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MonthlySummaryScreen(),
                      ),
                    );
                    _loadData();
                  }),
                  _buildMonthlyOverview(colorScheme, textTheme),
                  const SizedBox(height: 24),

                  _buildSectionHeader(context, 'Daily Activity', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailySummaryScreen(),
                      ),
                    );
                    _loadData();
                  }),
                  _buildDailyOverview(colorScheme, textTheme),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onSeeAll,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'See all',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOverview(ColorScheme colorScheme, TextTheme textTheme) {
    Map<int, _CategorySummary> categoryStats = {};
    for (var s in _allSpendings) {
      final id = s.categoryId ?? -1;
      if (!categoryStats.containsKey(id)) {
        categoryStats[id] = _CategorySummary(
          name: s.categoryName ?? 'Other',
          icon: s.categoryIcon,
          color: s.categoryColor,
          total: 0,
        );
      }
      categoryStats[id]!.total += s.amount;
    }
    final sorted = categoryStats.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No categories recorded.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    return Column(
      children: top3.map((entry) {
        final stat = entry.value;
        final catColor = ColorUtils.fromInt(stat.color);
        final catIcon = IconUtils.fromString(stat.icon);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: catColor.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        HistoryScreen(filterCategory: stat.name),
                  ),
                );
                if (result == true) {
                  _loadData();
                  widget.refreshNotifier.value++;
                }
              },
              leading: Icon(catIcon, color: catColor, size: 24),
              title: Text(
                stat.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${stat.total.toStringAsFixed(0)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyOverview(ColorScheme colorScheme, TextTheme textTheme) {
    Map<String, double> monthlyTotals = {};
    for (var s in _allSpendings) {
      if (!s.includeInSpendingAnalysis) continue;
      final month = DateFormat('MMM yyyy').format(s.date);
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + s.amount;
    }
    final sorted = monthlyTotals.entries.toList()
      ..sort((a, b) => _compareMonths(b.key, a.key));
    final top2 = sorted.take(2).toList();

    if (top2.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No monthly data.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    return Column(
      children: top2.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(filterMonth: entry.key),
                  ),
                );
                if (result == true) {
                  _loadData();
                  widget.refreshNotifier.value++;
                }
              },
              leading: Icon(
                Icons.calendar_month,
                color: colorScheme.primary,
                size: 24,
              ),
              title: Text(
                entry.key,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyOverview(ColorScheme colorScheme, TextTheme textTheme) {
    Map<String, double> dailyTotals = {};
    for (var s in _allSpendings) {
      if (!s.includeInSpendingAnalysis) continue;
      final day = DateFormat('yyyy-MM-dd').format(s.date);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + s.amount;
    }
    final sorted = dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No daily activity.',
          style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    return Column(
      children: top3.map((entry) {
        final date = DateTime.parse(entry.key);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            elevation: 0,
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(filterDate: entry.key),
                  ),
                );
                if (result == true) {
                  _loadData();
                  widget.refreshNotifier.value++;
                }
              },
              leading: Icon(
                Icons.calendar_today,
                color: colorScheme.primary,
                size: 24,
              ),
              title: Text(
                DateFormat('EEEE, MMM dd').format(date),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  int _compareMonths(String a, String b) {
    final format = DateFormat('MMM yyyy');
    return format.parse(a).compareTo(format.parse(b));
  }
}

class _CategorySummary {
  final String name;
  final String? icon;
  final int? color;
  double total;

  _CategorySummary({
    required this.name,
    this.icon,
    this.color,
    required this.total,
  });
}
