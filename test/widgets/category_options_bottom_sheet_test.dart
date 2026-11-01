import 'package:expend_note/models/category.dart';
import 'package:expend_note/widgets/category_options_bottom_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCategory = Category(
    id: 1,
    name: 'Entertainment',
    icon: 'movie',
    color: 123456,
  );

  group('CategoryOptionsBottomSheet Widget Tests', () {
    testWidgets('renders category name, Edit, Merge, and Delete options', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showCategoryOptionsBottomSheet(
                      context: context,
                      category: testCategory,
                      transactionCount: 0,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.merge_type), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('Delete option is enabled when category has 0 transactions', (
      tester,
    ) async {
      CategoryOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedOption = await showCategoryOptionsBottomSheet(
                      context: context,
                      category: testCategory,
                      transactionCount: 0,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Delete ListTile should be enabled
      final deleteListTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, 'Delete'),
      );
      expect(deleteListTile.enabled, isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(CategoryOption.delete));
    });

    testWidgets(
      'Delete option is disabled when category has transactions (>0)',
      (tester) async {
        CategoryOption? selectedOption;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      selectedOption = await showCategoryOptionsBottomSheet(
                        context: context,
                        category: testCategory,
                        transactionCount: 5,
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // Delete ListTile should be disabled
        final deleteListTile = tester.widget<ListTile>(
          find.widgetWithText(ListTile, 'Delete'),
        );
        expect(deleteListTile.enabled, isFalse);

        // Attempting to tap disabled Delete
        await tester.tap(find.text('Delete'));
        await tester.pumpAndSettle();

        // Sheet should NOT close with delete option
        expect(selectedOption, isNull);
        expect(find.text('Entertainment'), findsOneWidget);
      },
    );

    testWidgets('selecting Edit returns CategoryOption.edit', (tester) async {
      CategoryOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedOption = await showCategoryOptionsBottomSheet(
                      context: context,
                      category: testCategory,
                      transactionCount: 0,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(CategoryOption.edit));
    });

    testWidgets('selecting Merge returns CategoryOption.merge', (tester) async {
      CategoryOption? selectedOption;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selectedOption = await showCategoryOptionsBottomSheet(
                      context: context,
                      category: testCategory,
                      transactionCount: 0,
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Merge'));
      await tester.pumpAndSettle();

      expect(selectedOption, equals(CategoryOption.merge));
    });
  });
}
