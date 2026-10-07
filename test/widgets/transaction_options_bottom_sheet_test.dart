import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/widgets/transaction_options_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTransaction = Transaction(
    id: 1,
    title: 'Groceries',
    amount: 1500.0,
    date: DateTime(2025, 3, 10),
    categoryId: 1,
    includeInSpendingAnalysis: true,
  );

  group('TransactionOptionsBottomSheet Widget Tests', () {
    testWidgets('renders transaction title, Edit and Delete options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showTransactionOptionsBottomSheet(
                      context: context,
                      transaction: testTransaction,
                    );
                  },
                  child: const Text('Open Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('selecting Edit returns TransactionOption.edit', (
      tester,
    ) async {
      TransactionOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedOption = await showTransactionOptionsBottomSheet(
                      context: context,
                      transaction: testTransaction,
                    );
                  },
                  child: const Text('Open Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(TransactionOption.edit));
    });

    testWidgets('selecting Delete returns TransactionOption.delete', (
      tester,
    ) async {
      TransactionOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedOption = await showTransactionOptionsBottomSheet(
                      context: context,
                      transaction: testTransaction,
                    );
                  },
                  child: const Text('Open Bottom Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Bottom Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(TransactionOption.delete));
    });
  });
}
