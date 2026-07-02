import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import 'history_screen.dart';

class DailySummaryScreen extends StatefulWidget {
  const DailySummaryScreen({super.key});

  @override
  State<DailySummaryScreen> createState() => _DailySummaryScreenState();
}

class _DailySummaryScreenState extends State<DailySummaryScreen> {
  Map<String, List<Spending>> _groupedSpendings = {};
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
    final allSpendings = await DatabaseService().getSpendings();

    Map<String, List<Spending>> grouped = {};
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

  double _calculateDailyTotal(List<Spending> spendings) {
    return spendings.fold(0, (sum, item) => sum + item.amount);
  }

  String _getTopCategory(List<Spending> spendings) {
    if (spendings.isEmpty) return 'None';
    Map<String, double> categoryTotals = {};
    for (var s in spendings) {
      categoryTotals[s.category] = (categoryTotals[s.category] ?? 0) + s.amount;
    }
    return categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Summary'),
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
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
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

                return Card(
                  elevation: 0,
                  color: isToday
                      ? colorScheme.primaryContainer.withAlpha(50)
                      : colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isToday ? 1 : 0.5,
                    ),
                  ),
                  child: ListTile(
                    onTap: () {
                      // Navigate to detail view
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryScreen(filterDate: dateStr),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      backgroundColor: isToday
                          ? colorScheme.primary
                          : colorScheme.secondaryContainer,
                      child: Text(
                        DateFormat('dd').format(date),
                        style: TextStyle(
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(_getTopCategory(spendings)),
                          size: 14,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getTopCategory(spendings)} • ${spendings.length} items',
                          style: TextStyle(color: colorScheme.secondary),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${dailyTotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
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
