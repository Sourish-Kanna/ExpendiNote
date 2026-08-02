import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import 'history_screen.dart';

class MonthlySummaryScreen extends StatefulWidget {
  const MonthlySummaryScreen({super.key});

  @override
  State<MonthlySummaryScreen> createState() => _MonthlySummaryScreenState();
}

class _MonthlySummaryScreenState extends State<MonthlySummaryScreen> {
  Map<String, List<txmodel.Transaction>> _monthlySpendings = {};
  List<String> _sortedMonths = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlySummary();
  }

  Future<void> _loadMonthlySummary() async {
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> rawDataMaps = await TransactionRepository()
        .getAllWithCategoryName();

    final allSpendings = rawDataMaps
        .map((m) => txmodel.Transaction.fromMap(m))
        .toList();

    Map<String, List<txmodel.Transaction>> grouped = {};
    for (var s in allSpendings) {
      final monthStr = DateFormat('yyyy-MM').format(s.date);
      if (!grouped.containsKey(monthStr)) {
        grouped[monthStr] = [];
      }
      grouped[monthStr]!.add(s);
    }

    final sorted = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    setState(() {
      _monthlySpendings = grouped;
      _sortedMonths = sorted;
      _isLoading = false;
    });
  }

  double _calculateMonthlyTotal(List<txmodel.Transaction> spendings) {
    return spendings.fold(0, (sum, item) => sum + item.amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Monthly Summary'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sortedMonths.isEmpty
          ? const Center(child: Text('No spending history found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sortedMonths.length,
              itemBuilder: (context, index) {
                final monthStr = _sortedMonths[index];
                final spendings = _monthlySpendings[monthStr]!;
                final monthlyTotal = _calculateMonthlyTotal(spendings);
                final date = DateTime.parse('$monthStr-01');
                final filterMonthStr = DateFormat('MMM yyyy').format(date);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.calendar_month,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      DateFormat('MMMM yyyy').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${spendings.length} entries'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '₹${monthlyTotal.toStringAsFixed(0)}',
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
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              HistoryScreen(filterMonth: filterMonthStr),
                        ),
                      );
                      _loadMonthlySummary();
                    },
                  ),
                );
              },
            ),
    );
  }
}
