import 'package:flutter/material.dart';

class IconUtils {
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
    return [
      Icons.category,
      Icons.restaurant,
      Icons.directions_bus,
      Icons.shopping_bag,
      Icons.movie,
      Icons.medical_services,
      Icons.school,
      Icons.home,
      Icons.trending_up,
      Icons.payments,
      Icons.receipt,
      Icons.more_horiz,
      Icons.flight,
      Icons.fitness_center,
      Icons.games,
      Icons.pets,
      Icons.redeem,
      Icons.build,
      Icons.commute,
      Icons.work,
      Icons.computer,
      Icons.smartphone,
      Icons.watch,
      Icons.camera_alt,
      Icons.music_note,
      Icons.brush,
      Icons.coffee,
      Icons.fastfood,
      Icons.local_bar,
      Icons.local_gas_station,
      Icons.local_grocery_store,
      Icons.local_hospital,
      Icons.local_library,
      Icons.local_mall,
      Icons.local_pharmacy,
      Icons.local_pizza,
      Icons.local_shipping,
      Icons.local_taxi,
    ];
  }
}
