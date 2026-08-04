import 'package:flutter/material.dart';

/// Color token container used across both light and dark color palettes.
class AppColorsData {
  final Color primary;
  final Color primaryLight;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;

  const AppColorsData({
    required this.primary,
    required this.primaryLight,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  static const AppColorsData light = AppColorsData(
    primary: Color(0xFF6D5BFF),
    primaryLight: Color(0xFFEEF0FF),
    secondary: Color(0xFF4B8BFF),
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFF8FAFC),
    surfaceElevated: Color(0xFFFFFFFF),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF3B82F6),
  );
}
