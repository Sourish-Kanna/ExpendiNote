import 'package:material_ui/material_ui.dart';

import '../models/category.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

/// A shared card widget for displaying a category item according to Material 3 design specs.
class CategoryCard extends StatelessWidget {
  final Category category;
  final int transactionCount;
  final double totalAmount;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;

  const CategoryCard({
    super.key,
    required this.category,
    required this.transactionCount,
    required this.totalAmount,
    this.onTap,
    this.onLongPress,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final catColor = ColorUtils.fromInt(category.color);
    final catIcon = IconUtils.fromString(category.icon);

    Widget cardChild = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: catColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: contentPadding,
        leading: Icon(catIcon, color: catColor, size: 24),
        title: Row(
          children: [
            Text(
              category.name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            if (category.isPinned) ...[
              const SizedBox(width: 8),
              Icon(Icons.push_pin, size: 14, color: catColor),
            ],
          ],
        ),
        subtitle: Text(
          '$transactionCount transactions • ₹${totalAmount.toStringAsFixed(0)}',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.more_vert,
          size: 18,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          semanticLabel: 'Long press for options',
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: cardChild);
    }

    return cardChild;
  }
}
