import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_shared.dart';
import 'engineering_manager_teams_cubit.dart';

/// Tool Detail — active users, adoption %, monthly spend, usage trend,
/// cost per active user, license utilization, unused-license count, a
/// "Recommended Action" callout, and a "Review Licenses →" CTA.
class EngineeringManagerToolDetailScreen extends StatelessWidget {
  const EngineeringManagerToolDetailScreen({super.key, required this.tool});

  final TeamToolUsage tool;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final trendUp = tool.trendPercent >= 0;
    final trendColor = trendUp ? colors.success : colors.danger;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tool.toolName, style: AppTypography.h2(colors.textPrimary)),
                      Text('Tool usage & licensing', style: AppTypography.caption(colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.secondary, colors.primary.withValues(alpha: 0.85)],
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedOnTrackRing(percent: tool.adoptionPercent, color: Colors.white),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${tool.adoptionPercent}% adoption', style: AppTypography.h3(Colors.white)),
                        const SizedBox(height: 4),
                        Text('${tool.activeUsers} of ${tool.totalUsers} team members active',
                            style: AppTypography.caption(Colors.white.withValues(alpha: 0.85))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              colors: colors,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Monthly spend',
                          valueWidget: CurrencyValue(value: tool.monthlySpend, style: AppTypography.h3(colors.textPrimary), iconColor: colors.textPrimary),
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          label: 'Cost / active user',
                          valueWidget:
                              CurrencyValue(value: tool.costPerActiveUser, style: AppTypography.h3(colors.textPrimary), iconColor: colors.textPrimary),
                          colors: colors,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Usage trend',
                          valueWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16, color: trendColor),
                              Text('${tool.trendPercent.abs().toStringAsFixed(1)}%', style: AppTypography.h3(trendColor)),
                            ],
                          ),
                          colors: colors,
                        ),
                      ),
                      Expanded(
                        child: _Stat(label: 'License utilization', value: '${tool.licenseUtilizationPercent.round()}%', colors: colors),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: _Stat(label: 'Seats purchased', value: '${tool.seats}', colors: colors)),
                      Expanded(child: _Stat(label: 'Unused licenses', value: '${tool.unusedLicenseCount}', colors: colors)),
                    ],
                  ),
                ],
              ),
            ),
            if (tool.unusedLicenseCount > 0) ...[
              const SizedBox(height: AppSpacing.lg),
              _RecommendedActionCallout(
                text: '${tool.unusedLicenseCount} seat${tool.unusedLicenseCount > 1 ? 's' : ''} unused for 30 days.',
                colors: colors,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showComingSoon(context, 'License review'),
                icon: const Icon(Icons.key_rounded, size: 18),
                label: const Text('Review Licenses →'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, this.value, this.valueWidget, required this.colors});

  final String label;
  final String? value;
  final Widget? valueWidget;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption(colors.textSecondary)),
          const SizedBox(height: 2),
          valueWidget ?? Text(value ?? '', style: AppTypography.h3(colors.textPrimary)),
        ],
      ),
    );
  }
}

class _RecommendedActionCallout extends StatelessWidget {
  const _RecommendedActionCallout({required this.text, required this.colors});

  final String text;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recommended Action', style: AppTypography.caption(colors.warning).copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: AppTypography.body(colors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}