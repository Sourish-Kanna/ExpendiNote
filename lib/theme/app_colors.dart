import 'package:flutter/material.dart';

enum AppThemeColor {
  blue('Blue', Color(0xFF005AC1)),
  green('Green', Color(0xFF006D39)),
  purple('Purple', Color(0xFF7D00A5)),
  orange('Orange', Color(0xFF8E4E00));

  final String name;
  final Color seed;

  const AppThemeColor(this.name, this.seed);

  static AppThemeColor fromName(String? name) {
    return AppThemeColor.values.firstWhere(
      (c) => c.name == name,
      orElse: () => AppThemeColor.blue,
    );
  }
}
