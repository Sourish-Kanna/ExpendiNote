import 'package:expend_note/widgets/summary_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'SummaryCard label and value use maxLines: 1 and TextOverflow.ellipsis',
    (tester) async {
      const item = MetricItem(
        label: 'Very Long Metric Label That Should Overflow Beyond Card Width',
        value: '₹123,456,789.00 Very Long Value String That Overflows',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 200, child: SummaryCard(items: [item])),
          ),
        ),
      );

      final labelText = tester.widget<Text>(
        find.text(
          'Very Long Metric Label That Should Overflow Beyond Card Width',
        ),
      );
      final valueText = tester.widget<Text>(
        find.text('₹123,456,789.00 Very Long Value String That Overflows'),
      );

      expect(labelText.maxLines, equals(1));
      expect(labelText.overflow, equals(TextOverflow.ellipsis));
      expect(valueText.maxLines, equals(1));
      expect(valueText.overflow, equals(TextOverflow.ellipsis));
    },
  );
}
