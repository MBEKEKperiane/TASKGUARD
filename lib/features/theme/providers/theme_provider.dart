import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, pink }

extension AppThemeModeX on AppThemeMode {
  /// Maps to Flutter's [ThemeMode]. Pink Precision shares the light theme.
  ThemeMode get flutterMode =>
      this == AppThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
}

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier(super.initial);

  static const _key = 'app_theme_mode';

  Future<void> set(AppThemeMode mode) async {
    if (!mounted) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }
}

/// Reads the persisted theme synchronously before [runApp] in main.dart
/// and overrides this provider so there is no first-frame flicker.
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (_) => ThemeNotifier(AppThemeMode.light),
);
