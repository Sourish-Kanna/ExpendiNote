import 'package:flutter/material.dart';

enum AppThemeColor {
  blue('Blue', Colors.blue),
  green('Green', Colors.teal),
  purple('Purple', Colors.deepPurple),
  orange('Orange', Colors.deepOrange);

  final String name;
  final Color seed;

  const AppThemeColor(this.name, this.seed);

  static AppThemeColor fromName(String? name) {
    return AppThemeColor.values.firstWhere(
      (c) => c.name == name,
      orElse: () => AppThemeColor.green,
    );
  }
}
