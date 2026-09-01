import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/role_enum.dart';

/// Persists and broadcasts the app's light/dark preference.
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit({ThemeMode initialMode = ThemeMode.light}) : super(initialMode);

  RoleEnum? _activeRole;
  int _loadVersion = 0;

  Future<void> setRole(RoleEnum role) async {
    if (_activeRole == role) return;

    _activeRole = role;
    final loadVersion = ++_loadVersion;
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyFor(role));
    if (loadVersion != _loadVersion || _activeRole != role) return;

    final loadedMode =
        stored == null ? ThemeMode.light : _themeModeFromString(stored);
    if (loadedMode != state) emit(loadedMode);
  }

  void toggle() {
    final nextMode =
        state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(nextMode);
    _saveThemeModeForActiveRole(nextMode);
  }

  void setMode(ThemeMode mode) {
    if (mode == state) return;
    emit(mode);
    _saveThemeModeForActiveRole(mode);
  }

  /// Kept as a compatibility helper for callers that need a startup default.
  static Future<ThemeMode> loadSavedThemeMode() async {
    return ThemeMode.light;
  }

  String _keyFor(RoleEnum role) {
    switch (role) {
      case RoleEnum.ceo:
        return 'theme_ceo';
      case RoleEnum.cfo:
        return 'theme_cfo';
      case RoleEnum.engineeringManager:
        return 'theme_engineering_manager';
      case RoleEnum.employee:
        return 'theme_employee';
      case RoleEnum.orgAdmin:
        return 'theme_admin';
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

  Future<void> _saveThemeModeForActiveRole(ThemeMode mode) async {
    final role = _activeRole;
    if (role == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(role), _themeModeToString(mode));
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
}
