import 'package:material_ui/material_ui.dart';

class MetricItem {
  final String label;
  final String value;
  final Color? color;

  const MetricItem({required this.label, required this.value, this.color});
}

class SummaryCard extends StatelessWidget {
  final List<MetricItem> items;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// Displays a single metric with a prominent, centered value.
  final bool prominent;

  const SummaryCard({
    super.key,
    required this.items,
    this.onTap,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 28.0,
    this.padding = const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
    this.margin,
    this.prominent = false,
  }) : assert(
         items.length >= 1 && items.length <= 2,
         'SummaryCard supports exactly one or two metrics.',
       ),
       assert(
         !prominent || items.length == 1,
         'Prominent layout supports exactly one metric.',
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cardBgColor =
        backgroundColor ?? colorScheme.primaryContainer.withValues(alpha: 0.4);

    final defaultTextColor = textColor ?? colorScheme.primary;

    final Widget content = prominent
        ? _buildProminentContent(
            textTheme: textTheme,
            defaultTextColor: defaultTextColor,
          )
        : IntrinsicHeight(
            child: Row(
              children: _buildChildren(
                colorScheme,
                textTheme,
                defaultTextColor,
              ),
            ),
          );

    Widget cardContent = Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(padding: padding, child: content),
    );

    if (onTap != null) {
      cardContent = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: cardContent,
      );
    }

    if (margin != null) {
      cardContent = Padding(padding: margin!, child: cardContent);
    }

    return cardContent;
  }

  Widget _buildProminentContent({
    required TextTheme textTheme,
    required Color defaultTextColor,
  }) {
    final item = items.single;
    final itemTextColor = item.color ?? defaultTextColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          textAlign: TextAlign.center,
          // maxLines: 1,
          // overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: itemTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          item.value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.displayMedium?.copyWith(
            color: itemTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren(
    ColorScheme colorScheme,
    TextTheme textTheme,
    Color defaultTextColor,
  ) {
    final List<Widget> children = [];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final itemTextColor = item.color ?? defaultTextColor;

      children.add(
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: itemTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: itemTextColor,
                ),
              ),
            ],
          ),
        ),
      );

      if (i < items.length - 1) {
        children.add(
          VerticalDivider(
            color: defaultTextColor.withValues(alpha: 0.2),
            thickness: 2,
          ),
        );
      }
    }

    return children;
  }
}
