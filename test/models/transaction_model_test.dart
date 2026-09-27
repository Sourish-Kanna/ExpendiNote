import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/models/transaction.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  group('Transaction Model Tests', () {
    test('toMap converts Transaction to valid DB column map', () {
      final date = DateTime(2025, 3, 1, 10, 30);
      final createdAt = DateTime(2025, 3, 1, 10, 31);
      final tx = Transaction(
        id: 10,
        title: 'Lunch',
        amount: 250.50,
        date: date,
        categoryId: 1,
        description: 'Pizza with friends',
        includeInSpendingAnalysis: true,
        createdAt: createdAt,
      );

      final map = tx.toMap();

      expect(map[DbCols.id], equals(10));
      expect(map[DbCols.title], equals('Lunch'));
      expect(map[DbCols.amount], equals(250.50));
      expect(map[DbCols.date], equals(date.toIso8601String()));
      expect(map[DbCols.categoryId], equals(1));
      expect(map[DbCols.description], equals('Pizza with friends'));
      expect(map[DbCols.includeInSpendingAnalysis], equals(1));
      expect(map[DbCols.createdAt], equals(createdAt.toIso8601String()));
    });

    test('fromMap parses map with joined category details correctly', () {
      final dateStr = DateTime(2025, 2, 28, 18, 0).toIso8601String();
      final map = {
        DbCols.id: 15,
        DbCols.title: 'Movie Ticket',
        DbCols.amount: '300',
        DbCols.date: dateStr,
        DbCols.categoryId: 5,
        'categoryName': 'Entertainment',
        'categoryIcon': 'movie',
        'categoryColor': 9999,
        DbCols.description: 'IMAX',
        DbCols.includeInSpendingAnalysis: 1,
        DbCols.createdAt: dateStr,
      };

      final tx = Transaction.fromMap(map);

      expect(tx.id, equals(15));
      expect(tx.title, equals('Movie Ticket'));
      expect(tx.amount, equals(300.0));
      expect(tx.date.toIso8601String(), equals(dateStr));
      expect(tx.categoryId, equals(5));
      expect(tx.categoryName, equals('Entertainment'));
      expect(tx.categoryIcon, equals('movie'));
      expect(tx.categoryColor, equals(9999));
      expect(tx.description, equals('IMAX'));
      expect(tx.includeInSpendingAnalysis, isTrue);
    });

    test('fromMap handles null and missing fields gracefully', () {
      final map = <String, dynamic>{
        DbCols.title: 'Coffee',
        DbCols.amount: 50.0,
      };

      final tx = Transaction.fromMap(map);

      expect(tx.id, isNull);
      expect(tx.title, equals('Coffee'));
      expect(tx.amount, equals(50.0));
      expect(tx.categoryId, isNull);
      expect(tx.categoryName, isNull);
      expect(tx.description, isNull);
      expect(tx.includeInSpendingAnalysis, isTrue);
      expect(tx.date, isA<DateTime>());
      expect(tx.createdAt, isA<DateTime>());
    });

    test('copyWith produces updated transaction instance', () {
      final date = DateTime(2025, 1, 1);
      final tx = Transaction(
        id: 1,
        title: 'Taxi',
        amount: 150.0,
        date: date,
        categoryId: 3,
        includeInSpendingAnalysis: true,
      );

      final updated = tx.copyWith(
        amount: 180.0,
        description: 'Airport ride',
        includeInSpendingAnalysis: false,
      );

      expect(updated.id, equals(1));
      expect(updated.title, equals('Taxi'));
      expect(updated.amount, equals(180.0));
      expect(updated.description, equals('Airport ride'));
      expect(updated.includeInSpendingAnalysis, isFalse);
    });

    test('Equality and hashCode evaluate all fields', () {
      final date = DateTime(2025, 3, 10);
      final created = DateTime(2025, 3, 10);

      final tx1 = Transaction(
        id: 1,
        title: 'Groceries',
        amount: 1000.0,
        date: date,
        categoryId: 2,
        createdAt: created,
      );

      final tx2 = Transaction(
        id: 1,
        title: 'Groceries',
        amount: 1000.0,
        date: date,
        categoryId: 2,
        createdAt: created,
      );

      final tx3 = tx1.copyWith(amount: 1200.0);

      expect(tx1, equals(tx2));
      expect(tx1.hashCode, equals(tx2.hashCode));
      expect(tx1 == tx3, isFalse);
    });
  });
}
