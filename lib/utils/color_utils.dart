import 'package:material_ui/material_ui.dart';

class ColorUtils {
  static List<Color> colors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.deepOrange,
    Colors.blueGrey,
  ];

  static Color fromInt(int? value) {
    if (value == null) return colors[5];
    return Color(value);
  }

  static int colorToInt(Color color) {
    return color.toARGB32();
  }

  static List<Color> getAvailableColors() {
    return colors;
  }
}
