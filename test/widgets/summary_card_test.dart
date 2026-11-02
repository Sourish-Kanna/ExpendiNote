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
    testWidgets('renders supplied single metric label and value correctly', (
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

    testWidgets(
      'renders multiple metrics (two) in side-by-side layout with divider',
      (tester) async {
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
      },
    );

    testWidgets('renders prominent layout correctly with single metric', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            prominent: true,
            items: const [MetricItem(label: 'Net Balance', value: '₹12,345')],
          ),
        ),
      );

      expect(find.text('Net Balance'), findsOneWidget);
      expect(find.text('₹12,345'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsNothing);

      final valueText = tester.widget<Text>(find.text('₹12,345'));
      expect(valueText.maxLines, equals(1));
      expect(valueText.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets(
      'enforces constructor assertions for item length and prominent layout',
      (tester) async {
        // Zero metrics fails constructor assertion
        expect(
          () => SummaryCard(items: const []),
          throwsA(isA<AssertionError>()),
        );

        // Three metrics fails constructor assertion
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

        // Prominent layout with multiple metrics fails constructor assertion
        expect(
          () => SummaryCard(
            prominent: true,
            items: const [
              MetricItem(label: '1', value: '1'),
              MetricItem(label: '2', value: '2'),
            ],
          ),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    testWidgets(
      'handles long label and value without layout overflow in non-prominent layout',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            SummaryCard(
              items: const [
                MetricItem(
                  label: 'Extremely Long Metric Label That May Overflow',
                  value: '₹999,999,999,999,999.99 Extra Long Value',
                ),
                MetricItem(label: 'Normal', value: '₹200'),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final labelWidget = tester.widget<Text>(
          find.text('Extremely Long Metric Label That May Overflow'),
        );
        expect(labelWidget.maxLines, equals(1));
        expect(labelWidget.overflow, equals(TextOverflow.ellipsis));

        final valueWidget = tester.widget<Text>(
          find.text('₹999,999,999,999,999.99 Extra Long Value'),
        );
        expect(valueWidget.maxLines, equals(1));
        expect(valueWidget.overflow, equals(TextOverflow.ellipsis));
      },
    );

    testWidgets(
      'handles long value with ellipsis without overflow in prominent layout',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            SummaryCard(
              prominent: true,
              items: const [
                MetricItem(
                  label: 'Very Long Prominent Metric Label Title',
                  value: '₹999,999,999,999,999.99 Extra Long Value',
                ),
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final valueWidget = tester.widget<Text>(
          find.text('₹999,999,999,999,999.99 Extra Long Value'),
        );
        expect(valueWidget.maxLines, equals(1));
        expect(valueWidget.overflow, equals(TextOverflow.ellipsis));
      },
    );

    testWidgets('triggers onTap callback when tapped when onTap is provided', (
      tester,
    ) async {
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

      expect(find.byType(InkWell), findsOneWidget);

      await tester.tap(find.byType(SummaryCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('renders without InkWell when onTap callback is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          SummaryCard(
            onTap: null,
            items: const [MetricItem(label: 'No Tap', value: '100')],
          ),
        ),
      );

      expect(find.byType(InkWell), findsNothing);

      await tester.tap(find.byType(SummaryCard));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'applies custom background and item text colors when provided',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            SummaryCard(
              backgroundColor: Colors.red,
              textColor: Colors.blue,
              items: const [
                MetricItem(
                  label: 'Custom Item',
                  value: '100',
                  color: Colors.green,
                ),
              ],
            ),
          ),
        );

        final cardWidget = tester.widget<Card>(find.byType(Card));
        expect(cardWidget.color, equals(Colors.red));

        final textWidget = tester.widget<Text>(find.text('Custom Item'));
        expect(textWidget.style?.color, equals(Colors.green));
      },
    );
  });
}
