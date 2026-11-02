import 'package:material_ui/material_ui.dart';

import '../../models/category.dart';
import '../../repositories/category_repository.dart';
import '../../utils/color_utils.dart';
import '../../utils/icon_utils.dart';

class MergeCategoryScreen extends StatefulWidget {
  final Category sourceCategory;
  final int txCount;
  const MergeCategoryScreen({
    super.key,
    required this.sourceCategory,
    required this.txCount,
  });

  @override
  State<MergeCategoryScreen> createState() => _MergeCategoryScreenState();
}

class _MergeCategoryScreenState extends State<MergeCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Category> _allOtherCategories = [];
  List<Category> _filteredCategories = [];
  Map<int, int> _destinationCounts = {};
  Map<int, double> _destinationTotals = {};
  double _sourceTotalAmount = 0.0;
  Category? _selectedDestination;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _allOtherCategories;
      } else {
        _filteredCategories = _allOtherCategories
            .where((c) => c.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _loadCategories() async {
    try {
      final stats = await CategoryRepository.getCategoriesWithStats();

      double sourceTotal = 0.0;
      final Map<int, int> counts = {};
      final Map<int, double> totals = {};
      final List<Category> others = [];

      for (final stat in stats) {
        final cat = Category.fromMap(stat);
        final count = (stat['transactionCount'] as int?) ?? 0;
        final total = (stat['totalAmount'] ?? 0.0).toDouble();

        if (cat.id == widget.sourceCategory.id) {
          sourceTotal = total;
        } else {
          counts[cat.id!] = count;
          totals[cat.id!] = total;
          others.add(cat);
        }
      }

      if (mounted) {
        setState(() {
          _sourceTotalAmount = sourceTotal;
          _allOtherCategories = others;
          _filteredCategories = others;
          _destinationCounts = counts;
          _destinationTotals = totals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  Future<void> _merge() async {
    if (_selectedDestination == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Merge'),
        content: Text(
          'This will move all ${widget.txCount} transactions '
          '(₹${_sourceTotalAmount.toStringAsFixed(2)}) from '
          '"${widget.sourceCategory.name}" to "${_selectedDestination!.name}".\n\n'
          '"${widget.sourceCategory.name}" will be deleted.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Merge'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await CategoryRepository.mergeCategories(
          widget.sourceCategory.id!,
          _selectedDestination!.id!,
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Merge failed: $e')));
        }
      }
    }
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
          'Merge Category',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSourceCard(theme),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Icon(
                        Icons.arrow_downward,
                        size: 32,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Text(
                    'Into Destination Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_allOtherCategories.length >= 5) ...[
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search destination categories...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_allOtherCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No other categories available to merge into.\nCreate another category first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else if (_filteredCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        'No categories match your search.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ..._filteredCategories.map((c) {
                      final isSelected = _selectedDestination?.id == c.id;
                      final catColor = ColorUtils.fromInt(c.color);
                      final count = _destinationCounts[c.id!] ?? 0;
                      final total = _destinationTotals[c.id!] ?? 0.0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Card(
                          elevation: 0,
                          color: isSelected
                              ? catColor.withValues(alpha: 0.2)
                              : catColor.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isSelected
                                ? BorderSide(color: catColor, width: 2)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              setState(() {
                                _selectedDestination = c;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    IconUtils.fromString(c.icon),
                                    color: catColor,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          c.name,
                                          style: textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$count transactions • ₹${total.toStringAsFixed(2)}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: catColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _selectedDestination == null ? null : _merge,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.merge),
                    label: const Text('Merge Categories'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'This moves all associated transactions and deletes the source category.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: colorScheme.outline,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSourceCard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final catColor = ColorUtils.fromInt(widget.sourceCategory.color);

    return Card(
      elevation: 0,
      color: catColor.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: catColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Text(
              'Merge From (Source)',
              style: textTheme.labelLarge?.copyWith(
                color: catColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  IconUtils.fromString(widget.sourceCategory.icon),
                  color: catColor,
                  size: 28,
                ),
              ),
              title: Text(
                widget.sourceCategory.name,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${widget.txCount} transactions • ₹${_sourceTotalAmount.toStringAsFixed(2)} will be moved',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
