import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/utils/icon_utils.dart';

void main() {
  group('IconUtils Tests', () {
    test('getAvailableIcons returns predefined list of icons', () {
      final icons = IconUtils.getAvailableIcons();
      expect(icons, isNotEmpty);
      expect(icons, contains(Icons.restaurant));
      expect(icons, contains(Icons.category));
    });

    test('fromString converts valid icon strings to IconData', () {
      expect(IconUtils.fromString('restaurant'), equals(Icons.restaurant));
      expect(IconUtils.fromString('shopping_bag'), equals(Icons.shopping_bag));
      expect(IconUtils.fromString('movie'), equals(Icons.movie));
      expect(
        IconUtils.fromString('medical_services'),
        equals(Icons.medical_services),
      );
      expect(IconUtils.fromString('school'), equals(Icons.school));
      expect(IconUtils.fromString('home'), equals(Icons.home));
      expect(IconUtils.fromString('trending_up'), equals(Icons.trending_up));
      expect(IconUtils.fromString('commute'), equals(Icons.commute));
    });

    test(
      'fromString returns default Icons.category for null or unknown strings',
      () {
        expect(IconUtils.fromString(null), equals(Icons.category));
        expect(IconUtils.fromString('unknown_icon'), equals(Icons.category));
      },
    );

    test('iconToString converts IconData to string key', () {
      expect(IconUtils.iconToString(Icons.restaurant), equals('restaurant'));
      expect(
        IconUtils.iconToString(Icons.shopping_bag),
        equals('shopping_bag'),
      );
      expect(IconUtils.iconToString(Icons.movie), equals('movie'));
      expect(
        IconUtils.iconToString(Icons.medical_services),
        equals('medical_services'),
      );
      expect(IconUtils.iconToString(Icons.school), equals('school'));
      expect(IconUtils.iconToString(Icons.home), equals('home'));
      expect(IconUtils.iconToString(Icons.trending_up), equals('trending_up'));
      expect(IconUtils.iconToString(Icons.commute), equals('commute'));
      expect(IconUtils.iconToString(Icons.star), equals('category'));
    });
  });
}
