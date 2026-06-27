import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier(super.initial);

  static const key = 'app_language';

  Future<void> set(String languageCode) async {
    if (!mounted) return;
    state = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, languageCode);
  }
}

/// Reads the persisted language synchronously before runApp in main.dart
/// and overrides this provider so there is no first-frame flicker.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (_) => LocaleNotifier(const Locale('en')),
);
