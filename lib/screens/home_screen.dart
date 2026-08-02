import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import 'add_spending_screen.dart';
import 'search_screen.dart';
import 'spending_detail_screen.dart';
import 'unified_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      _HomeTab(
        refreshNotifier: _refreshNotifier,
        onShowAnalysis: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      UnifiedSummaryScreen(refreshNotifier: _refreshNotifier),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analysis',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.large(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSpendingScreen(),
                  ),
                );
                if (result == true) {
                  _refreshNotifier.value++;
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _HomeTab extends StatefulWidget {
  final ValueNotifier<int> refreshNotifier;
  final VoidCallback onShowAnalysis;
  const _HomeTab({required this.refreshNotifier, required this.onShowAnalysis});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<txmodel.Transaction> _recentSpendings = [];
  double _todayTotal = 0;
  double _monthlyTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshSpendings();
    widget.refreshNotifier.addListener(_refreshSpendings);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_refreshSpendings);
    super.dispose();
  }

  Future<void> _refreshSpendings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final List<Map<String, dynamic>> rawDataMaps = await TransactionRepository()
        .getAllWithCategoryName();

    final data = rawDataMaps
        .map((m) => txmodel.Transaction.fromMap(m))
        .toList();

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

    if (!mounted) return;
    setState(() {
      _recentSpendings = data.take(20).toList();
      _todayTotal = total;
      _monthlyTotal = monthlyTotal;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('ExpendNote'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshSpendings,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SearchBar(
                        hintText: 'Search spending...',
                        leading: const Icon(Icons.search),
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStateProperty.all(
                          colorScheme.surfaceContainerHigh,
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                          if (result == true) {
                            widget.refreshNotifier.value++;
                          }
                        },
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: _buildTotalCard(colorScheme)),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  _recentSpendings.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(colorScheme),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final spending = _recentSpendings[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Card(
                                color: colorScheme.surfaceContainerLow,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        colorScheme.primaryContainer,
                                    child: Icon(
                                      _getCategoryIcon(spending.category),
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    spending.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${spending.category} • ${DateFormat('hh:mm a').format(spending.date)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    '₹${spending.amount.toStringAsFixed(0)}',
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
                                            SpendingDetailScreen(
                                              transaction: spending,
                                            ),
                                      ),
                                    );
                                    if (result == true) {
                                      widget.refreshNotifier.value++;
                                    }
                                  },
                                  onLongPress: () => _confirmDelete(spending),
                                ),
                              ),
                            );
                          }, childCount: _recentSpendings.length),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildTotalCard(ColorScheme colorScheme) {
    return InkWell(
      onTap: widget.onShowAnalysis,
      borderRadius: BorderRadius.circular(24),
      child: Container(
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
          const Text('No spendings noted yet.'),
        ],
      ),
    );
  }

  void _confirmDelete(txmodel.Transaction spending) {
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
            onPressed: () async {
              Navigator.pop(context);
              await TransactionRepository().deleteTransaction(spending.id!);
              widget.refreshNotifier.value++;
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
