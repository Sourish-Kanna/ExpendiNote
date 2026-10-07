import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/models/category.dart';
import 'package:expend_note/constants/database_constants.dart';

void main() {
  group('Category Model Tests', () {
    test('toMap converts Category to valid DB column map', () {
      final now = DateTime.now();
      final category = Category(
        id: 1,
        name: 'Food',
        icon: 'restaurant',
        color: 4282339765,
        isPinned: true,
        isArchived: false,
        includeInSpendingAnalysis: true,
        createdAt: now,
      );

      final map = category.toMap();

      expect(map[DbCols.id], equals(1));
      expect(map[DbCols.name], equals('Food'));
      expect(map[DbCols.icon], equals('restaurant'));
      expect(map[DbCols.color], equals(4282339765));
      expect(map[DbCols.isPinned], equals(1));
      expect(map[DbCols.isArchived], equals(0));
      expect(map[DbCols.includeInSpendingAnalysis], equals(1));
      expect(map[DbCols.createdAt], equals(now.toIso8601String()));
    });

    test('fromMap constructs Category correctly from DB row map', () {
      final nowStr = DateTime.now().toIso8601String();
      final map = {
        DbCols.id: 2,
        DbCols.name: 'Investment',
        DbCols.icon: 'trending_up',
        DbCols.color: 123456,
        DbCols.isPinned: 0,
        DbCols.isArchived: 1,
        DbCols.includeInSpendingAnalysis: 0,
        DbCols.createdAt: nowStr,
      };

      final category = Category.fromMap(map);

      expect(category.id, equals(2));
      expect(category.name, equals('Investment'));
      expect(category.icon, equals('trending_up'));
      expect(category.color, equals(123456));
      expect(category.isPinned, isFalse);
      expect(category.isArchived, isTrue);
      expect(category.includeInSpendingAnalysis, isFalse);
      expect(category.createdAt.toIso8601String(), equals(nowStr));
    });

    test('fromMap handles null and missing optional fields with defaults', () {
      final map = <String, dynamic>{DbCols.name: 'Others'};

      final category = Category.fromMap(map);

      expect(category.id, isNull);
      expect(category.name, equals('Others'));
      expect(category.icon, isNull);
      expect(category.color, isNull);
      expect(category.isPinned, isFalse);
      expect(category.isArchived, isFalse);
      expect(category.includeInSpendingAnalysis, isTrue);
      expect(category.createdAt, isA<DateTime>());
    });

    test('copyWith updates specified fields while keeping original values', () {
      final category = Category(
        id: 1,
        name: 'Bills',
        icon: 'home',
        color: 111,
        isPinned: false,
        isArchived: false,
        includeInSpendingAnalysis: true,
      );

      final updated = category.copyWith(name: 'Utilities', isPinned: true);

      expect(updated.id, equals(1));
      expect(updated.name, equals('Utilities'));
      expect(updated.icon, equals('home'));
      expect(updated.color, equals(111));
      expect(updated.isPinned, isTrue);
      expect(updated.isArchived, isFalse);
      expect(updated.includeInSpendingAnalysis, isTrue);
    });

    test('Equality and hashCode work correctly', () {
      final now = DateTime.now();
      final cat1 = Category(
        id: 5,
        name: 'Shopping',
        icon: 'shopping_bag',
        color: 222,
        isPinned: true,
        isArchived: false,
        includeInSpendingAnalysis: true,
        createdAt: now,
      );

      final cat2 = Category(
        id: 5,
        name: 'Shopping',
        icon: 'shopping_bag',
        color: 222,
        isPinned: true,
        isArchived: false,
        includeInSpendingAnalysis: true,
        createdAt: now,
      );

      final cat3 = Category(id: 5, name: 'Shopping Different', createdAt: now);

      expect(cat1, equals(cat2));
      expect(cat1.hashCode, equals(cat2.hashCode));
      expect(cat1 == cat3, isFalse);
    });
  });
}
