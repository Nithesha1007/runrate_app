import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';

/// Common scaffold for every dedicated Engineering Manager · More
/// destination screen (Profile & Account, Notifications, Security &
/// Privacy, Team Reports, Budget & Forecast, AI Activity & Usage,
/// Policies & Approval Rules, Integrations, Approval Preferences,
/// About Runrate).
///
/// Gives every screen, for free:
/// - correct AppBar/header with automatic back navigation
/// - consistent theme (light/dark via existing AppColors.of(context))
/// - safe-area + scroll handling so nothing overflows on small screens
///
/// Each screen file only supplies its own `body`. This widget is not
/// itself a "new nav system" — it just wraps the same Scaffold/AppBar
/// pattern already used by the existing screens in this project.
class EmScreenScaffold extends StatelessWidget {
  const EmScreenScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.padded = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Set to false if the screen body manages its own padding/scrolling
  /// (e.g. a screen with its own ListView + sticky filter bar).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(title, style: AppTypography.h2(colors.textPrimary)),
        actions: actions,
      ),
      body: SafeArea(
        child: padded
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: body,
              )
            : body,
      ),
    );
  }
}

/// Temporary in-progress state for a screen whose full content hasn't
/// landed yet. Purely a build-order placeholder for this dev pass —
/// every screen using this gets replaced in place with real content
/// (charts, lists, forms, etc.) in the next iteration, per spec.
///
/// TODO(next pass): remove this widget from each screen file as its
/// real content is implemented.
class EmScreenInProgress extends StatelessWidget {
  const EmScreenInProgress({
    super.key,
    required this.icon,
    required this.description,
  });

  final IconData icon;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: colors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.body(colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
