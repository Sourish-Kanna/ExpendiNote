import 'package:expend_note/widgets/summary_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Center(child: SizedBox(width: 300, child: child)),
      ),
    );
  }

  group('SummaryCard Widget Tests', () {
    testWidgets('renders single metric correctly taking full available width', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            items: const [MetricItem(label: 'Total Spending', value: '₹1,500')],
          ),
        ),
      );

      expect(find.text('Total Spending'), findsOneWidget);
      expect(find.text('₹1,500'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);
    });

    testWidgets('renders two metrics in side-by-side layout with divider', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            items: const [
              MetricItem(label: 'Today', value: '₹250'),
              MetricItem(label: 'This Month', value: '₹5,000'),
            ],
          ),
        ),
      );

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('₹250'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('₹5,000'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);
    });

    testWidgets('renders normal metric labels and values', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            items: const [MetricItem(label: 'Label One', value: 'Value One')],
          ),
        ),
      );

      expect(find.text('Label One'), findsOneWidget);
      expect(find.text('Value One'), findsOneWidget);
    });

    testWidgets('handles very long label without layout overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            items: const [
              MetricItem(
                label:
                    'Extremely Long Metric Label That Will Overflow Normal Available Width',
                value: '₹100',
              ),
              MetricItem(label: 'Normal', value: '₹200'),
            ],
          ),
        ),
      );

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);
      expect(find.byType(SummaryCard), findsOneWidget);

      final labelTextWidget = tester.widget<Text>(
        find.text(
          'Extremely Long Metric Label That Will Overflow Normal Available Width',
        ),
      );
      expect(labelTextWidget.maxLines, equals(1));
      expect(labelTextWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('handles very long value without layout overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            items: const [
              MetricItem(
                label: 'Total',
                value: '₹999,999,999,999,999.99 Extra Long Value',
              ),
            ],
          ),
        ),
      );

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);

      final valueTextWidget = tester.widget<Text>(
        find.text('₹999,999,999,999,999.99 Extra Long Value'),
      );
      expect(valueTextWidget.maxLines, equals(1));
      expect(valueTextWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets(
      'enforces one-or-two-metric constraint via constructor assertion',
      (tester) async {
        // Zero metrics should fail constructor assertion immediately
        expect(
          () => SummaryCard(items: const []),
          throwsA(isA<AssertionError>()),
        );

        // Three metrics should fail constructor assertion immediately
        expect(
          () => SummaryCard(
            items: const [
              MetricItem(label: '1', value: '1'),
              MetricItem(label: '2', value: '2'),
              MetricItem(label: '3', value: '3'),
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            onTap: () {
              tapped = true;
            },
            items: const [MetricItem(label: 'Tap Me', value: '100')],
          ),
        ),
      );

      await tester.tap(find.byType(SummaryCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
