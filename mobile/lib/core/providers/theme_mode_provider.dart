import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference { light, dark }

class ThemeModeNotifier extends Notifier<AppThemePreference> {
  static const _key = 'app_theme_mode';

  @override
  AppThemePreference build() {
    Future.microtask(_loadStored);
    return AppThemePreference.light;
  }

  Future<void> _loadStored() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    if (stored == 'dark' && state != AppThemePreference.dark) {
      state = AppThemePreference.dark;
    }
  }

  ThemeMode get materialMode =>
      state == AppThemePreference.dark ? ThemeMode.dark : ThemeMode.light;

  Future<void> toggle() async {
    state = state == AppThemePreference.light
        ? AppThemePreference.dark
        : AppThemePreference.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      state == AppThemePreference.dark ? 'dark' : 'light',
    );
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, AppThemePreference>(
  ThemeModeNotifier.new,
);
