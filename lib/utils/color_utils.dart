import 'package:material_ui/material_ui.dart';

class ColorUtils {
  static const Color purpleColor = Colors.purple;
  static const Color deepPurpleColor = Colors.deepPurple;
  static const Color indigoColor = Colors.indigo;
  static const Color blueColor = Colors.blue;
  static const Color tealColor = Colors.teal;
  static const Color deepOrangeColor = Colors.deepOrange;
  static const Color blueGreyColor = Colors.blueGrey;

  static List<Color> colors = [
    purpleColor,
    deepPurpleColor,
    indigoColor,
    blueColor,
    tealColor,
    deepOrangeColor,
    blueGreyColor,
  ];

  static Color fromInt(int? value) {
    if (value == null) return deepOrangeColor;
    return Color(value);
  }

  static int colorToInt(Color color) {
    return color.toARGB32();
  }

  static List<Color> getAvailableColors() {
    return colors;
  }
}
