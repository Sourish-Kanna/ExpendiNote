import 'package:material_ui/material_ui.dart';

import '../models/category.dart';

enum CategoryOption { edit, merge, delete }

/// Displays a Material 3 modal bottom sheet with options to Edit, Merge, or Delete a category.
Future<CategoryOption?> showCategoryOptionsBottomSheet({
  required BuildContext context,
  required Category category,
  required int transactionCount,
}) {
  return showModalBottomSheet<CategoryOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => CategoryOptionsBottomSheet(
      category: category,
      transactionCount: transactionCount,
    ),
  );
}

class CategoryOptionsBottomSheet extends StatelessWidget {
  final Category category;
  final int transactionCount;

  const CategoryOptionsBottomSheet({
    super.key,
    required this.category,
    required this.transactionCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bool canDelete = transactionCount == 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                category.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(
                'Edit',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context, CategoryOption.edit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.merge_type),
              title: Text(
                'Merge',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context, CategoryOption.merge);
              },
            ),
            ListTile(
              enabled: canDelete,
              leading: Icon(
                Icons.delete,
                color: canDelete ? colorScheme.error : null,
              ),
              title: Text(
                'Delete',
                style: textTheme.bodyLarge?.copyWith(
                  color: canDelete ? colorScheme.error : null,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: canDelete
                  ? () {
                      Navigator.pop(context, CategoryOption.delete);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
