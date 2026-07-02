import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/spending.dart';
import '../services/database_service.dart';
import '../services/export_service.dart';
import 'add_spending_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Spending> _spendings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSpendings();
  }

  Future<void> _refreshSpendings() async {
    setState(() => _isLoading = true);
    final data = await DatabaseService().getSpendings();
    setState(() {
      _spendings = data;
      _isLoading = false;
    });
  }

  void _deleteSpending(int id) async {
    await DatabaseService().deleteSpending(id);
    _refreshSpendings();
  }

  void _exportJSON() async {
    if (_spendings.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    await ExportService().exportToJSON(_spendings);
  }

  void _exportCSV() async {
    if (_spendings.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }
    await ExportService().exportToCSV(_spendings);
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
            icon: const Icon(Icons.code),
            tooltip: 'Export JSON',
            onPressed: _exportJSON,
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Export CSV',
            onPressed: _exportCSV,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _spendings.isEmpty
          ? Center(
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
                    'No spendings noted yet.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _spendings.length,
              itemBuilder: (context, index) {
                final spending = _spendings[index];
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${spending.category} • ${DateFormat('MMM dd, yyyy').format(spending.date)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (spending.description != null &&
                            spending.description!.isNotEmpty)
                          Text(
                            spending.description!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
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
                    onLongPress: () => _confirmDelete(spending),
                  ),
                );
              },
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
