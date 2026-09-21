import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/models/transaction.dart';

void main() {
  group('Issue 14 Models & Analysis Default Tests', () {
    test('Category default includeInSpendingAnalysis', () {
      final defaultCat = Category(name: 'Food');
      expect(defaultCat.includeInSpendingAnalysis, isTrue);

      final investmentCat = Category(
        name: 'Investment',
        includeInSpendingAnalysis: false,
      );
      expect(investmentCat.includeInSpendingAnalysis, isFalse);

      final map = investmentCat.toMap();
      expect(map['includeInSpendingAnalysis'], equals(0));

      final restored = Category.fromMap(map);
      expect(restored.includeInSpendingAnalysis, isFalse);
    });

    test('Transaction includeInSpendingAnalysis defaults and mapping', () {
      final txDefault = Transaction(
        title: 'Lunch',
        amount: 15.0,
        date: DateTime.now(),
      );
      expect(txDefault.includeInSpendingAnalysis, isTrue);

      final txExcluded = Transaction(
        title: 'Stock Purchase',
        amount: 500.0,
        date: DateTime.now(),
        includeInSpendingAnalysis: false,
      );
      expect(txExcluded.includeInSpendingAnalysis, isFalse);

      final map = txExcluded.toMap();
      expect(map['includeInSpendingAnalysis'], equals(0));

      final restored = Transaction.fromMap(map);
      expect(restored.includeInSpendingAnalysis, isFalse);
    });

    test('Calculation filtering logic', () {
      final txList = [
        Transaction(title: 'Groceries', amount: 50.0, date: DateTime.now(), includeInSpendingAnalysis: true),
        Transaction(title: 'ETF Investment', amount: 200.0, date: DateTime.now(), includeInSpendingAnalysis: false),
        Transaction(title: 'Coffee', amount: 5.0, date: DateTime.now(), includeInSpendingAnalysis: true),
      ];

      final totalSpending = txList
          .where((t) => t.includeInSpendingAnalysis)
          .fold(0.0, (sum, t) => sum + t.amount);

      expect(totalSpending, equals(55.0));
      expect(txList.length, equals(3));
    });
  });
}
