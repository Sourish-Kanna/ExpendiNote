import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/models/spending.dart';

void main() {
  group('Spending Model Tests', () {
    test('Spending.toMap() should return a valid map', () {
      final date = DateTime.now();
      final spending = Spending(
        id: 1,
        title: 'Lunch',
        amount: 15.5,
        date: date,
        category: 'Food',
        description: 'Tacos',
      );

      final map = spending.toMap();

      expect(map['id'], 1);
      expect(map['title'], 'Lunch');
      expect(map['amount'], 15.5);
      expect(map['date'], date.toIso8601String());
      expect(map['category'], 'Food');
      expect(map['description'], 'Tacos');
    });

    test('Spending.fromMap() should return a valid Spending object', () {
      final date = DateTime.now();
      final map = {
        'id': 2,
        'title': 'Bus',
        'amount': 2.5,
        'date': date.toIso8601String(),
        'category': 'Transport',
        'description': null,
      };

      final spending = Spending.fromMap(map);

      expect(spending.id, 2);
      expect(spending.title, 'Bus');
      expect(spending.amount, 2.5);
      expect(spending.date.toIso8601String(), date.toIso8601String());
      expect(spending.category, 'Transport');
      expect(spending.description, null);
    });
  });
}
