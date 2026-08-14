import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_colors_dark.dart';

/// Extension methods on [BuildContext] for easy access to theme colors.
extension ThemeExtension on BuildContext {
  /// Get the background color for the current theme.
  Color get backgroundColor {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.background
        : AppColors.background;
  }

  /// Get the border color for the current theme.
  Color get borderColor {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.border
        : AppColors.border;
  }

  /// Get the card/surface color for the current theme.
  Color get cardColor {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.surfaceElevated
        : AppColors.surfaceElevated;
  }

  /// Get the primary text color for the current theme.
  Color get textPrimary {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.textPrimary
        : AppColors.textPrimary;
  }

  /// Get the secondary text color for the current theme.
  Color get textSecondary {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.textSecondary
        : AppColors.textSecondary;
  }

  /// Get the surface/card elevated color for the current theme.
  Color get surfaceColor {
    return Theme.of(this).brightness == Brightness.dark
        ? AppColorsDark.surface
        : AppColors.surface;
  }

  /// Get the primary brand color.
  Color get primaryColor {
    return Theme.of(this).primaryColor;
  }
}
