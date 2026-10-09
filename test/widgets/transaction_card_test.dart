import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/widgets/transaction_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTransaction = Transaction(
    id: 1,
    title: 'Starbucks Coffee',
    amount: 250.0,
    date: DateTime(2025, 3, 10, 14, 30),
    categoryId: 1,
    categoryName: 'Food',
    categoryIcon: 'restaurant',
    categoryColor: 0xFF2196F3,
    includeInSpendingAnalysis: true,
  );

  group('TransactionCard Widget Tests', () {
    testWidgets('renders transaction details correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TransactionCard(transaction: testTransaction)),
        ),
      );

      expect(find.text('Starbucks Coffee'), findsOneWidget);
      expect(find.text('₹250'), findsOneWidget);
      expect(find.text('Food • 10/3 • 02:30 PM'), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('respects custom subtitle and amountText overrides', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: testTransaction,
              subtitle: 'Custom Subtitle',
              amountText: '₹250.00',
            ),
          ),
        ),
      );

      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.text('₹250.00'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: testTransaction,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Starbucks Coffee'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('triggers onLongPress callback when long pressed', (
      tester,
    ) async {
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionCard(
              transaction: testTransaction,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Starbucks Coffee'));
      await tester.pump();

      expect(longPressed, isTrue);
    });
  });
}
