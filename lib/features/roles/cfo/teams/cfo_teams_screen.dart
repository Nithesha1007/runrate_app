import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/teams/department_detail/cfo_department_detail_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_teams_cubit.dart';

// ---------------------------------------------------------------------------
// Palette — shared gradient language used across the CFO surface
// (Approvals, Teams, Team Members) so the app reads as one cohesive system.
// ---------------------------------------------------------------------------
const _kGradientStart = Color(0xFF6C5CE7);
const _kGradientEnd = Color(0xFF4C6FEF);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 20.0;

/// CFO · Teams
/// "Runrate" Teams Overview: gradient performance hero, filterable
/// department performance list (tap a department to drill in), top
/// org-wide ROI tools, pending budget requests, and a team leaderboard —
/// wired to [CfoTeamsCubit].
///
/// Note: bottom navigation (Home / AI / Teams / Approvals / More) is
/// assumed to live in the parent tab shell, not in this screen, so it
/// isn't duplicated here.
class CfoTeamsScreen extends StatelessWidget {
  const CfoTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoTeamsCubit(),
      child: const _CfoTeamsView(),
    );
  }
}

class _CfoTeamsView extends StatelessWidget {
  const _CfoTeamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: BlocBuilder<CfoTeamsCubit, CfoTeamsState>(
          builder: (context, state) {
            if (state is CfoTeamsLoading || state is CfoTeamsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoTeamsError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoTeamsCubit>().load(),
              );
            }

            final data = (state as CfoTeamsLoaded).data;

            return RefreshIndicator(
              onRefresh: () => context.read<CfoTeamsCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _TopBar(),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _PerformanceHero(metrics: data.overviewMetrics),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _ScopeAndFilterRow(
                        scope: data.scope,
                        onScopeChanged: (scope) =>
                            context.read<CfoTeamsCubit>().setScope(scope),
                        onFilterTap: () {
                          // TODO: open department filter options.
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Text(
                        'Department Performance',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.grey.shade900),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Column(
                        children: [
                          for (var i = 0; i < data.visibleDepartments.length; i++) ...[
                            _DepartmentCard(
                              department: data.visibleDepartments[i],
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CfoDepartmentDetailScreen(
                                    department: data.visibleDepartments[i],
                                  ),
                                ),
                              ),
                            ),
                            if (i != data.visibleDepartments.length - 1)
                              const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _ViewAllDepartmentsRow(
                        onTap: () {
                          // TODO: navigate to full department list.
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Text(
                        'Top Org-Wide ROI Tools',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.grey.shade900),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Row(
                        children: [
                          for (var i = 0; i < data.roiTools.length; i++) ...[
                            Expanded(child: _RoiToolCard(tool: data.roiTools[i])),
                            if (i != data.roiTools.length - 1)
                              const SizedBox(width: AppSpacing.sm),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _BudgetRequestsBanner(
                        summary: data.budgetRequests,
                        onReview: () {
                          // TODO: navigate to budget requests / approvals.
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Top bar — logo mark, "Runrate" wordmark, "CFO VIEW" pill, bell
/// ---------------------------------------------------------------------

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
            ),
            child: const Icon(Icons.grid_view_rounded, size: 18, color: Colors.white),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Runrate',
                  style: TextStyle(color: _kGradientStart, fontWeight: FontWeight.w800, fontSize: 19),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CFO VIEW',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  // TODO: navigate to notifications.
                },
                customBorder: const CircleBorder(),
                child: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.notifications_none_rounded, color: Colors.grey.shade700, size: 20),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Gradient performance hero — replaces the old 4-up metric row
/// ---------------------------------------------------------------------

class _PerformanceHero extends StatelessWidget {
  const _PerformanceHero({required this.metrics});

  final TeamsOverviewMetrics metrics;

  static String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final ringPercent = metrics.avgRoiPercent.clamp(0, 100) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradientStart, _kGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _kGradientEnd.withOpacity(0.3), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teams Overview',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: ringPercent.toDouble(),
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.22),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Text(
                      '${metrics.avgRoiPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avg. ROI across org',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 14, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${metrics.avgRoiTrendPercent.toStringAsFixed(1)}% vs last week',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.schedule_rounded,
                  value: '${_trimZero(metrics.totalTimeSavedHours)}h',
                  label: 'Time Saved',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${metrics.tasksCompleted}',
                  label: 'Tasks Done',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.currency_rupee_rounded,
                  value: formatInrCompact(metrics.valueGenerated),
                  label: 'Value Gen.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Scope tabs (All Departments / Direct Reports) + Filter button
/// ---------------------------------------------------------------------

class _ScopeAndFilterRow extends StatelessWidget {
  const _ScopeAndFilterRow({
    required this.scope,
    required this.onScopeChanged,
    required this.onFilterTap,
  });

  final DepartmentScope scope;
  final ValueChanged<DepartmentScope> onScopeChanged;
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ScopePill(
          label: 'All Departments',
          isSelected: scope == DepartmentScope.allDepartments,
          onTap: () => onScopeChanged(DepartmentScope.allDepartments),
        ),
        const SizedBox(width: AppSpacing.xs),
        _ScopePill(
          label: 'Direct Reports',
          isSelected: scope == DepartmentScope.directReports,
          onTap: () => onScopeChanged(DepartmentScope.directReports),
        ),
        const Spacer(),
        _FilterButton(onTap: onFilterTap),
      ],
    );
  }
}

class _ScopePill extends StatelessWidget {
  const _ScopePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [_kGradientStart, _kGradientEnd]) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _kGradientStart.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 15, color: _kGradientStart),
            const SizedBox(width: 4),
            const Text(
              'Filter',
              style: TextStyle(color: _kGradientStart, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Department performance card — tap to open the department detail
/// ---------------------------------------------------------------------

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.department, required this.onTap});

  final DepartmentRoi department;
  final VoidCallback onTap;

  ({IconData icon, Color color, Color bg}) get _style {
    switch (department.icon) {
      case DepartmentIcon.engineering:
        return (icon: Icons.code_rounded, color: Colors.indigo.shade600, bg: Colors.indigo.withOpacity(0.10));
      case DepartmentIcon.marketing:
        return (icon: Icons.campaign_rounded, color: Colors.green.shade700, bg: Colors.green.withOpacity(0.10));
      case DepartmentIcon.sales:
        return (icon: Icons.storefront_rounded, color: Colors.orange.shade800, bg: Colors.orange.withOpacity(0.10));
      case DepartmentIcon.product:
        return (icon: Icons.groups_rounded, color: Colors.blue.shade700, bg: Colors.blue.withOpacity(0.10));
    }
  }

  static String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final success = Colors.green.shade700;
    final style = _style;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: style.bg),
                    child: Icon(style.icon, size: 19, color: style.color),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(department.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('${department.memberCount} Members',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('ROI', style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      Text(
                        '+${department.roiPercent.toStringAsFixed(0)}%',
                        style: TextStyle(color: success, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Time Saved', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('${_trimZero(department.timeSavedHours)}h',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: department.timeSavedBarProgress.clamp(0, 1),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(_kGradientStart),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// "View All Departments" row
/// ---------------------------------------------------------------------

class _ViewAllDepartmentsRow extends StatelessWidget {
  const _ViewAllDepartmentsRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View All Departments',
              style: TextStyle(color: _kGradientStart, fontWeight: FontWeight.w700),
            ),
            SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: _kGradientStart),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Top org-wide ROI tool card
/// ---------------------------------------------------------------------

class _RoiToolCard extends StatelessWidget {
  const _RoiToolCard({required this.tool});

  final RoiTool tool;

  IconData get _icon {
    switch (tool.icon) {
      case ToolIcon.codeAssistant:
        return Icons.integration_instructions_rounded;
      case ToolIcon.chat:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  Color get _bgColor {
    switch (tool.color) {
      case ToolColor.dark:
        return const Color(0xFF15161A);
      case ToolColor.teal:
        return const Color(0xFF0F9B8E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _bgColor, borderRadius: BorderRadius.circular(12)),
                child: Icon(_icon, size: 18, color: Colors.white),
              ),
              const Icon(Icons.auto_awesome_rounded, size: 15, color: _kGradientStart),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(tool.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 2),
          Text(tool.metricLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Budget requests banner
/// ---------------------------------------------------------------------

class _BudgetRequestsBanner extends StatelessWidget {
  const _BudgetRequestsBanner({
    required this.summary,
    required this.onReview,
  });

  final BudgetRequestsSummary summary;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradientStart, _kGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: _kGradientEnd.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                child: const Icon(Icons.fact_check_outlined, size: 18, color: Colors.white),
              ),
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5484D),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${summary.pendingCount}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary.title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                Text(summary.subtitle,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(100)),
            child: TextButton(
              onPressed: onReview,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: const StadiumBorder(),
                foregroundColor: _kGradientStart,
              ),
              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFE5484D)),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
                borderRadius: BorderRadius.circular(100),
              ),
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — Indian currency (Cr / L)
/// ---------------------------------------------------------------------

String formatInrCompact(double value) {
  if (value >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  }
  if (value >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(2)}L';
  }
  return '₹${value.toStringAsFixed(0)}';
}