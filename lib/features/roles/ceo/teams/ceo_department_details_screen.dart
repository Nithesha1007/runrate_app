import 'package:flutter/material.dart';
import 'package:runrate/features/roles/ceo/shared/models/team_model.dart';
import 'package:runrate/features/roles/ceo/shared/widgets/health_badge.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_card.dart';

import '../../../../shared/widgets/simple_bar_chart.dart';
import '../../../../shared/widgets/reveal.dart';
import '../../../../shared/widgets/empty_state.dart';

/// CEO · Teams › Department Details — full drill-down for a single
/// department: members with individual AI spend, license/tool summary,
/// and a 6-month spend trend chart.
class CeoDepartmentDetailsScreen extends StatelessWidget {
  final TeamModel department;
  const CeoDepartmentDetailsScreen({super.key, required this.department});

  @override
  Widget build(BuildContext context) {
    final d = department;
    final months = [
      '6mo ago',
      '5mo ago',
      '4mo ago',
      '3mo ago',
      '2mo ago',
      'This mo'
    ];
    final trendPoints = [
      for (var i = 0; i < d.monthlyTrend.length; i++)
        BarChartPoint(
          label: i < months.length ? months[i] : 'M${i + 1}',
          value: d.monthlyTrend[i],
        ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(d.name)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          Reveal(child: _overviewCard(context, d)),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 60,
            child: Text('Monthly Trend',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          if (trendPoints.isNotEmpty)
            Reveal(
                delayMs: 80,
                child: AppCard(child: SimpleBarChart(points: trendPoints)))
          else
            const EmptyState(
              title: 'No trend data',
              message:
                  'Monthly history isn\'t available for this department yet.',
              icon: Icons.show_chart,
            ),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 100,
            child: Text('Tool Distribution',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          Reveal(delayMs: 120, child: _toolDistribution(context, d)),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 140,
            child: Row(
              children: [
                Expanded(
                  child: Text('Team Members',
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Text('${d.memberCount} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (d.members.isEmpty)
            const EmptyState(
              title: 'No member-level data',
              message:
                  'Individual AI spend hasn\'t been reported for this department.',
              icon: Icons.people_outline,
            )
          else
            ...d.members.asMap().entries.map((e) => Reveal(
                  delayMs: 160 + e.key * 30,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _MemberTile(member: e.value),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _overviewCard(BuildContext context, TeamModel d) {
    final theme = Theme.of(context);
    final healthLabel = switch (d.health) {
      DepartmentHealth.onTrack => 'Healthy',
      DepartmentHealth.atRisk => 'At Risk',
      DepartmentHealth.critical => 'Over Budget',
    };
    final healthColor = switch (d.health) {
      DepartmentHealth.onTrack => AppColors.success,
      DepartmentHealth.atRisk => AppColors.warning,
      DepartmentHealth.critical => AppColors.danger,
    };

    Widget stat(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Led by ${d.departmentHead}',
                    style: theme.textTheme.bodyMedium),
              ),
              HealthBadge(label: healthLabel, color: healthColor),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              stat('Budget', Formatters.currency(d.monthlyBudget)),
              stat('Spend', Formatters.currency(d.spend)),
              stat('Used', '${d.budgetUsedPercent.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              stat('AI ROI', '${d.aiRoi.toStringAsFixed(1)}x'),
              stat('Adoption', '${d.aiAdoption.toStringAsFixed(0)}%'),
              stat('Productivity', '${d.productivityScore.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toolDistribution(BuildContext context, TeamModel d) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.hub_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.activeAiTools} active AI tools',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('Top tool: ${d.topAiTool}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final DepartmentMember member;
  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.appColors.primaryLight,
            child: Text(
              member.name.isNotEmpty ? member.name[0] : '?',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(member.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(Formatters.currency(member.aiSpend),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              Text('${member.toolsUsed} tools',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}
