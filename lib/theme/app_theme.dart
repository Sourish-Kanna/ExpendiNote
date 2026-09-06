import 'package:flutter/material.dart';

import 'app_shapes.dart';

class AppTheme {
  static const Color fallbackSeed = Colors.teal;

  static ThemeData buildTheme(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      typography: Typography.material2021(),

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
      ),

      scaffoldBackgroundColor: scheme.surface,

      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.mediumRadius,
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: const CircleBorder(),
        backgroundColor: scheme.primaryContainer,
        foregroundColor: scheme.onPrimaryContainer,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: AppShapes.mediumShape,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: AppShapes.mediumShape),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: AppShapes.mediumShape),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: AppShapes.mediumShape),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        border: OutlineInputBorder(borderRadius: AppShapes.mediumRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.mediumRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.mediumRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),

      dialogTheme: DialogThemeData(shape: AppShapes.largeShape),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.radiusExtraLarge),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        backgroundColor: scheme.surface,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w500,
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: AppShapes.mediumShape,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
      ),

      listTileTheme: ListTileThemeData(shape: AppShapes.mediumShape),

      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),

      // Typography harmonization
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontWeight: FontWeight.bold),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
