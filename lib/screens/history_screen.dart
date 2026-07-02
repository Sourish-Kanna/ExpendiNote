import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import 'add_spending_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String? filterDate;
  const HistoryScreen({super.key, this.filterDate});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, List<Spending>> _groupedSpendings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final allSpendings = await DatabaseService().getSpendings();

    // Group spendings by date string
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    Map<String, List<Spending>> grouped = {};
    for (var s in allSpendings) {
      final dateStr = DateFormat('yyyy-MM-dd').format(s.date);

      // If filtering by date, only include that date
      if (widget.filterDate != null && dateStr != widget.filterDate) continue;

      // If not filtering, skip today (it's on Home) - keeping original logic for general history
      if (widget.filterDate == null && dateStr == todayStr) continue;

      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(s);
    }

    setState(() {
      _groupedSpendings = grouped;
      _isLoading = false;
    });
  }

  void _deleteSpending(int id) async {
    await DatabaseService().deleteSpending(id);
    _loadHistory();
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

  double _calculateDailyTotal(List<Spending> spendings) {
    return spendings.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sortedDates = _groupedSpendings.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final title = widget.filterDate != null
        ? DateFormat('EEEE, MMM dd').format(DateTime.parse(widget.filterDate!))
        : 'Spending History';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedDates.isEmpty
          ? const Center(child: Text('No previous history found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final dateStr = sortedDates[index];
                final spendings = _groupedSpendings[dateStr]!;
                final dailyTotal = _calculateDailyTotal(spendings);
                final date = DateTime.parse(dateStr);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8.0,
                        horizontal: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMM dd').format(date),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Total: ₹${dailyTotal.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    ...spendings.map(
                      (s) => Card(
                        child: ListTile(
                          leading: Icon(
                            _getCategoryIcon(s.category),
                            color: colorScheme.secondary,
                          ),
                          title: Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: s.description != null
                              ? Tooltip(
                                  message: s.description!,
                                  child: Text(
                                    s.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : null,
                          trailing: Text('₹${s.amount.toStringAsFixed(2)}'),
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddSpendingScreen(spending: s),
                              ),
                            );
                            if (result == true) {
                              _loadHistory();
                            }
                          },
                          onLongPress: () => _confirmDelete(s),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
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
