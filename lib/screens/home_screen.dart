import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'add_spending_screen.dart';
import 'daily_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Spending> _allSpendings = [];
  List<Spending> _todaySpendings = [];
  double _todayTotal = 0;
  double _monthlyTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSpendings();
  }

  Future<void> _refreshSpendings() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService().getSpendings();

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthStr = DateFormat('yyyy-MM').format(now);

    final todayData = data
        .where((s) => DateFormat('yyyy-MM-dd').format(s.date) == todayStr)
        .toList();
    final total = todayData.fold(0.0, (sum, item) => sum + item.amount);

    final monthlyTotal = data
        .where((s) => DateFormat('yyyy-MM').format(s.date) == monthStr)
        .fold(0.0, (sum, item) => sum + item.amount);

    setState(() {
      _allSpendings = data;
      _todaySpendings = todayData;
      _todayTotal = total;
      _monthlyTotal = monthlyTotal;
      _isLoading = false;
    });
  }

  void _deleteSpending(int id) async {
    await DatabaseService().deleteSpending(id);
    _refreshSpendings();
  }

  void _exportCSV() async {
    if (_allSpendings.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    await ExportService().exportToCSV(_allSpendings);
  }

  void _confirmDeleteOld() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Old Records?'),
        content: const Text(
          'This will permanently delete all spending entries older than 3 months. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final count = await DatabaseService().deleteOldSpendings(3);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Deleted $count old records.')),
              );
              _refreshSpendings();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExpendNote'),
        backgroundColor: colorScheme.surfaceContainerLow,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailySummaryScreen(),
                ),
              );
              _refreshSpendings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Download CSV',
            onPressed: _exportCSV,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_old') {
                _confirmDeleteOld();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete_old',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear > 3 months'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTotalCard(colorScheme),
                Expanded(
                  child: _todaySpendings.isEmpty
                      ? _buildEmptyState(colorScheme)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _todaySpendings.length,
                          itemBuilder: (context, index) {
                            final spending = _todaySpendings[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 4,
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: colorScheme.primaryContainer,
                                  child: Icon(
                                    _getCategoryIcon(spending.category),
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                title: Text(
                                  spending.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${spending.category} • ${DateFormat('hh:mm a').format(spending.date)}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    if (spending.description != null &&
                                        spending.description!.isNotEmpty)
                                      Tooltip(
                                        message: spending.description!,
                                        child: Text(
                                          spending.description!,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  '₹${spending.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: colorScheme.error,
                                  ),
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddSpendingScreen(spending: spending),
                                    ),
                                  );
                                  if (result == true) {
                                    _refreshSpendings();
                                  }
                                },
                                onLongPress: () => _confirmDelete(spending),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSpendingScreen()),
          );
          if (result == true) {
            _refreshSpendings();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  "Today",
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_todayTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.onPrimaryContainer.withAlpha(51),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  "This Month",
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_monthlyTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No spendings noted for today.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Spending spending) {
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
              style: TextStyle(color: Theme.of(context).colorScheme.error),
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
