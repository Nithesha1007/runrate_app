import 'package:flutter/material.dart';
import 'app_colors_data.dart';

/// Dark-mode counterpart to [AppColors]. Brand accents stay identical;
/// only background/surface/text tokens are adapted for a dark canvas.
class AppColorsDark {
  static const Color primary = Color(0xFF6D5BFF);
  static const Color primaryLight = Color(0xFF23204A);
  static const Color secondary = Color(0xFF4B8BFF);
  static const Color background = Color(0xFF0B0F1A);
  static const Color surface = Color(0xFF151A26);
  static const Color surfaceElevated = Color(0xFF1B2130);
  static const Color border = Color(0xFF262E3F);
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const AppColorsData data = AppColorsData(
    primary: primary,
    primaryLight: primaryLight,
    secondary: secondary,
    background: background,
    surface: surface,
    surfaceElevated: surfaceElevated,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    success: success,
    warning: warning,
    danger: danger,
    info: info,
  );
}
