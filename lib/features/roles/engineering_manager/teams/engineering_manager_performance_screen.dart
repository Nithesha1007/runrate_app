import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_shared.dart';
import 'engineering_manager_teams_cubit.dart';

/// Team Performance — Sprint completion %, On-time delivery %,
/// AI-assisted work %, Productivity score, each as a compact progress row.
/// Linked from the hero card's "View Team Analytics" CTA and from the
/// "Team Report" quick action.
class EngineeringManagerPerformanceScreen extends StatelessWidget {
  const EngineeringManagerPerformanceScreen({super.key, required this.overview});

  final EngineeringTeamOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    final rows = <(String, int, IconData)>[
      ('Sprint completion', overview.sprintVelocityPercent.clamp(0, 100), Icons.speed_rounded),
      ('On-time delivery', (overview.healthBreakdown.isNotEmpty ? overview.healthBreakdown[0].score : 0),
          Icons.event_available_rounded),
      ('AI-assisted work', overview.avgAiAdoptionPercent, Icons.smart_toy_outlined),
      ('Productivity score', overview.productivityScore, Icons.trending_up_rounded),
    ];

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            _ScreenHeader(title: 'Team Performance', subtitle: overview.teamName, colors: colors),
            const SizedBox(height: AppSpacing.lg),
            for (var i = 0; i < rows.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == rows.length - 1 ? 0 : AppSpacing.md),
                child: StaggeredEntrance(
                  index: i,
                  child: _ProgressRow(label: rows[i].$1, percent: rows[i].$2, icon: rows[i].$3, colors: colors),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.label, required this.percent, required this.icon, required this.colors});

  final String label;
  final int percent;
  final IconData icon;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      colors: colors,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.body(colors.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: percent / 100),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v,
                      minHeight: 8,
                      backgroundColor: colors.border,
                      valueColor: AlwaysStoppedAnimation(colors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text('$percent%', style: AppTypography.h3(colors.textPrimary)),
        ],
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title, required this.subtitle, required this.colors});

  final String title;
  final String subtitle;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleOnTap(
          onTap: () => Navigator.of(context).maybePop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.arrow_back_rounded, color: colors.textSecondary, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTypography.h2(colors.textPrimary)),
            Text(subtitle, style: AppTypography.caption(colors.textSecondary)),
          ],
        ),
      ],
    );
  }
}