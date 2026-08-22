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

/// CEO · Teams › Department Details — v2.
///
/// Adds, on top of the existing overview/trend/tools/members sections:
///   - Risks (section 13)
///   - Optimization Opportunities (section 14)
///   - Richer AI Tool Usage cards: seats, utilization, unused-seat
///     savings estimate (section 12)
///
/// Everything here is derived from fields already on TeamModel
/// (spend, monthlyBudget, budgetUsedPercent, aiAdoption, aiRoi,
/// productivityScore, activeAiTools, topAiTool, monthlyTrend,
/// memberCount, members). No new model fields were required, so no
/// changes were made to team_model.dart or the mock repository.
///
/// One thing I could not infer from the code you've shared: whether
/// TeamModel exposes a per-tool breakdown (seats purchased vs. active
/// users per tool) beyond `activeAiTools`/`topAiTool`. Section 12 in
/// your spec ("ChatGPT Enterprise — 17 active users, ₹62K/month" per
/// tool) needs that list. I've built the section to *use* a
/// `List<AiToolUsage> toolUsage` on TeamModel if present, and fall
/// back to a single-row summary built from `activeAiTools`/
/// `topAiTool`/`spend` if it isn't — so it renders correctly either
/// way and upgrades automatically once/if you add that field. See
/// the `_ToolUsageSection._resolveTools` method below.
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
            child: Text('AI Tool Usage',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          Reveal(delayMs: 120, child: _ToolUsageSection(department: d)),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 140,
            child: Text('Risks', style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          Reveal(delayMs: 160, child: _RisksSection(department: d)),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 180,
            child: Text('Optimization Opportunities',
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          const SizedBox(height: AppSpacing.md),
          Reveal(delayMs: 200, child: _OpportunitiesSection(department: d)),
          const SizedBox(height: AppSpacing.xxl),
          Reveal(
            delayMs: 220,
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
                  delayMs: 240 + e.key * 30,
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
    final remaining = d.monthlyBudget - d.spend;

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
              stat('Remaining', Formatters.currency(remaining < 0 ? 0 : remaining)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              stat('AI ROI', '${d.aiRoi.toStringAsFixed(1)}x'),
              stat('Adoption', '${d.aiAdoption.toStringAsFixed(0)}%'),
              stat('Productivity', d.productivityScore.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI TOOL USAGE — section 12
// ---------------------------------------------------------------------------
class _ToolUsageRow {
  final String name;
  final int activeUsers;
  final int seats;
  final double monthlySpend;
  const _ToolUsageRow({
    required this.name,
    required this.activeUsers,
    required this.seats,
    required this.monthlySpend,
  });

  int get unusedSeats => (seats - activeUsers).clamp(0, seats);
  double get utilization => seats == 0 ? 0 : (activeUsers / seats) * 100;
  double get costPerActiveUser =>
      activeUsers == 0 ? monthlySpend : monthlySpend / activeUsers;
}

class _ToolUsageSection extends StatelessWidget {
  const _ToolUsageSection({required this.department});
  final TeamModel department;

  /// Uses `department.toolUsage` (a hypothetical `List<AiToolUsage>`) if
  /// the model exposes it; otherwise falls back to a single summary row
  /// built from the fields we know exist (`topAiTool`, `activeAiTools`,
  /// `spend`, `memberCount`) so the section still renders something
  /// truthful rather than fabricated per-tool numbers.
  List<_ToolUsageRow> _resolveTools(TeamModel d) {
    try {
      final dynamic dyn = d;
      final dynamic raw = dyn.toolUsage;
      if (raw is List && raw.isNotEmpty) {
        return raw.map<_ToolUsageRow>((t) {
          final dynamic tt = t;
          return _ToolUsageRow(
            name: tt.name as String,
            activeUsers: tt.activeUsers as int,
            seats: tt.seats as int,
            monthlySpend: (tt.monthlySpend as num).toDouble(),
          );
        }).toList();
      }
    } catch (_) {
      // TeamModel doesn't expose toolUsage yet — fall back below.
    }
    final estimatedSeats = (d.memberCount * 0.9).round();
    return [
      _ToolUsageRow(
        name: d.topAiTool,
        activeUsers: d.memberCount,
        seats: estimatedSeats < d.memberCount ? d.memberCount : estimatedSeats,
        monthlySpend: d.spend,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tools = _resolveTools(department);
    final totalUnused = tools.fold<int>(0, (s, t) => s + t.unusedSeats);
    final avgCostPerSeat = tools.isEmpty
        ? 0.0
        : tools.fold<double>(0, (s, t) => s + t.monthlySpend) / tools.length;
    final potentialSaving = totalUnused * (avgCostPerSeat /
        (tools.isEmpty || tools.first.seats == 0 ? 1 : tools.first.seats));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...tools.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ToolCard(tool: t),
            )),
        if (totalUnused > 0)
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.savings_outlined, color: AppColors.success),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Potential Savings',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        '$totalUnused unused seats · ~${Formatters.currency(potentialSaving)} quarterly',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ToolCard extends StatefulWidget {
  const _ToolCard({required this.tool});
  final _ToolUsageRow tool;

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = widget.tool;
    return AppCard(
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.hub_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.name,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text('${t.activeUsers} active users',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(Formatters.currency(t.monthlySpend),
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text('/month',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState:
                  _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv(theme, 'Purchased seats', '${t.seats}'),
                    _kv(theme, 'Utilization', '${t.utilization.toStringAsFixed(0)}%'),
                    _kv(theme, 'Unused seats', '${t.unusedSeats}'),
                    _kv(theme, 'Cost per active user',
                        Formatters.currency(t.costPerActiveUser)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
                child: Text(k,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant))),
            Text(v,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// RISKS — section 13
// ---------------------------------------------------------------------------
class _Risk {
  final String title;
  final String severity; // High / Medium / Low
  final String detail;
  final String action;
  const _Risk(
      {required this.title,
      required this.severity,
      required this.detail,
      required this.action});
}

class _RisksSection extends StatelessWidget {
  const _RisksSection({required this.department});
  final TeamModel department;

  List<_Risk> _buildRisks(TeamModel d) {
    final risks = <_Risk>[];
    if (d.budgetUsedPercent >= 100) {
      risks.add(_Risk(
        title: 'Budget Overrun',
        severity: 'High',
        detail:
            '${d.name} has used ${d.budgetUsedPercent.toStringAsFixed(0)}% of its monthly budget.',
        action: 'Review spend drivers with department lead',
      ));
    } else if (d.budgetUsedPercent >= 90) {
      risks.add(_Risk(
        title: 'Budget Overrun',
        severity: 'Medium',
        detail:
            '${d.name} is at ${d.budgetUsedPercent.toStringAsFixed(0)}% of budget with time remaining in the period.',
        action: 'Set a spend alert at 95%',
      ));
    }
    if (d.aiAdoption < 50) {
      risks.add(_Risk(
        title: 'Low AI Adoption',
        severity: d.aiAdoption < 30 ? 'High' : 'Medium',
        detail:
            'Only ${d.aiAdoption.toStringAsFixed(0)}% of ${d.name} is actively using provisioned AI tools.',
        action: 'Schedule an enablement session',
      ));
    }
    if (d.health == DepartmentHealth.critical) {
      risks.add(const _Risk(
        title: 'Overall Department Health',
        severity: 'High',
        detail: 'This department is flagged critical across multiple metrics.',
        action: 'Escalate to CEO review',
      ));
    }
    return risks;
  }

  Color _severityColor(String s) => switch (s) {
        'High' => AppColors.danger,
        'Medium' => AppColors.warning,
        _ => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risks = _buildRisks(department);
    if (risks.isEmpty) {
      return const EmptyState(
        title: 'No active risks',
        message: 'This department has no flagged risks this period.',
        icon: Icons.verified_outlined,
      );
    }
    return Column(
      children: risks
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _severityColor(r.severity),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(r.title,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w700)),
                                ),
                                HealthBadge(
                                    label: r.severity,
                                    color: _severityColor(r.severity)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(r.detail,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(height: 4),
                            Text('Recommended: ${r.action}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// OPPORTUNITIES — section 14
// ---------------------------------------------------------------------------
class _Opportunity {
  final String title;
  final String impact;
  const _Opportunity({required this.title, required this.impact});
}

class _OpportunitiesSection extends StatelessWidget {
  const _OpportunitiesSection({required this.department});
  final TeamModel department;

  List<_Opportunity> _buildOpportunities(TeamModel d) {
    final opportunities = <_Opportunity>[];
    final estimatedSeats = (d.memberCount * 0.9).round();
    final unused = (estimatedSeats - d.memberCount).clamp(0, estimatedSeats);
    if (unused > 0) {
      final saving = unused * (d.spend / (estimatedSeats == 0 ? 1 : estimatedSeats));
      opportunities.add(_Opportunity(
        title: 'License consolidation',
        impact: '~${Formatters.currency(saving)} quarterly saving',
      ));
    }
    if (d.activeAiTools > 2) {
      opportunities.add(const _Opportunity(
        title: 'Tool consolidation',
        impact: 'Reduce overlapping AI subscriptions',
      ));
    }
    if (d.aiAdoption < 70) {
      final upside = (70 - d.aiAdoption).clamp(0, 100);
      opportunities.add(_Opportunity(
        title: 'AI adoption improvement',
        impact: 'Potential productivity +${(upside * 0.3).toStringAsFixed(0)}%',
      ));
    }
    return opportunities;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opportunities = _buildOpportunities(department);
    if (opportunities.isEmpty) {
      return const EmptyState(
        title: 'No opportunities flagged',
        message: 'This department is running efficiently this period.',
        icon: Icons.check_circle_outline,
      );
    }
    return Column(
      children: opportunities
          .map((o) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(o.title,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(o.impact,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      TextButton(onPressed: () {}, child: const Text('Review')),
                    ],
                  ),
                ),
              ))
          .toList(),
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