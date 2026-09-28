import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expend_note/utils/color_utils.dart';

void main() {
  group('ColorUtils Tests', () {
    test('getAvailableColors returns predefined list of colors', () {
      final colors = ColorUtils.getAvailableColors();
      expect(colors, isNotEmpty);
      expect(colors, contains(Colors.purple));
      expect(colors, contains(Colors.teal));
    });

    test('fromInt returns correct Color or fallback color for null', () {
      const targetColor = Colors.blue;
      final intVal = ColorUtils.colorToInt(targetColor);

      final colorResult = ColorUtils.fromInt(intVal);
      expect(colorResult.toARGB32(), equals(targetColor.toARGB32()));

      final fallback = ColorUtils.fromInt(null);
      expect(fallback, equals(ColorUtils.colors[5]));
    });

    test('colorToInt serializes Color to ARGB32 integer', () {
      const color = Color(0xFF123456);
      final intVal = ColorUtils.colorToInt(color);
      expect(intVal, equals(0xFF123456));
    });
  });
}
