import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';
import 'app_colors.dart';

class AppThemeController extends ChangeNotifier {
  final SettingsRepository _settingsRepository;

  ThemeMode _themeMode = ThemeMode.system;
  bool _customThemeEnabled = false;
  AppThemeColor _selectedThemeColor = AppThemeColor.blue;

  AppThemeController({SettingsRepository? settingsRepository})
    : _settingsRepository = settingsRepository ?? SettingsRepository() {
    _loadSettings();
  }

  ThemeMode get themeMode => _themeMode;
  bool get customThemeEnabled => _customThemeEnabled;
  AppThemeColor get selectedThemeColor => _selectedThemeColor;

  Future<void> _loadSettings() async {
    final modeStr = await _settingsRepository.get('theme_mode');
    if (modeStr != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (m) => m.name == modeStr,
        orElse: () => ThemeMode.system,
      );
    }

    final customThemePref = await _settingsRepository.get(
      'custom_theme_enabled',
    );
    if (customThemePref == null) {
      // If no preference is saved, check if device supports dynamic colors
      final corePalette = await DynamicColorPlugin.getCorePalette();
      // If no dynamic color support, default to enabling custom theme
      _customThemeEnabled = (corePalette == null);
      // Persist the default choice
      await _settingsRepository.setBool(
        'custom_theme_enabled',
        _customThemeEnabled,
      );
    } else {
      _customThemeEnabled = customThemePref.toLowerCase() == 'true';
    }

    final colorName = await _settingsRepository.get('selected_theme_color');
    _selectedThemeColor = AppThemeColor.fromName(colorName);

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _settingsRepository.set('theme_mode', mode.name);
  }

  Future<void> setCustomThemeEnabled(bool enabled) async {
    if (_customThemeEnabled == enabled) return;
    _customThemeEnabled = enabled;
    notifyListeners();
    await _settingsRepository.setBool('custom_theme_enabled', enabled);
  }

  Future<void> setSelectedThemeColor(AppThemeColor color) async {
    if (_selectedThemeColor == color) return;
    _selectedThemeColor = color;
    notifyListeners();
    await _settingsRepository.set('selected_theme_color', color.name);
  }
}
