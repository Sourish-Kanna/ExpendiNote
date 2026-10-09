import 'package:expend_note/models/category.dart';
import 'package:expend_note/widgets/category_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testCategory = Category(
    id: 1,
    name: 'Groceries',
    icon: 'shopping_bag',
    color: 0xFF4CAF50,
    isPinned: true,
  );

  group('CategoryCard Widget Tests', () {
    testWidgets('renders category details and pinned indicator correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: testCategory,
              transactionCount: 5,
              totalAmount: 1250.0,
            ),
          ),
        ),
      );

      expect(find.text('Groceries'), findsOneWidget);
      expect(find.text('5 transactions • ₹1250'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('hides pinned indicator when category is not pinned', (
      tester,
    ) async {
      final unpinnedCategory = Category(
        id: 2,
        name: 'Entertainment',
        icon: 'movie',
        color: 0xFF9C27B0,
        isPinned: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: unpinnedCategory,
              transactionCount: 0,
              totalAmount: 0.0,
            ),
          ),
        ),
      );

      expect(find.text('Entertainment'), findsOneWidget);
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('triggers onTap callback when tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryCard(
              category: testCategory,
              transactionCount: 1,
              totalAmount: 100.0,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Groceries'));
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
            body: CategoryCard(
              category: testCategory,
              transactionCount: 1,
              totalAmount: 100.0,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Groceries'));
      await tester.pump();

      expect(longPressed, isTrue);
    });
  });
}
