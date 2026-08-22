import 'dart:ui';
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
/// v5: removed the solid vertical health-color accent bar from
/// department cards (per feedback — no more colored "line" per
/// card). Health status is now communicated via the badge icon +
/// label and a very faint oversized watermark icon in the card
/// background, instead of a hard color bar. The "Sort" control now
/// opens as an anchored popup menu right at the button (via
/// `showMenu`) instead of sliding up as a full-width bottom sheet,
/// with an animated chevron that rotates while open. No logic
/// changes — filtering/sorting/search/period wiring all unchanged.
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
// Screen header — glow accent line + pulsing "live" indicator (unchanged)
// ---------------------------------------------------------------------------
class _ScreenHeader extends StatefulWidget {
  const _ScreenHeader({required this.colors});
  final AppColorsData colors;

  @override
  State<_ScreenHeader> createState() => _ScreenHeaderState();
}

class _ScreenHeaderState extends State<_ScreenHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: -3,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.corporate_fare_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text('Departments', style: AppTypography.h1(colors.textPrimary)),
                  const SizedBox(width: 10),
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, _) {
                      final t = _pulseController.value;
                      return Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.success,
                          boxShadow: [
                            BoxShadow(
                              color: colors.success
                                  .withValues(alpha: 0.55 - (t * 0.35)),
                              blurRadius: 4 + (t * 8),
                              spreadRadius: t * 2.5,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Org-wide team health & spend',
                  style: AppTypography.caption(colors.textSecondary)),
              const SizedBox(height: 10),
              Container(
                width: 46,
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [colors.primary, colors.secondary],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _ScaleOnTap(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
      duration: const Duration(milliseconds: 220),
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
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
// Currency helpers (unchanged)
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
    _Period.month: 'Month',
    _Period.quarter: 'Quarter',
    _Period.ytd: 'YTD',
  };

  static const _icons = {
    _Period.month: Icons.calendar_view_day_rounded,
    _Period.quarter: Icons.calendar_view_month_rounded,
    _Period.ytd: Icons.insights_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final index = _Period.values.indexOf(selected);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final segmentWidth =
                  (constraints.maxWidth - 10) / _Period.values.length;
              return SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 340),
                      curve: Curves.easeOutCubic,
                      left: index * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colors.primary, colors.secondary],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: -3,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: _Period.values.map((p) {
                        final isSelected = p == selected;
                        return Expanded(
                          child: _ScaleOnTap(
                            onTap: () => onSelect(p),
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: AppTypography.caption(
                                isSelected ? Colors.white : colors.textSecondary,
                              ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      scale: isSelected ? 1.05 : 1.0,
                                      child: Icon(
                                        _icons[p],
                                        size: 15,
                                        color: isSelected
                                            ? Colors.white
                                            : colors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(_labels[p]!),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
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
          final glow = dotColor ?? colors.primary;
          return _ScaleOnTap(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [colors.primary, colors.secondary],
                      )
                    : null,
                color: isSelected ? null : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? Colors.transparent : colors.border),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: glow.withValues(alpha: 0.35),
                          blurRadius: 14,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : dotColor,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ]
                            : null,
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
// SORT ROW — v5: opens an anchored popup menu right at the button
// instead of a full-width bottom sheet. Chevron rotates while open.
// ---------------------------------------------------------------------------
const Map<_SortKey, String> _kSortLabels = {
  _SortKey.health: 'Health',
  _SortKey.spend: 'Spend',
  _SortKey.adoption: 'Adoption',
};

const Map<_SortKey, IconData> _kSortIcons = {
  _SortKey.health: Icons.favorite_rounded,
  _SortKey.spend: Icons.currency_rupee_rounded,
  _SortKey.adoption: Icons.trending_up_rounded,
};

class _SortHeaderRow extends StatefulWidget {
  const _SortHeaderRow({required this.selected, required this.onSelect});
  final _SortKey selected;
  final ValueChanged<_SortKey> onSelect;

  @override
  State<_SortHeaderRow> createState() => _SortHeaderRowState();
}

class _SortHeaderRowState extends State<_SortHeaderRow> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _menuOpen = false;

  Future<void> _openSortMenu(BuildContext context) async {
    final renderBox =
        _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlayBox == null) return;

    final colors = AppColors.of(context);
    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = renderBox.size;

    final position = RelativeRect.fromLTRB(
      topLeft.dx,
      topLeft.dy + size.height + 8,
      overlayBox.size.width - (topLeft.dx + size.width),
      0,
    );

    setState(() => _menuOpen = true);

    final result = await showMenu<_SortKey>(
      context: context,
      position: position,
      color: colors.surfaceElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.border),
      ),
      constraints: const BoxConstraints(minWidth: 190),
      items: [
        for (final key in _SortKey.values)
          PopupMenuItem<_SortKey>(
            value: key,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: key == widget.selected
                        ? colors.primary.withValues(alpha: 0.14)
                        : colors.border.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _kSortIcons[key],
                    size: 16,
                    color: key == widget.selected
                        ? colors.primary
                        : colors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _kSortLabels[key]!,
                  style: AppTypography.body(colors.textPrimary).copyWith(
                      fontWeight: key == widget.selected
                          ? FontWeight.w700
                          : FontWeight.w500),
                ),
                const Spacer(),
                if (key == widget.selected)
                  Icon(Icons.check_circle_rounded,
                      color: colors.primary, size: 17),
              ],
            ),
          ),
      ],
    );

    if (!mounted) return;
    setState(() => _menuOpen = false);
    if (result != null) widget.onSelect(result);
  }

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
          onTap: () => _openSortMenu(context),
          child: AnimatedContainer(
            key: _buttonKey,
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _menuOpen ? colors.primary : colors.border,
                width: _menuOpen ? 1.4 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: _menuOpen ? 0.18 : 0.08),
                  blurRadius: _menuOpen ? 14 : 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_kSortIcons[widget.selected], size: 13, color: colors.primary),
                const SizedBox(width: 5),
                Text('Sort: ${_kSortLabels[widget.selected]}',
                    style: AppTypography.caption(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _menuOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ],
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
  }) : impact = null;
}

class _ExecutiveSignalsSection extends StatelessWidget {
  const _ExecutiveSignalsSection({required this.departments});
  final List<DepartmentSummary> departments;

  List<_Signal> _buildSignals(AppColorsData colors) {
    final signals = <_Signal>[];
    if (departments.isEmpty) return signals;

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
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: colors.primary),
            const SizedBox(width: 6),
            Text('Insights', style: AppTypography.h3(colors.textPrimary)),
          ],
        ),
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
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: signal.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(signal.icon, color: signal.color),
                    ),
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
          border: Border.all(color: signal.color.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: signal.color.withValues(alpha: 0.12),
              blurRadius: 16,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
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
                    color: signal.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: signal.color.withValues(alpha: 0.25),
                        blurRadius: 8,
                      ),
                    ],
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
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 14,
            spreadRadius: -3,
            offset: const Offset(0, 5),
          ),
        ],
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
// DEPARTMENT CARD — v5: the solid vertical health-color accent bar has
// been removed entirely. Health is now communicated through (1) an
// icon + label badge, and (2) a very faint oversized watermark icon
// in the card's background corner — no hard color "line" on any card.
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

  static const _healthIcons = {
    DepartmentHealth.onTrack: Icons.check_circle_rounded,
    DepartmentHealth.atRisk: Icons.error_outline_rounded,
    DepartmentHealth.critical: Icons.dangerous_rounded,
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
    final healthIcon = _healthIcons[summary.health]!;
    final budgetPct = (team.budgetUsedPercent / 100).clamp(0.0, 1.0);
    final budgetBarColor = team.budgetUsedPercent >= 100
        ? colors.danger
        : team.budgetUsedPercent >= 90
            ? colors.warning
            : colors.primary;

    return _ScaleOnTap(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: healthColor.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Faint oversized watermark icon — a subtle nod to
              // status without a hard color bar/line on the card.
              Positioned(
                right: -14,
                top: -14,
                child: Icon(
                  healthIcon,
                  size: 96,
                  color: healthColor.withValues(alpha: 0.05),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Identity: department + lead + health ---
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
                                style: AppTypography.caption(
                                    colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 5),
                          decoration: BoxDecoration(
                            color: healthColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color: healthColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(healthIcon, size: 12, color: healthColor),
                              const SizedBox(width: 4),
                              Text(
                                _healthLabels[summary.health]!,
                                style: AppTypography.caption(healthColor)
                                    .copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // --- Spend vs. budget ---
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
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 5,
                        child: Stack(
                          children: [
                            Container(color: colors.border),
                            FractionallySizedBox(
                              widthFactor: budgetPct,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      budgetBarColor,
                                      budgetBarColor.withValues(alpha: 0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: budgetBarColor
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: AppSpacing.sm),
                    // --- Footer ---
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
            ],
          ),
        ),
      ),
    );
  }
}