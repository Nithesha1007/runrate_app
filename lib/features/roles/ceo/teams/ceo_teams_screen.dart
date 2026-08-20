import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';

/// CEO · Teams — org-wide department view.
///
/// v3: removed the top "Org health overview" KPI hero card, and
/// stripped the department cards down to what matters at a glance —
/// name, lead, member count, health status, and spend vs. budget.
/// Dropped from each card: the trend arrow/percentage, the AI-tool
/// line, and the Adoption/Budget/Productivity mini-stat row. Tapping
/// a card still opens the full team roster (CeoTeamMembersScreen) for
/// anyone who wants the detail that used to live inline.
///
/// Search, filters, sort, period selector, and the Insights section
/// below the list are unchanged.
///
/// NOTE — Period selector (This Month / This Quarter / YTD): the
/// existing repository only exposes a single current snapshot per
/// department (no per-period historical query). Per your instruction
/// not to fabricate fake API calls, the selector is wired into the
/// UI and re-triggers the existing `CeoTeamsCubit.load()` so it's
/// ready the moment a period-aware repository method exists — but it
/// does not change the numbers shown today. Flag this to me if you'd
/// rather the control simply not exist yet.
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

enum _HealthFilter {
  all,
  onTrack,
  atRisk,
  critical,
  highSpend,
  lowAdoption,
  overBudget,
}

enum _SortKey { health, spend, adoption }

enum _Period { month, quarter, ytd }

class _CeoTeamsView extends StatefulWidget {
  const _CeoTeamsView();

  @override
  State<_CeoTeamsView> createState() => _CeoTeamsViewState();
}

class _CeoTeamsViewState extends State<_CeoTeamsView> {
  _HealthFilter _filter = _HealthFilter.all;
  _SortKey _sort = _SortKey.health;
  _Period _period = _Period.month;

  // ---- filtering ----------------------------------------------------------

  List<DepartmentSummary> _applyFilter(List<DepartmentSummary> list) {
    if (list.isEmpty) return list;

    switch (_filter) {
      case _HealthFilter.all:
        return list;
      case _HealthFilter.onTrack:
        return list.where((d) => d.health == DepartmentHealth.onTrack).toList();
      case _HealthFilter.atRisk:
        return list.where((d) => d.health == DepartmentHealth.atRisk).toList();
      case _HealthFilter.critical:
        return list
            .where((d) => d.health == DepartmentHealth.critical)
            .toList();
      case _HealthFilter.highSpend:
        final median = _median(list.map((d) => d.team.spend).toList());
        return list.where((d) => d.team.spend > median).toList();
      case _HealthFilter.lowAdoption:
        return list.where((d) => d.team.aiAdoption < 50).toList();
      case _HealthFilter.overBudget:
        return list.where((d) => d.team.budgetUsedPercent >= 100).toList();
    }
  }

  List<DepartmentSummary> _applySort(List<DepartmentSummary> list) {
    final sorted = [...list];
    switch (_sort) {
      case _SortKey.health:
        sorted.sort((a, b) => _healthRank(b.health).compareTo(
            _healthRank(a.health))); // healthiest first
        break;
      case _SortKey.spend:
        sorted.sort((a, b) => b.team.spend.compareTo(a.team.spend));
        break;
      case _SortKey.adoption:
        sorted.sort((a, b) => b.team.aiAdoption.compareTo(a.team.aiAdoption));
        break;
    }
    return sorted;
  }

  static int _healthRank(DepartmentHealth h) {
    switch (h) {
      case DepartmentHealth.onTrack:
        return 2;
      case DepartmentHealth.atRisk:
        return 1;
      case DepartmentHealth.critical:
        return 0;
    }
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<CeoTeamsCubit, CeoTeamsState>(
          builder: (context, state) {
            final visible = _applySort(_applyFilter(state.filtered));
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
                            child: _PeriodSelector(
                              selected: _period,
                              onSelect: (p) {
                                setState(() => _period = p);
                                context.read<CeoTeamsCubit>().load();
                              },
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 1,
                            child: _ThemedSearchField(
                              hint: 'Search by department or lead',
                              onChanged: (q) =>
                                  context.read<CeoTeamsCubit>().search(q),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _Staggered(
                            index: 2,
                            child: _FilterRow(
                              departments: state.allDepartments,
                              selected: _filter,
                              onSelect: (f) => setState(() => _filter = f),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          if (!state.loading && visible.isNotEmpty)
                            _Staggered(
                              index: 3,
                              child: _SortHeaderRow(
                                selected: _sort,
                                onSelect: (s) => setState(() => _sort = s),
                              ),
                            ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                  if (state.loading)
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      sliver: SliverList.separated(
                        itemCount: 5,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, __) =>
                            const SkeletonLoader(height: 108),
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
                            ? 'Try a different filter.'
                            : 'Try a different search term.',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.lg),
                      sliver: SliverList.separated(
                        // AnimatedList would need index-stable keys across
                        // sort/filter changes; SliverList + Staggered fade
                        // gives a smooth re-order feel without the added
                        // state-management surface a full AnimatedList needs.
                        key: ValueKey('${_filter}_$_sort'),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, i) {
                          final dept = visible[i];
                          return _Staggered(
                            key: ValueKey(dept.team.name),
                            index: i + 4,
                            child: _DepartmentCard(
                              summary: dept,
                              onTap: () => _openMembers(context, dept),
                            ),
                          );
                        },
                      ),
                    ),
                  // "Insights" — secondary section, below the primary
                  // department list rather than competing with it up top.
                  if (!state.loading && state.allDepartments.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, 0, AppSpacing.xl, 100),
                      sliver: SliverToBoxAdapter(
                        child: _Staggered(
                          index: visible.length + 5,
                          child: _ExecutiveSignalsSection(
                              departments: state.allDepartments),
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(
                        child: SizedBox(height: AppSpacing.xl)),
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
// Screen header
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
            child: Icon(Icons.close_rounded,
                color: colors.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }
}

/// Slide-up + fade stagger wrapper, indexed by section/row order.
class _Staggered extends StatelessWidget {
  const _Staggered({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index * 45).clamp(0, 460)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
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
// THEMED SEARCH FIELD (unchanged)
// ---------------------------------------------------------------------------
class _ThemedSearchField extends StatefulWidget {
  const _ThemedSearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<_ThemedSearchField> createState() => _ThemedSearchFieldState();
}

class _ThemedSearchFieldState extends State<_ThemedSearchField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode
        .addListener(() => setState(() => _focused = _focusNode.hasFocus));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: 52,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused ? colors.primary : colors.border,
          width: _focused ? 1.6 : 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(
              Icons.search_rounded,
              key: ValueKey(_focused),
              color: _focused ? colors.primary : colors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onChanged,
              style: AppTypography.body(colors.textPrimary),
              cursorColor: colors.primary,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.body(colors.textSecondary),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            _ScaleOnTap(
              onTap: () {
                _controller.clear();
                widget.onChanged('');
                setState(() {});
              },
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.close_rounded,
                    size: 18, color: colors.textSecondary),
              ),
            )
          else
            const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Currency helpers (still used by department cards & Insights section)
// ---------------------------------------------------------------------------
final _amountFormat = NumberFormat('#,##0');
String _formatAmount(double value) => _amountFormat.format(value);

String _compactCurrency(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return _formatAmount(value);
}

// ---------------------------------------------------------------------------
// PERIOD SELECTOR (unchanged)
// ---------------------------------------------------------------------------
class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selected, required this.onSelect});
  final _Period selected;
  final ValueChanged<_Period> onSelect;

  static const _labels = {
    _Period.month: 'This Month',
    _Period.quarter: 'This Quarter',
    _Period.ytd: 'YTD',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: _Period.values.map((p) {
          final isSelected = p == selected;
          return Expanded(
            child: _ScaleOnTap(
              onTap: () => onSelect(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  _labels[p]!,
                  style: AppTypography.caption(
                          isSelected ? Colors.white : colors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER ROW (unchanged)
// ---------------------------------------------------------------------------
class _FilterRow extends StatelessWidget {
  const _FilterRow({
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
    final onTrack =
        departments.where((d) => d.health == DepartmentHealth.onTrack).length;
    final atRisk =
        departments.where((d) => d.health == DepartmentHealth.atRisk).length;
    final critical =
        departments.where((d) => d.health == DepartmentHealth.critical).length;
    final overBudget =
        departments.where((d) => d.team.budgetUsedPercent >= 100).length;
    final lowAdoption =
        departments.where((d) => d.team.aiAdoption < 50).length;

    final chips = <(_HealthFilter, String, Color?)>[
      (_HealthFilter.all, 'All (${departments.length})', null),
      (_HealthFilter.onTrack, 'On track ($onTrack)', colors.success),
      (_HealthFilter.atRisk, 'At risk ($atRisk)', colors.warning),
      (_HealthFilter.critical, 'Critical ($critical)', colors.danger),
      (_HealthFilter.highSpend, 'High spend', colors.secondary),
      (_HealthFilter.lowAdoption, 'Low adoption ($lowAdoption)', colors.warning),
      (_HealthFilter.overBudget, 'Over budget ($overBudget)', colors.danger),
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
// SORT ROW (unchanged)
// ---------------------------------------------------------------------------
const Map<_SortKey, String> _kSortLabels = {
  _SortKey.health: 'Health',
  _SortKey.spend: 'Spend',
  _SortKey.adoption: 'Adoption',
};

class _SortHeaderRow extends StatelessWidget {
  const _SortHeaderRow({required this.selected, required this.onSelect});
  final _SortKey selected;
  final ValueChanged<_SortKey> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Text('Department performance',
              style: AppTypography.h3(colors.textPrimary)),
        ),
        _ScaleOnTap(
          onTap: () => _showSortSheet(context, selected, onSelect),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Sort: ${_kSortLabels[selected]} ▾',
                    style: AppTypography.caption(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.tune_rounded, size: 16, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSortSheet(
      BuildContext context, _SortKey current, ValueChanged<_SortKey> onSelect) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort by', style: AppTypography.h3(colors.textPrimary)),
              const SizedBox(height: AppSpacing.md),
              for (final key in _SortKey.values)
                _ScaleOnTap(
                  onTap: () {
                    onSelect(key);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Icon(
                          key == current
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: key == current
                              ? colors.primary
                              : colors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text(_kSortLabels[key]!,
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(
                                    fontWeight: key == current
                                        ? FontWeight.w700
                                        : FontWeight.w500)),
                        const Spacer(),
                        if (key == current)
                          Icon(Icons.check_rounded,
                              color: colors.primary, size: 18),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXECUTIVE SIGNALS (unchanged)
// ---------------------------------------------------------------------------
class _Signal {
  final IconData icon;
  final String category;
  final Color color;
  final String title;
  final String detail;
  final String? impact;
  const _Signal({
    required this.icon,
    required this.category,
    required this.color,
    required this.title,
    required this.detail,
    this.impact,
  });
}

class _ExecutiveSignalsSection extends StatelessWidget {
  const _ExecutiveSignalsSection({required this.departments});
  final List<DepartmentSummary> departments;

  List<_Signal> _buildSignals(AppColorsData colors) {
    final signals = <_Signal>[];
    if (departments.isEmpty) return signals;

    // Biggest spender
    final bySpend = [...departments]
      ..sort((a, b) => b.team.spend.compareTo(a.team.spend));
    final topSpender = bySpend.first;
    signals.add(_Signal(
      icon: Icons.payments_outlined,
      category: 'Spend',
      color: colors.secondary,
      title: '${topSpender.team.name} is the top spender',
      detail:
          '${_compactCurrency(topSpender.team.spend)} of ${_compactCurrency(topSpender.team.monthlyBudget)} budget used this period.',
    ));

    // Adoption drop / low adoption
    final lowAdoption = departments
        .where((d) => d.team.aiAdoption < 50)
        .toList()
      ..sort((a, b) => a.team.aiAdoption.compareTo(b.team.aiAdoption));
    if (lowAdoption.isNotEmpty) {
      final d = lowAdoption.first;
      signals.add(_Signal(
        icon: Icons.trending_down_rounded,
        category: 'Risk',
        color: colors.warning,
        title: '${d.team.name} adoption is low',
        detail:
            'Only ${d.team.aiAdoption.toStringAsFixed(0)}% AI adoption across ${d.team.memberCount} members.',
      ));
    }

    // Highest adoption growth proxy — trend delta from monthlyTrend
    final growers = departments.where((d) => d.team.monthlyTrend.length >= 2);
    if (growers.isNotEmpty) {
      DepartmentSummary? best;
      double bestDelta = 0;
      for (final d in growers) {
        final t = d.team.monthlyTrend;
        final delta = t.last - t[t.length - 2];
        if (best == null || delta > bestDelta) {
          best = d;
          bestDelta = delta;
        }
      }
      if (best != null && bestDelta > 0) {
        signals.add(_Signal(
          icon: Icons.rocket_launch_outlined,
          category: 'Growth',
          color: colors.success,
          title: '${best.team.name} is trending up',
          detail: 'Spend/activity rose vs. the prior month.',
        ));
      }
    }

    // Over-budget departments
    final overBudget = departments
        .where((d) => d.team.budgetUsedPercent >= 90)
        .toList()
      ..sort((a, b) =>
          b.team.budgetUsedPercent.compareTo(a.team.budgetUsedPercent));
    if (overBudget.isNotEmpty) {
      final d = overBudget.first;
      final over = d.team.budgetUsedPercent >= 100;
      signals.add(_Signal(
        icon: Icons.account_balance_wallet_outlined,
        category: 'Budget',
        color: colors.danger,
        title: over
            ? '${d.team.name} is over budget'
            : '${d.team.name} is approaching budget',
        detail:
            '${d.team.budgetUsedPercent.toStringAsFixed(0)}% of quarterly budget used.',
      ));
    }

    // Tool overlap — departments sharing the same top tool
    final byTool = <String, List<DepartmentSummary>>{};
    for (final d in departments) {
      byTool.putIfAbsent(d.team.topAiTool, () => []).add(d);
    }
    final overlap =
        byTool.entries.where((e) => e.value.length > 1).toList()
          ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (overlap.isNotEmpty) {
      final entry = overlap.first;
      signals.add(_Signal(
        icon: Icons.hub_outlined,
        category: 'Optimization',
        color: colors.primary,
        title: 'Overlapping tool usage',
        detail:
            '${entry.value.length} departments rely on ${entry.key} — a consolidated license tier may cut cost.',
      ));
    }

    return signals;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final signals = _buildSignals(colors);
    if (signals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Insights', style: AppTypography.h3(colors.textPrimary)),
        const SizedBox(height: 2),
        Text('A few things worth a closer look',
            style: AppTypography.caption(colors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 164,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: signals.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) => _SignalCard(signal: signals[i]),
          ),
        ),
      ],
    );
  }
}

class _SignalCard extends StatelessWidget {
  const _SignalCard({required this.signal});
  final _Signal signal;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: colors.surfaceElevated,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(signal.icon, color: signal.color),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(signal.title,
                          style: AppTypography.h3(colors.textPrimary)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(signal.detail,
                    style: AppTypography.body(colors.textSecondary)),
                if (signal.impact != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Impact: ${signal.impact}',
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        );
      },
      child: Container(
        width: 248,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: signal.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(signal.icon, color: signal.color, size: 16),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(signal.category.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption(signal.color).copyWith(
                          fontWeight: FontWeight.w700, fontSize: 10)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              signal.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              signal.detail,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption(colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DEPARTMENT BRAND
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
  const _DeptAvatar({required this.name}) : size = 46;
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
// DEPARTMENT CARD — v3: stripped to essentials.
//
// Kept: avatar, name, lead + member count, health badge, spend vs.
// budget with a slim progress bar, and a "View team roster" footer
// that mirrors the card's own tap target.
//
// Removed: the trend arrow/percentage, the AI-tool line, and the
// Adoption/Budget/Productivity mini-stat row — all per your last
// message. Those numbers are still visible in full on the team
// roster screen this card opens.
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
    final budgetPct = (team.budgetUsedPercent / 100).clamp(0.0, 1.0);
    final budgetBarColor = team.budgetUsedPercent >= 100
        ? colors.danger
        : team.budgetUsedPercent >= 90
            ? colors.warning
            : colors.primary;

    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Identity: department + lead + health -------------------
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
            const SizedBox(height: AppSpacing.md),
            // --- Spend vs. budget, with a slim progress indicator -------
            Row(
              children: [
                Icon(Icons.currency_rupee_rounded,
                    size: 15, color: colors.textPrimary),
                const SizedBox(width: 2),
                Text(
                  '${_formatAmount(team.spend)} / ${_formatAmount(team.monthlyBudget)}',
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${team.budgetUsedPercent.toStringAsFixed(0)}% used',
                  style: AppTypography.caption(colors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 4,
                child: Stack(
                  children: [
                    Container(color: colors.border),
                    FractionallySizedBox(
                      widthFactor: budgetPct,
                      child: Container(color: budgetBarColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            // --- Footer: clear affordance to open the full roster -------
            Row(
              children: [
                Text(
                  'View team roster',
                  style: AppTypography.caption(colors.primary)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(Icons.chevron_right_rounded,
                    color: colors.primary, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}