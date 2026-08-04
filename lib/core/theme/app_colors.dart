import 'package:flutter/material.dart';
import 'app_colors_data.dart';
import 'app_colors_dark.dart';

/// Light-mode brand color tokens. Never hardcode hex values outside this file.
class AppColors {
  static const Color primary = Color(0xFF6D5BFF);
  static const Color primaryLight = Color(0xFFEEF0FF);
  static const Color secondary = Color(0xFF4B8BFF);
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static AppColorsData of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? AppColorsDark.data
        : AppColorsData.light;
  }
}

extension AppColorsResolver on BuildContext {
  AppColorsData get appColors => AppColors.of(this);
}
