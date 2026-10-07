import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../widgets/transaction_card.dart';
import 'edit_category_screen.dart';
import 'merge_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  List<Map<String, dynamic>> _categoriesWithStats = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final stats = await CategoryRepository.getCategoriesWithStats();
    setState(() {
      _categoriesWithStats = stats;
      _isLoading = false;
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
        title: Text(
          'Manage Categories',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoriesWithStats.isEmpty
          ? const Center(child: Text('No categories found.'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _categoriesWithStats.length,
              itemBuilder: (context, index) {
                final catMap = _categoriesWithStats[index];
                final category = Category.fromMap(catMap);
                final txCount = catMap['transactionCount'] ?? 0;
                final totalAmount =
                    (catMap['totalAmount'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TransactionCard.category(
                    category: category,
                    categoryTxCount: txCount,
                    categoryTotalAmount: totalAmount,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    onTap: () => _editCategory(category),
                    onLongPress: () {
                      showCategoryActionSheet(
                        context: context,
                        category: category,
                        txCount: txCount,
                        onEdit: () => _editCategory(category),
                        onMerge: () => _mergeCategory(category, txCount),
                        onDelete: () => _confirmDelete(category),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _editCategory(null),
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _editCategory(Category? category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCategoryScreen(category: category),
      ),
    );
    if (result == true) {
      _loadCategories();
    }
  }

  Future<void> _mergeCategory(Category category, int txCount) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MergeCategoryScreen(sourceCategory: category, txCount: txCount),
      ),
    );
    if (result == true) {
      _loadCategories();
    }
  }

  void _confirmDelete(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CategoryRepository.deleteCategory(category.id!);
                if (mounted) {
                  _loadCategories();
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
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
}
