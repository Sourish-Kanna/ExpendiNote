import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../repositories/category_repository.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

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
  List<Category> _otherCategories = [];
  Category? _selectedDestination;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final all = await CategoryRepository.getAllCategories();
    setState(() {
      _otherCategories = all
          .where((c) => c.id != widget.sourceCategory.id)
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _merge() async {
    if (_selectedDestination == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Merge'),
        content: Text(
          'This will move all ${widget.txCount} transactions from '
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
                  if (_otherCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No other categories available to merge into.\nCreate another category first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    RadioGroup<int>(
                      groupValue: _selectedDestination?.id,
                      onChanged: (value) {
                        setState(() {
                          _selectedDestination = _otherCategories.firstWhere(
                            (cat) => cat.id == value,
                          );
                        });
                      },
                      child: Column(
                        children: _otherCategories.map((c) {
                          final isSelected = _selectedDestination?.id == c.id;
                          final catColor = ColorUtils.fromInt(c.color);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Card(
                              elevation: 0,
                              color: isSelected
                                  ? catColor.withValues(alpha: 0.2)
                                  : catColor.withValues(alpha: 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: isSelected
                                    ? BorderSide(color: catColor, width: 2)
                                    : BorderSide.none,
                              ),
                              child: RadioListTile<int>(
                                value: c.id!,
                                title: Text(
                                  c.name,
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                secondary: Icon(
                                  IconUtils.fromString(c.icon),
                                  color: catColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                '${widget.txCount} transactions will be moved',
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
