import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists and broadcasts the app's light/dark preference.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeMode initialMode = ThemeMode.light}) : super(initialMode) {
    _loadThemeMode();
  }

  static const String _themeModeKey = 'theme_mode';

  void toggle() {
    final nextMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(nextMode);
    _saveThemeMode(nextMode);
  }

  void setMode(ThemeMode mode) {
    if (mode == state) return;
    emit(mode);
    _saveThemeMode(mode);
  }

  static Future<ThemeMode> loadSavedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored == null) return ThemeMode.light;
    return _themeModeFromStringStatic(stored);
  }

  static ThemeMode _themeModeFromStringStatic(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_themeModeKey);
    if (stored == null) return;

    final loadedMode = _themeModeFromString(stored);
    if (loadedMode != state) {
      emit(loadedMode);
    }
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeToString(mode));
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
