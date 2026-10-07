import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/models/settings.dart';

void main() {
  group('Setting Model Tests', () {
    test('toMap and fromMap convert Setting correctly', () {
      final setting = const Setting(key: 'theme_mode', value: 'dark');

      final map = setting.toMap();
      expect(map['key'], equals('theme_mode'));
      expect(map['value'], equals('dark'));

      final reconstructed = Setting.fromMap(map);
      expect(reconstructed, equals(setting));
    });

    test('Typed getters perform expected type conversions', () {
      final boolSetting = const Setting(
        key: 'custom_theme_enabled',
        value: 'true',
      );
      expect(boolSetting.boolValue, isTrue);

      final falseBoolSetting = const Setting(
        key: 'custom_theme_enabled',
        value: 'false',
      );
      expect(falseBoolSetting.boolValue, isFalse);

      final intSetting = const Setting(key: 'version', value: '5');
      expect(intSetting.intValue, equals(5));

      final doubleSetting = const Setting(key: 'threshold', value: '12.34');
      expect(doubleSetting.doubleValue, equals(12.34));

      final nullSetting = const Setting(key: 'missing', value: null);
      expect(nullSetting.boolValue, isFalse);
      expect(nullSetting.intValue, isNull);
      expect(nullSetting.doubleValue, isNull);
    });

    test('copyWith and equality work as intended', () {
      final s1 = const Setting(key: 'k1', value: 'v1');
      final s2 = s1.copyWith(value: 'v2');

      expect(s2.key, equals('k1'));
      expect(s2.value, equals('v2'));
      expect(s1 == s2, isFalse);

      final s3 = const Setting(key: 'k1', value: 'v1');
      expect(s1, equals(s3));
      expect(s1.hashCode, equals(s3.hashCode));
    });
  });
}
