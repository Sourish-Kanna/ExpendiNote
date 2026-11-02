import 'package:material_ui/material_ui.dart';

class IconUtils {
  static const IconData defaultIcon = Icons.category;
  static const IconData restaurantIcon = Icons.restaurant;
  static const IconData shoppingBagIcon = Icons.shopping_bag;
  static const IconData movieIcon = Icons.movie;
  static const IconData medicalServicesIcon = Icons.medical_services;
  static const IconData schoolIcon = Icons.school;
  static const IconData homeIcon = Icons.home;
  static const IconData trendingUpIcon = Icons.trending_up;
  static const IconData commuteIcon = Icons.commute;

  static const List<IconData> iconsList = [
    defaultIcon,
    restaurantIcon,
    shoppingBagIcon,
    movieIcon,
    medicalServicesIcon,
    schoolIcon,
    homeIcon,
    trendingUpIcon,
    commuteIcon,
  ];

  static IconData fromString(String? iconString) {
    switch (iconString) {
      case 'category':
        return Icons.category;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'movie':
        return Icons.movie;
      case 'medical_services':
        return Icons.medical_services;
      case 'school':
        return Icons.school;
      case 'home':
        return Icons.home;
      case 'trending_up':
        return Icons.trending_up;
      case 'commute':
        return Icons.commute;
      default:
        return Icons.category;
    }
  }

  static String iconToString(IconData icon) {
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.shopping_bag) return 'shopping_bag';
    if (icon == Icons.movie) return 'movie';
    if (icon == Icons.medical_services) return 'medical_services';
    if (icon == Icons.school) return 'school';
    if (icon == Icons.home) return 'home';
    if (icon == Icons.trending_up) return 'trending_up';
    if (icon == Icons.commute) return 'commute';
    return 'category';
  }

  static List<IconData> getAvailableIcons() {
    return iconsList;
  }
}
