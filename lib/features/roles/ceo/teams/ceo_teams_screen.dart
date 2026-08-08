import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/shared/models/home_models.dart';
import 'package:runrate/features/roles/ceo/shared/models/team_model.dart';
import 'package:runrate/features/roles/ceo/teams/ceo_teams_memberscreen.dart';

import '../data/ceo_mock_repository.dart';

import 'ceo_teams_cubit.dart';
import 'ceo_teams_state.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/utils/formatters.dart';

/// CEO · Teams — org-wide department view: animated headcount/health hero,
/// department cards (lead, size, spend, health), search + health filter,
/// and a tap-through to each department's member roster.
class CeoTeamsScreen extends StatelessWidget {
  const CeoTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoTeamsCubit(CeoMockRepository()),
      child: const _CeoTeamsView(),
    );
  }
}

enum _HealthFilter { all, onTrack, atRisk, critical }

class _CeoTeamsView extends StatefulWidget {
  const _CeoTeamsView();

  @override
  State<_CeoTeamsView> createState() => _CeoTeamsViewState();
}

class _CeoTeamsViewState extends State<_CeoTeamsView> {
  _HealthFilter _filter = _HealthFilter.all;

  List<DepartmentSummary> _applyHealthFilter(List<DepartmentSummary> list) {
    switch (_filter) {
      case _HealthFilter.all:
        return list;
      case _HealthFilter.onTrack:
        return list.where((d) => d.health == DepartmentHealth.onTrack).toList();
      case _HealthFilter.atRisk:
        return list.where((d) => d.health == DepartmentHealth.atRisk).toList();
      case _HealthFilter.critical:
        return list.where((d) => d.health == DepartmentHealth.critical).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<CeoTeamsCubit, CeoTeamsState>(
          builder: (context, state) {
            final visible = _applyHealthFilter(state.filtered);
            return RefreshIndicator(
              color: colors.primary,
              onRefresh: () => context.read<CeoTeamsCubit>().load(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _ScreenHeader(colors: colors),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 0,
                            child: state.loading
                                ? const _HeroShimmer()
                                : _TeamsHeroCard(state: state),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 1,
                            child: AppSearchBar(
                              hint: 'Search by department or lead',
                              onChanged: (q) =>
                                  context.read<CeoTeamsCubit>().search(q),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _Staggered(
                            index: 2,
                            child: _HealthFilterRow(
                              departments: state.allDepartments,
                              selected: _filter,
                              onSelect: (f) => setState(() => _filter = f),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                  if (state.loading)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl),
                      sliver: SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, __) =>
                            const SkeletonLoader(height: 96),
                      ),
                    )
                  else if (visible.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: state.query.isEmpty
                            ? 'No departments in this filter'
                            : 'No departments found',
                        message: state.query.isEmpty
                            ? 'Try a different health filter.'
                            : 'Try a different search term.',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, 100),
                      sliver: SliverList.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final dept = visible[i];
                          return _Staggered(
                            index: i + 3,
                            child: _DepartmentCard(
                              summary: dept,
                              onTap: () => _openMembers(context, dept),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openMembers(BuildContext context, DepartmentSummary dept) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 380),
        pageBuilder: (_, animation, __) =>
            CeoTeamMembersScreen(department: dept),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen header — title + subtitle, matches the rest of the app's header
// typography instead of a plain AppBar title.
// ---------------------------------------------------------------------------
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Departments', style: AppTypography.h1(colors.textPrimary)),
              const SizedBox(height: 2),
              Text('Org-wide team health & spend',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.close_rounded, color: colors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Slide-up + fade stagger wrapper, indexed by section/row order.
class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 50).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Subtle scale-down-on-tap wrapper for tactile cards/buttons.
class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO CARD — gradient summary: total employees, department count, and an
// animated ring showing % of departments that are "On Track".
// ---------------------------------------------------------------------------
class _TeamsHeroCard extends StatelessWidget {
  const _TeamsHeroCard({required this.state});
  final CeoTeamsState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final total = state.allDepartments.length;
    final onTrack = state.allDepartments
        .where((d) => d.health == DepartmentHealth.onTrack)
        .length;
    final atRisk = state.allDepartments
        .where((d) => d.health == DepartmentHealth.atRisk)
        .length;
    final critical = state.allDepartments
        .where((d) => d.health == DepartmentHealth.critical)
        .length;
    final healthScore = total == 0 ? 0.0 : onTrack / total;
    final totalSpend =
        state.allDepartments.fold<double>(0, (s, d) => s + d.team.spend);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.secondary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Org health overview',
                      style: AppTypography.h3(Colors.white)),
                ),
                _StatusPill(
                  label: critical > 0
                      ? '$critical critical'
                      : atRisk > 0
                          ? '$atRisk at risk'
                          : 'All healthy',
                  color: critical > 0
                      ? colors.danger
                      : atRisk > 0
                          ? colors.warning
                          : colors.success,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: CircularProgressIndicator(
                          value: 1,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          valueColor: AlwaysStoppedAnimation(
                              Colors.white.withValues(alpha: 0.18)),
                        ),
                      ),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: healthScore),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => SizedBox(
                          width: 92,
                          height: 92,
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor:
                                const AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                      _AnimatedCounterText(
                        target: (healthScore * 100).round(),
                        suffix: '%',
                        style: AppTypography.h3(Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatChip(
                          label: 'Employees', value: '${state.totalEmployees}'),
                      const SizedBox(height: AppSpacing.sm),
                      _StatChip(
                          label: 'Spend', value: '\$${_compact(totalSpend)}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _MetricPill(label: 'Departments', value: '$total'),
                _MetricPill(label: 'On track', value: '$onTrack'),
                _MetricPill(label: 'At risk', value: '${atRisk + critical}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroShimmer extends StatelessWidget {
  const _HeroShimmer();

  @override
  Widget build(BuildContext context) {
    return const SkeletonLoader(height: 236, );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(Colors.white)),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  const _AnimatedCounterText({
    required this.target,
    required this.style,
    this.suffix = '',
  });

  final int target;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text('$value$suffix', style: style),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
          Text(value,
              style: AppTypography.caption(Colors.white)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label · $value',
          style: AppTypography.caption(Colors.white)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// HEALTH FILTER ROW — chip row with live counts, replaces plain search-only
// filtering. "All" always first; selected chip gets a filled gradient look.
// ---------------------------------------------------------------------------
class _HealthFilterRow extends StatelessWidget {
  const _HealthFilterRow({
    required this.departments,
    required this.selected,
    required this.onSelect,
  });

  final List<DepartmentSummary> departments;
  final _HealthFilter selected;
  final ValueChanged<_HealthFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final onTrack = departments
        .where((d) => d.health == DepartmentHealth.onTrack)
        .length;
    final atRisk =
        departments.where((d) => d.health == DepartmentHealth.atRisk).length;
    final critical = departments
        .where((d) => d.health == DepartmentHealth.critical)
        .length;

    final chips = <(_HealthFilter, String, Color?)>[
      (_HealthFilter.all, 'All (${departments.length})', null),
      (_HealthFilter.onTrack, 'On track ($onTrack)', colors.success),
      (_HealthFilter.atRisk, 'At risk ($atRisk)', colors.warning),
      (_HealthFilter.critical, 'Critical ($critical)', colors.danger),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (filter, label, dotColor) = chips[i];
          final isSelected = filter == selected;
          return _ScaleOnTap(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? colors.primary : colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTypography.caption(
                            isSelected ? Colors.white : colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEPARTMENT BRAND — consistent color + initials per department name, so
// each card gets a distinct identity instead of a flat generic icon.
// ---------------------------------------------------------------------------
const List<Color> _kDeptPalette = [
  Color(0xFF6C5CE7),
  Color(0xFF2F80ED),
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFF11998E),
  Color(0xFF9B51E0),
];

Color _deptColorFor(String name) {
  final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _kDeptPalette[hash % _kDeptPalette.length];
}

String _initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
}

class _DeptAvatar extends StatelessWidget {
  const _DeptAvatar({required this.name, this.size = 46});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _deptColorFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.7)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initialsFor(name),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEPARTMENT CARD — lead, headcount, spend, health pill + a slim spend
// progress bar underneath so budget pressure is visible at a glance.
// ---------------------------------------------------------------------------
class _DepartmentCard extends StatelessWidget {
  final DepartmentSummary summary;
  final VoidCallback onTap;
  const _DepartmentCard({required this.summary, required this.onTap});

  static const _healthLabels = {
    DepartmentHealth.onTrack: 'On Track',
    DepartmentHealth.atRisk: 'At Risk',
    DepartmentHealth.critical: 'Critical',
  };

  Color _healthColor(AppColorsData colors, DepartmentHealth health) {
    switch (health) {
      case DepartmentHealth.onTrack:
        return colors.success;
      case DepartmentHealth.atRisk:
        return colors.warning;
      case DepartmentHealth.critical:
        return colors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final team = summary.team;
    final healthColor = _healthColor(colors, summary.health);

    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DeptAvatar(name: team.name),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Led by ${summary.leadName} · ${team.memberCount} members',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: healthColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _healthLabels[summary.health]!,
                    style: AppTypography.caption(healthColor)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  Formatters.currency(team.spend),
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: colors.textSecondary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}