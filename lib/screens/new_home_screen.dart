import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel show Transaction;
import '../repositories/transaction_repository.dart' show TransactionRepository;
import '../utils/color_utils.dart' show ColorUtils;
import '../utils/icon_utils.dart' show IconUtils;
import 'add_spending_screen.dart' show AddSpendingScreen;
import 'search_screen.dart' show SearchScreen;
import 'settings_screen.dart' show SettingsScreen;
import 'spending_detail_screen.dart' show SpendingDetailScreen;
import 'unified_summary_screen.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  List<txmodel.Transaction> _recentSpendings = [];
  double _todayTotal = 0;
  double _monthlyTotal = 0;
  bool _isLoading = true;
  final ValueNotifier<int> _refreshNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _refreshSpendings();
    _refreshNotifier.addListener(_refreshSpendings);
  }

  @override
  void dispose() {
    _refreshNotifier.removeListener(_refreshSpendings);
    _refreshNotifier.dispose();
    super.dispose();
  }

  Future<void> _refreshSpendings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final data = await TransactionRepository.getAllTransactions();

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthStr = DateFormat('yyyy-MM').format(now);

    final todayTotal = data
        .where(
          (s) =>
              s.includeInSpendingAnalysis &&
              DateFormat('yyyy-MM-dd').format(s.date) == todayStr,
        )
        .fold(0.0, (sum, item) => sum + item.amount);

    final monthlyTotal = data
        .where(
          (s) =>
              s.includeInSpendingAnalysis &&
              DateFormat('yyyy-MM').format(s.date) == monthStr,
        )
        .fold(0.0, (sum, item) => sum + item.amount);

    if (!mounted) return;
    setState(() {
      _recentSpendings = data.take(10).toList();
      _todayTotal = todayTotal;
      _monthlyTotal = monthlyTotal;
      _isLoading = false;
    });
  }

  void _navigateToAnalysis() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UnifiedSummaryScreen(refreshNotifier: _refreshNotifier),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Expendi Note',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                _refreshNotifier.value++;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshSpendings,
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SearchBar(
                        hintText: 'Search Expense',
                        trailing: const [Icon(Icons.search)],
                        elevation: WidgetStateProperty.all(0),
                        backgroundColor: WidgetStateProperty.all(
                          colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SearchScreen(),
                            ),
                          );
                          if (result == true) {
                            _refreshNotifier.value++;
                          }
                        },
                      ),
                    ),
                  ),

                  // Analysis Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: InkWell(
                        onTap: _navigateToAnalysis,
                        child: Row(
                          children: [
                            Text(
                              'Analysis',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Analysis Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: _navigateToAnalysis,
                        borderRadius: BorderRadius.circular(28),
                        child: Card(
                          elevation: 0,
                          color: colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          "Today",
                                          style: textTheme.labelLarge?.copyWith(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _todayTotal.toStringAsFixed(2),
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: colorScheme.primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(
                                    color: colorScheme.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    thickness: 2,
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Text(
                                          "This Month",
                                          style: textTheme.labelLarge?.copyWith(
                                            color: colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _monthlyTotal.toStringAsFixed(2),
                                          style: textTheme.headlineMedium
                                              ?.copyWith(
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
                      ),
                    ),
                  ),

                  // Recent Activity Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Recent Activity',
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),

                  // Activity List
                  _recentSpendings.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: _buildEmptyState(colorScheme),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final spending = _recentSpendings[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Card(
                                  elevation: 0,
                                  color: _getCategoryColor(
                                    spending,
                                  ).withValues(alpha: 0.12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    leading: Icon(
                                      _getCategoryIcon(spending),
                                      color: _getCategoryColor(spending),
                                    ),
                                    title: Text(
                                      '${spending.title} | ₹${spending.amount.toStringAsFixed(0)}',
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${spending.categoryName ?? 'Other'} | ${DateFormat('d/M').format(spending.date)} | ${DateFormat('hh:mm a').format(spending.date)}',
                                      style: textTheme.bodySmall,
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.more_vert),
                                      onPressed: () =>
                                          _showItemActions(spending),
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
                                        _refreshNotifier.value++;
                                      }
                                    },
                                  ),
                                ),
                              );
                            }, childCount: _recentSpendings.length),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddSpendingScreen()),
          );
          if (result == true) {
            _refreshNotifier.value++;
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 64, color: colorScheme.outline),
          const SizedBox(height: 16),
          const Text('No spending noted yet.'),
        ],
      ),
    );
  }

  void _showItemActions(txmodel.Transaction spending) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AddSpendingScreen(transaction: spending),
                ),
              );
              if (result == true) {
                _refreshNotifier.value++;
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(spending);
            },
          ),
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
              await TransactionRepository.deleteTransaction(spending.id!);
              _refreshNotifier.value++;
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

  IconData _getCategoryIcon(txmodel.Transaction spending) {
    return IconUtils.fromString(spending.categoryIcon);
  }

  Color _getCategoryColor(txmodel.Transaction spending) {
    return ColorUtils.fromInt(spending.categoryColor);
  }
}
