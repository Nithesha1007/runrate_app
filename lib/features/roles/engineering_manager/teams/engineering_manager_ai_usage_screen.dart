import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_shared.dart';
import 'engineering_manager_teams_cubit.dart';
import 'engineering_manager_tool_detail_screen.dart';

/// AI Usage Overview — adoption % (active/total), AI-assisted-work %,
/// monthly spend, active tools count, last-month-vs-this-month adoption
/// trend. Reached from the "AI Analytics" quick action, the "Active AI
/// Users"/"Active AI Tools" KPI tiles, and the inline overview's
/// "View AI Analytics" CTA.
class EngineeringManagerAiUsageScreen extends StatelessWidget {
  const EngineeringManagerAiUsageScreen({super.key, required this.overview});

  final EngineeringTeamOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final activeUsers = overview.toolUsage.fold<int>(0, (sum, t) => sum + t.activeUsers);
    final trendUp = overview.avgAiAdoptionPercent >= 60;

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
                    Text('AI Usage Overview', style: AppTypography.h2(colors.textPrimary)),
                    Text(overview.teamName, style: AppTypography.caption(colors.textSecondary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.groups_rounded,
                    label: 'Adoption',
                    value: '${overview.avgAiAdoptionPercent}%',
                    sub: '$activeUsers/${overview.totalMembers} active',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.bolt_rounded,
                    label: 'AI-assisted work',
                    value: '${overview.sprintVelocityPercent}%',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Monthly spend',
                    valueWidget: CurrencyValue(value: overview.totalMonthlyAiSpend, style: AppTypography.h2(colors.textPrimary), iconColor: colors.textPrimary),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _MetricTile(
                    icon: Icons.extension_rounded,
                    label: 'Active tools',
                    value: '${overview.activeAiToolsCount}',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            SectionCard(
              colors: colors,
              child: Row(
                children: [
                  Icon(trendUp ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: trendUp ? colors.success : colors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Adoption is ${trendUp ? 'up' : 'down'} vs last month, currently at ${overview.avgAiAdoptionPercent}% team-wide.',
                      style: AppTypography.body(colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('By Tool', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < overview.toolUsage.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i == overview.toolUsage.length - 1 ? 0 : AppSpacing.sm),
                child: StaggeredEntrance(
                  index: i,
                  child: ScaleOnTap(
                    onTap: () => Navigator.of(context).push(
                      slideFadeRoute(EngineeringManagerToolDetailScreen(tool: overview.toolUsage[i])),
                    ),
                    child: SectionCard(
                      colors: colors,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(overview.toolUsage[i].toolName,
                                style: AppTypography.body(colors.textPrimary).copyWith(fontWeight: FontWeight.w700)),
                          ),
                          Text('${overview.toolUsage[i].adoptionPercent}%', style: AppTypography.body(colors.textSecondary)),
                          const SizedBox(width: 6),
                          Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.icon, required this.label, this.value, this.valueWidget, this.sub, required this.colors});

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final String? sub;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      colors: colors,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(height: AppSpacing.sm),
          valueWidget ?? Text(value ?? '', style: AppTypography.h2(colors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(colors.textSecondary)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: AppTypography.caption(colors.textSecondary)),
          ],
        ],
      ),
    );
  }
}