import 'package:flutter/material.dart';

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
  final CategoryRepository _categoryRepository = CategoryRepository();
  List<Category> _otherCategories = [];
  Category? _selectedDestination;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final all = await _categoryRepository.getAllCategories();
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
        await _categoryRepository.mergeCategories(
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
      appBar: AppBar(
        title: const Text('Merge Category'),
        backgroundColor: colorScheme.surfaceContainer,
        scrolledUnderElevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSourceCard(colorScheme),
                  const SizedBox(height: 16),
                  const Center(child: Icon(Icons.arrow_downward, size: 32)),
                  const SizedBox(height: 16),
                  Text(
                    'Into Destination Category',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_otherCategories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No other categories available to merge into. Create another category first.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    ..._otherCategories.map(
                      (c) => Card(
                        color: _selectedDestination?.id == c.id
                            ? colorScheme.primaryContainer.withValues(
                                alpha: 0.3,
                              )
                            : colorScheme.surfaceContainerLow,
                        child: RadioListTile<int>(
                          value: c.id!,
                          groupValue: _selectedDestination?.id,
                          onChanged: (value) {
                            setState(() {
                              _selectedDestination = c;
                            });
                          },
                          title: Text(
                            c.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: ColorUtils.fromInt(
                              c.color,
                            ).withValues(alpha: 0.2),
                            child: Icon(
                              IconUtils.fromString(c.icon),
                              color: ColorUtils.fromInt(c.color),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),
                  FilledButton.icon(
                    onPressed: _selectedDestination == null ? null : _merge,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                    ),
                    icon: const Icon(Icons.merge_type),
                    label: const Text('Merge Categories'),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This moves all associated transactions and deletes the source category.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSourceCard(ColorScheme colorScheme) {
    return Card(
      color: colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Merge From (Source)'),
            const SizedBox(height: 12),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: ColorUtils.fromInt(
                  widget.sourceCategory.color,
                ).withValues(alpha: 0.2),
                child: Icon(
                  IconUtils.fromString(widget.sourceCategory.icon),
                  color: ColorUtils.fromInt(widget.sourceCategory.color),
                ),
              ),
              title: Text(
                widget.sourceCategory.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${widget.txCount} transactions will be moved'),
            ),
          ],
        ),
      ),
    );
  }
}
