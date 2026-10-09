import 'package:intl/intl.dart' show DateFormat;
import 'package:material_ui/material_ui.dart';

import '../models/transaction.dart';
import '../utils/color_utils.dart';
import '../utils/icon_utils.dart';

/// A shared card widget for displaying a transaction list item according to Material 3 design specs.
class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? subtitle;
  final String? amountText;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? contentPadding;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onLongPress,
    this.subtitle,
    this.amountText,
    this.margin = const EdgeInsets.only(bottom: 8),
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 8,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final catColor = ColorUtils.fromInt(transaction.categoryColor);
    final catIcon = IconUtils.fromString(transaction.categoryIcon);

    final String displaySubtitle =
        subtitle ??
        '${transaction.categoryName ?? 'Other'} • ${DateFormat('d/M').format(transaction.date)} • ${DateFormat('hh:mm a').format(transaction.date)}';

    final String displayAmount =
        amountText ??
        '₹${transaction.amount % 1 == 0 ? transaction.amount.toStringAsFixed(0) : transaction.amount.toStringAsFixed(2)}';

    Widget cardChild = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: catColor.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: contentPadding,
        leading: Icon(catIcon, color: catColor, size: 24),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          displaySubtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              displayAmount,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.more_vert,
              size: 18,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              semanticLabel: 'Long press for options',
            ),
          ],
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
