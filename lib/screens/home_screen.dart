import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../models/transaction.dart' as txmodel show Transaction;
import '../repositories/transaction_repository.dart' show TransactionRepository;
import '../theme/app_shapes.dart' show AppShapes;
import '../utils/color_utils.dart' show ColorUtils;
import '../utils/icon_utils.dart' show IconUtils;
import 'add_spending_screen.dart' show AddSpendingScreen;
import 'search_screen.dart' show SearchScreen;
import 'settings_screen.dart' show SettingsScreen;
import 'spending_detail_screen.dart' show SpendingDetailScreen;
import 'unified_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

    final todayData = data
        .where(
          (s) =>
              s.includeInSpendingAnalysis &&
              DateFormat('yyyy-MM-dd').format(s.date) == todayStr,
        )
        .toList();
    final total = todayData.fold(0.0, (sum, item) => sum + item.amount);

    final monthlyTotal = data
        .where(
          (s) =>
              s.includeInSpendingAnalysis &&
              DateFormat('yyyy-MM').format(s.date) == monthStr,
        )
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
        title: const Text('Expendi Note'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
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
                            _refreshNotifier.value++;
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
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: _getCategoryColor(
                                      spending,
                                    ).withValues(alpha: 0.2),
                                    child: Icon(
                                      _getCategoryIcon(spending),
                                      color: _getCategoryColor(spending),
                                    ),
                                  ),
                                  title: Text(
                                    spending.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  subtitle: Text(
                                    '${spending.categoryName ?? 'Other'} • ${DateFormat('hh:mm a').format(spending.date)}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  trailing: Text(
                                    '₹${spending.amount.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: colorScheme.error),
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
                                  onLongPress: () => _confirmDelete(spending),
                                ),
                              ),
                            );
                          }, childCount: _recentSpendings.length),
                        ),
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
        // label: const Text("Add"),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTotalCard(ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                UnifiedSummaryScreen(refreshNotifier: _refreshNotifier),
          ),
        );
      },
      borderRadius: AppShapes.largeRadius,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: AppShapes.largeRadius,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    "Today",
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_todayTotal.toStringAsFixed(0)}',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
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
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_monthlyTotal.toStringAsFixed(0)}',
                    style: textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
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
          const Text('No spending noted yet.'),
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
