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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Spendings'),
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
          ? const Center(child: Text('No spendings noted yet.'))
          : ListView.builder(
              itemCount: _spendings.size,
              itemBuilder: (context, index) {
                final spending = _spendings[index];
                return ListTile(
                  title: Text(spending.title),
                  subtitle: Text(
                    '${spending.category} - ${DateFormat('MMM dd, yyyy').format(spending.date)}\n${spending.description ?? ""}',
                  ),
                  trailing: Text(
                    '₹${spending.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.redAccent,
                    ),
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Spending?'),
                        content: const Text(
                          'Are you sure you want to delete this entry?',
                        ),
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
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
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
}

extension on List {
  int get size => length;
}
