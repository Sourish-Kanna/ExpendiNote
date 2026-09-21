import 'package:material_ui/material_ui.dart';

class IconUtils {
  static List<IconData> iconsLiist = [
    Icons.category,
    Icons.restaurant,
    Icons.shopping_bag,
    Icons.movie,
    Icons.medical_services,
    Icons.school,
    Icons.home,
    Icons.trending_up,
    Icons.commute,
  ];

  static IconData fromString(String? iconString) {
    if (iconString == null || iconString.isEmpty) return Icons.category;
    try {
      final codePoint = int.parse(iconString);
      // ignore: non_const_argument_for_const_parameter
      return IconData(codePoint, fontFamily: 'MaterialIcons');
    } catch (e) {
      return Icons.category;
    }
  }

  static String iconToString(IconData icon) {
    return icon.codePoint.toString();
  }

  static List<IconData> getAvailableIcons() {
    return iconsLiist;
  }
}
