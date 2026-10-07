import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:expend_note/theme/app_theme.dart';
import 'package:expend_note/theme/app_colors.dart';

void main() {
  group('AppTheme Tests', () {
    test(
      'buildTheme generates valid Material 3 ThemeData from ColorScheme',
      () {
        final scheme = ColorScheme.fromSeed(
          seedColor: AppThemeColor.blue.seed,
          brightness: Brightness.light,
        );

        final theme = AppTheme.buildTheme(scheme);

        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme.primary, equals(scheme.primary));
        expect(theme.appBarTheme.centerTitle, isTrue);
        expect(theme.cardTheme.elevation, equals(0));
        expect(
          theme.floatingActionButtonTheme.shape,
          equals(const CircleBorder()),
        );
      },
    );

    test(
      'generates valid light and dark ThemeData for all 4 AppThemeColors',
      () {
        for (final colorPreset in AppThemeColor.values) {
          // Light Scheme
          final lightScheme = ColorScheme.fromSeed(
            seedColor: colorPreset.seed,
            brightness: Brightness.light,
          );
          final lightTheme = AppTheme.buildTheme(lightScheme);
          expect(lightTheme.colorScheme.brightness, equals(Brightness.light));
          expect(
            lightTheme.scaffoldBackgroundColor,
            equals(lightScheme.surface),
          );

          // Dark Scheme
          final darkScheme = ColorScheme.fromSeed(
            seedColor: colorPreset.seed,
            brightness: Brightness.dark,
          );
          final darkTheme = AppTheme.buildTheme(darkScheme);
          expect(darkTheme.colorScheme.brightness, equals(Brightness.dark));
          expect(darkTheme.scaffoldBackgroundColor, equals(darkScheme.surface));
        }
      },
    );
  });
}
