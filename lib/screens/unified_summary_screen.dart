import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'category_summary_screen.dart';
import 'daily_summary_screen.dart';
import 'monthly_summary_screen.dart';

class UnifiedSummaryScreen extends StatefulWidget {
  final ValueNotifier<int> refreshNotifier;
  const UnifiedSummaryScreen({super.key, required this.refreshNotifier});

  @override
  State<UnifiedSummaryScreen> createState() => _UnifiedSummaryScreenState();
}

class _UnifiedSummaryScreenState extends State<UnifiedSummaryScreen> {
  List<Spending> _allSpendings = [];
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
    final data = await DatabaseService().getSpendings();
    setState(() {
      _allSpendings = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Analysis'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: () async {
              if (_allSpendings.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No data to export')),
                  );
                }
                return;
              }
              await ExportService().exportToCSV(_allSpendings);
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader(context, 'Categories', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CategorySummaryScreen(),
                      ),
                    );
                    _loadData();
                  }),
                  _buildCategoryOverview(colorScheme),
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
                  _buildMonthlyOverview(colorScheme),
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
                  _buildDailyOverview(colorScheme),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }

  Widget _buildCategoryOverview(ColorScheme colorScheme) {
    Map<String, double> categoryTotals = {};
    for (var s in _allSpendings) {
      categoryTotals[s.category] = (categoryTotals[s.category] ?? 0) + s.amount;
    }
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) return const Text('No categories recorded.');

    return Column(
      children: top3.map((entry) {
        return Card(
          color: colorScheme.surfaceContainerLow,
          child: ListTile(
            leading: Icon(
              _getCategoryIcon(entry.key),
              color: colorScheme.primary,
            ),
            title: Text(entry.key),
            trailing: Text(
              '₹${entry.value.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyOverview(ColorScheme colorScheme) {
    Map<String, double> monthlyTotals = {};
    for (var s in _allSpendings) {
      final month = DateFormat('MMM yyyy').format(s.date);
      monthlyTotals[month] = (monthlyTotals[month] ?? 0) + s.amount;
    }
    final sorted = monthlyTotals.entries.toList()
      ..sort((a, b) => _compareMonths(b.key, a.key));
    final top2 = sorted.take(2).toList();

    if (top2.isEmpty) return const Text('No monthly data.');

    return Column(
      children: top2.map((entry) {
        return Card(
          color: colorScheme.surfaceContainerLow,
          child: ListTile(
            title: Text(entry.key),
            trailing: Text(
              '₹${entry.value.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailyOverview(ColorScheme colorScheme) {
    Map<String, double> dailyTotals = {};
    for (var s in _allSpendings) {
      final day = DateFormat('yyyy-MM-dd').format(s.date);
      dailyTotals[day] = (dailyTotals[day] ?? 0) + s.amount;
    }
    final sorted = dailyTotals.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    final top3 = sorted.take(3).toList();

    if (top3.isEmpty) return const Text('No daily activity.');

    return Column(
      children: top3.map((entry) {
        final date = DateTime.parse(entry.key);
        return Card(
          color: colorScheme.surfaceContainerLow,
          child: ListTile(
            title: Text(DateFormat('EEEE, MMM dd').format(date)),
            trailing: Text(
              '₹${entry.value.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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
