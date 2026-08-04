import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';
import 'app_typography.dart';

/// Builds the light/dark [ThemeData] used throughout the app.
class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      cardColor: AppColors.surfaceElevated,
      dividerColor: AppColors.border,
      textTheme: TextTheme(
        displayLarge: AppTypography.display(AppColors.textPrimary),
        headlineLarge: AppTypography.h1(AppColors.textPrimary),
        headlineMedium: AppTypography.h2(AppColors.textPrimary),
        headlineSmall: AppTypography.h3(AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge(AppColors.textPrimary),
        bodyMedium: AppTypography.body(AppColors.textSecondary),
        labelSmall: AppTypography.label(AppColors.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColorsDark.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        secondary: AppColorsDark.secondary,
        error: AppColorsDark.danger,
        surface: AppColorsDark.surface,
      ),
      cardColor: AppColorsDark.surfaceElevated,
      dividerColor: AppColorsDark.border,
      textTheme: TextTheme(
        displayLarge: AppTypography.display(AppColorsDark.textPrimary),
        headlineLarge: AppTypography.h1(AppColorsDark.textPrimary),
        headlineMedium: AppTypography.h2(AppColorsDark.textPrimary),
        headlineSmall: AppTypography.h3(AppColorsDark.textPrimary),
        bodyLarge: AppTypography.bodyLarge(AppColorsDark.textPrimary),
        bodyMedium: AppTypography.body(AppColorsDark.textSecondary),
        labelSmall: AppTypography.label(AppColorsDark.textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
