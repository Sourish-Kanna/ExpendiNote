import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

class TransactionCard extends StatelessWidget {
  final Transaction? transaction;
  final Category? category;
  final int? categoryTxCount;
  final double? categoryTotalAmount;

  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final Widget? trailingWidget;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.titleWidget,
    this.subtitleWidget,
    this.trailingWidget,
    this.contentPadding,
    this.onTap,
    this.onLongPress,
  })  : category = null,
        categoryTxCount = null,
        categoryTotalAmount = null;

  const TransactionCard.category({
    super.key,
    required this.category,
    required this.categoryTxCount,
    required this.categoryTotalAmount,
    this.titleWidget,
    this.subtitleWidget,
    this.trailingWidget,
    this.contentPadding,
    this.onTap,
    this.onLongPress,
  }) : transaction = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final Color cardColor;
    final IconData iconData;
    final Widget title;
    final Widget subtitle;
    final Widget? trailing;

    if (transaction != null) {
      final t = transaction!;
      cardColor = ColorUtils.fromInt(t.categoryColor);
      iconData = IconUtils.fromString(t.categoryIcon);

      title = titleWidget ??
          Text(
            t.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          );

      subtitle = subtitleWidget ??
          Text(
            '${t.categoryName ?? 'Other'} • ${DateFormat('d/M').format(t.date)} • ${DateFormat('hh:mm a').format(t.date)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );

      trailing = trailingWidget ??
          Text(
            '₹${t.amount.toStringAsFixed(0)}',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          );
    } else if (category != null) {
      final c = category!;
      cardColor = ColorUtils.fromInt(c.color);
      iconData = IconUtils.fromString(c.icon);

      title = titleWidget ??
          Row(
            children: [
              Text(
                c.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (c.isPinned) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin, size: 14, color: cardColor),
              ],
            ],
          );

      subtitle = subtitleWidget ??
          Text(
            '${categoryTxCount ?? 0} transactions • ₹${(categoryTotalAmount ?? 0.0).toStringAsFixed(0)}',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          );

      trailing = trailingWidget;
    } else {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: cardColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          iconData,
          color: cardColor,
          size: 24,
        ),
        title: title,
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }
}

void showTransactionActionSheet({
  required BuildContext context,
  required Transaction transaction,
  required VoidCallback onEdit,
  required VoidCallback onDelete,
}) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  transaction.title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text(
                  'Delete',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onDelete();
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void showCategoryActionSheet({
  required BuildContext context,
  required Category category,
  required int txCount,
  required VoidCallback onEdit,
  required VoidCallback onMerge,
  required VoidCallback onDelete,
}) {
  final theme = Theme.of(context);
  final textTheme = theme.textTheme;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  category.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit();
                },
              ),
              ListTile(
                leading: const Icon(Icons.merge_type),
                title: const Text('Merge'),
                onTap: () {
                  Navigator.pop(context);
                  onMerge();
                },
              ),
              if (txCount == 0)
                ListTile(
                  leading: Icon(Icons.delete, color: theme.colorScheme.error),
                  title: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onDelete();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
