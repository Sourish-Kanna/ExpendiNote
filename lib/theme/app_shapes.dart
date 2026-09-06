import 'package:flutter/material.dart';

class AppShapes {
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusExtraLarge = 28.0;

  static BorderRadius get smallRadius => BorderRadius.circular(radiusSmall);
  static BorderRadius get mediumRadius => BorderRadius.circular(radiusMedium);
  static BorderRadius get largeRadius => BorderRadius.circular(radiusLarge);
  static BorderRadius get extraLargeRadius =>
      BorderRadius.circular(radiusExtraLarge);

  static RoundedRectangleBorder get smallShape =>
      RoundedRectangleBorder(borderRadius: smallRadius);
  static RoundedRectangleBorder get mediumShape =>
      RoundedRectangleBorder(borderRadius: mediumRadius);
  static RoundedRectangleBorder get largeShape =>
      RoundedRectangleBorder(borderRadius: largeRadius);
  static RoundedRectangleBorder get extraLargeShape =>
      RoundedRectangleBorder(borderRadius: extraLargeRadius);
}
