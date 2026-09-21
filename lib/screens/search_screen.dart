import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart' as txmodel;
import '../repositories/transaction_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';
import 'spending_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<txmodel.Transaction> _allSpendings = [];
  List<txmodel.Transaction> _filteredSpendings = [];
  bool _isLoading = true;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final data = await TransactionRepository.getAllTransactions();

    setState(() {
      _allSpendings = data;
      _filteredSpendings = _allSpendings.where((s) {
        final query = _searchController.text.toLowerCase();
        return s.title.toLowerCase().contains(query) ||
            (s.categoryName?.toLowerCase().contains(query) ?? false) ||
            (s.description?.toLowerCase().contains(query) ?? false);
      }).toList();
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSpendings = _allSpendings.where((s) {
        return s.title.toLowerCase().contains(query) ||
            (s.categoryName?.toLowerCase().contains(query) ?? false) ||
            (s.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search title or category...',
            border: InputBorder.none,
            hintStyle: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
          style: textTheme.titleMedium?.copyWith(color: colorScheme.onSurface),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredSpendings.isEmpty
          ? const Center(child: Text('No results found.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _filteredSpendings.length,
              itemBuilder: (context, index) {
                final s = _filteredSpendings[index];
                final catColor = ColorUtils.fromInt(s.categoryColor);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    elevation: 0,
                    color: catColor.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Icon(
                        IconUtils.fromString(s.categoryIcon),
                        color: catColor,
                        size: 24,
                      ),
                      title: Text(
                        '${s.title} | ₹${s.amount.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${s.categoryName ?? 'Other'} | ${DateFormat('d/M').format(s.date)} | ${DateFormat('hh:mm a').format(s.date)}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SpendingDetailScreen(transaction: s),
                          ),
                        );
                        if (result == true) {
                          _hasChanged = true;
                          _loadData();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
