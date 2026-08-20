import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_shared.dart';
import 'engineering_manager_teams_cubit.dart';

/// Team Budget — Spend / Remaining / Forecast, progress bar, status pill,
/// a dynamic warning line when utilization is high, and per-member budget
/// breakdown. Reached from the "Budget Details" quick action and the
/// inline Team Budget section's "Review Budget →" CTA.
class EngineeringManagerBudgetScreen extends StatelessWidget {
  const EngineeringManagerBudgetScreen({super.key, required this.overview, this.members = const []});

  final EngineeringTeamOverview overview;
  final List<TeamMember> members;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final util = overview.budgetUtilizationPercent;
    final highUtilization = util >= 85;
    final barColor = util >= 100 ? colors.danger : (util >= 85 ? colors.warning : colors.success);
    final statusLabel = util >= 100 ? 'Over budget' : (util >= 85 ? 'Warning' : 'Healthy');

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Team Budget', style: AppTypography.h2(colors.textPrimary)),
                    Text(overview.teamName, style: AppTypography.caption(colors.textSecondary)),
                  ],
                ),
                const Spacer(),
                StatusBadge(info: StatusInfo(statusLabel, barColor, barColor.withValues(alpha: 0.14))),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: HeroMetricPill(label: 'Spend', value: CurrencyValue.format(overview.totalMonthlyAiSpend)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: HeroMetricPill(label: 'Remaining', value: CurrencyValue.format(overview.budgetRemaining)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: HeroMetricPill(label: 'Forecast', value: CurrencyValue.format(overview.budgetForecast)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: (util / 100).clamp(0, 1).toDouble()),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('${util.round()}% of allocated budget used', style: AppTypography.caption(Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            if (highUtilization) ...[
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.warning.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: colors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Budget utilization is at ${util.round()}% — review spend before month end to stay on track.',
                        style: AppTypography.body(colors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text('Top AI Tool Spend', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < overview.toolUsage.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == overview.toolUsage.length - 1 ? 0 : AppSpacing.sm),
                child: StaggeredEntrance(
                  index: i,
                  child: SectionCard(
                    colors: colors,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(overview.toolUsage[i].toolName,
                              style: AppTypography.body(colors.textPrimary).copyWith(fontWeight: FontWeight.w600)),
                        ),
                        CurrencyValue(
                          value: overview.toolUsage[i].monthlySpend,
                          style: AppTypography.body(colors.textPrimary).copyWith(fontWeight: FontWeight.w700),
                          iconColor: colors.textPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showComingSoon(context, 'Budget review'),
                icon: const Icon(Icons.fact_check_outlined, size: 18),
                label: const Text('Review Budget →'),
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