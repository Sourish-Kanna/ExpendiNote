import 'package:flutter/material.dart';

class ColorUtils {
  static Color fromInt(int? value) {
    if (value == null) return Colors.blue;
    return Color(value);
  }

  static int colorToInt(Color color) {
    return color.value;
  }

  static List<Color> getAvailableColors() {
    return [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];
  }
}
