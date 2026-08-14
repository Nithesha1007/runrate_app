import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runrate/features/roles/ceo/shared/models/home_models.dart';
import 'package:runrate/features/roles/ceo/shared/models/team_model.dart';
import '../data/ceo_mock_repository.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';

enum _MemberFilter { all, highSpend, mostTools }

/// CEO · Teams → Department drill-down. Shows the roster for one
/// department, reached by tapping a department card on CeoTeamsScreen.
/// Redesigned to match the app's premium gradient-hero + themed-search +
/// staggered-list style used across Home/Teams/Approvals.
class CeoTeamMembersScreen extends StatefulWidget {
  final DepartmentSummary department;
  const CeoTeamMembersScreen({super.key, required this.department});

  @override
  State<CeoTeamMembersScreen> createState() => _CeoTeamMembersScreenState();
}

class _CeoTeamMembersScreenState extends State<CeoTeamMembersScreen> {
  final _repo = CeoMockRepository();
  late Future<List<TeamMember>> _future;
  String _query = '';
  _MemberFilter _filter = _MemberFilter.all;

  List<TeamMember> _applyFilterAndSearch(List<TeamMember> members) {
    var list = members
        .where((m) =>
            _query.isEmpty ||
            m.name.toLowerCase().contains(_query) ||
            m.role.toLowerCase().contains(_query))
        .toList();

    switch (_filter) {
      case _MemberFilter.all:
        break;
      case _MemberFilter.highSpend:
        if (list.isNotEmpty) {
          final median = _median(list.map((m) => m.aiSpend).toList());
          list = list.where((m) => m.aiSpend > median).toList();
        }
        break;
      case _MemberFilter.mostTools:
        if (list.isNotEmpty) {
          final median =
              _median(list.map((m) => m.toolsUsed.toDouble()).toList());
          list = list.where((m) => m.toolsUsed > median).toList();
        }
        break;
    }
    return list;
  }

  static double _median(List<double> values) {
    if (values.isEmpty) return 0;
    final sorted = [...values]..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return (sorted[mid - 1] + sorted[mid]) / 2;
  }

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchDepartmentMembers(widget.department.team.name);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _repo.fetchDepartmentMembers(widget.department.team.name);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dept = widget.department.team;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: colors.primary,
          onRefresh: _refresh,
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
                      _ScreenHeader(colors: colors, title: dept.name),
                      const SizedBox(height: AppSpacing.xl),
                      _Staggered(
                        index: 0,
                        child:
                            _DepartmentHeroCard(department: widget.department),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _Staggered(
                        index: 1,
                        child: _ThemedSearchField(
                          hint: 'Search by name or role',
                          onChanged: (q) =>
                              setState(() => _query = q.toLowerCase()),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Staggered(
                        index: 2,
                        child: _MemberFilterRow(
                          selected: _filter,
                          onSelect: (f) => setState(() => _filter = f),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<TeamMember>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      sliver: SliverList.separated(
                        itemCount: 4,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, __) =>
                            const SkeletonLoader(height: 72),
                      ),
                    );
                  }
                  final allMembers = snapshot.data!;
                  final members = _applyFilterAndSearch(allMembers);
                  final maxTools = allMembers.isEmpty
                      ? 1
                      : allMembers
                          .map((m) => m.toolsUsed)
                          .reduce((a, b) => a > b ? a : b)
                          .clamp(1, 1 << 30);
                  if (members.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: 'No members found',
                        message: _query.isEmpty && _filter == _MemberFilter.all
                            ? 'This department has no members yet.'
                            : 'Try a different search term or filter.',
                        icon: Icons.search_off_rounded,
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, 100),
                    sliver: SliverList.separated(
                      key: ValueKey('${_filter}_$_query'),
                      itemCount: members.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        return _Staggered(
                          key: ValueKey(members[i].name),
                          index: i + 3,
                          child: _MemberCard(
                            member: members[i],
                            maxTools: maxTools,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen header — matches Teams/Approvals header pattern.
// ---------------------------------------------------------------------------
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.colors, required this.title});
  final AppColorsData colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.arrow_back_rounded,
                color: colors.textSecondary, size: 20),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h1(colors.textPrimary)),
              const SizedBox(height: 2),
              Text('Team roster',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
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
// THEMED SEARCH FIELD — same treatment as the Teams list screen: animated
// focus border/icon in the app's accent color instead of a flat black one.
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
          Icon(Icons.search_rounded,
              color: _focused ? colors.primary : colors.textSecondary,
              size: 20),
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
// MEMBER FILTER ROW — All / High spend / Most tools.
// ---------------------------------------------------------------------------
class _MemberFilterRow extends StatelessWidget {
  const _MemberFilterRow({required this.selected, required this.onSelect});
  final _MemberFilter selected;
  final ValueChanged<_MemberFilter> onSelect;

  static const _labels = {
    _MemberFilter.all: 'All',
    _MemberFilter.highSpend: 'High spend',
    _MemberFilter.mostTools: 'Most tools',
  };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _MemberFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final key = _MemberFilter.values[i];
          final isSelected = key == selected;
          return _ScaleOnTap(
            onTap: () => onSelect(key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? colors.primaryLight : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? colors.primary : colors.border),
              ),
              alignment: Alignment.center,
              child: Text(_labels[key]!,
                  style: AppTypography.caption(
                          isSelected ? colors.primary : colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
          );
        },
      ),
    );
  }
}

final _amountFormat = NumberFormat('#,##0');
String _formatAmount(double value) => _amountFormat.format(value);
String _compactCurrency(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return _formatAmount(value);
}

// ---------------------------------------------------------------------------
// DEPARTMENT HERO — gradient card summarizing the department: lead,
// members, spend, health status.
// ---------------------------------------------------------------------------
class _DepartmentHeroCard extends StatelessWidget {
  const _DepartmentHeroCard({required this.department});
  final DepartmentSummary department;

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
    final team = department.team;
    final statusColor = _healthColor(colors, department.health);

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
                  child: Text('Led by ${department.leadName}',
                      style: AppTypography.h3(Colors.white)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(_healthLabels[department.health]!,
                          style: AppTypography.caption(Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedCounterText(
                      target: team.memberCount,
                      style: AppTypography.display(Colors.white),
                    ),
                    Text('team members',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.currency_rupee_rounded,
                            color: Colors.white, size: 18),
                        Text(_compactCurrency(team.spend),
                            style: AppTypography.h2(Colors.white)),
                      ],
                    ),
                    Text('total spend',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  const _AnimatedCounterText({
    required this.target,
    required this.style,
  });

  final int target;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text('$value', style: style),
    );
  }
}

// ---------------------------------------------------------------------------
// MEMBER CARD — colored initials avatar, role, spend (icon + digits,
// never a raw currency-symbol string), tools-used chip.
// ---------------------------------------------------------------------------
const List<Color> _kAvatarPalette = [
  Color(0xFF6C5CE7),
  Color(0xFF2F80ED),
  Color(0xFFE85D75),
  Color(0xFFF2994A),
  Color(0xFF11998E),
  Color(0xFF9B51E0),
];

Color _avatarColorFor(String name) {
  final hash = name.codeUnits.fold<int>(0, (sum, c) => sum + c);
  return _kAvatarPalette[hash % _kAvatarPalette.length];
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, required this.maxTools});
  final TeamMember member;
  final int maxTools;

  void _showDetails(BuildContext context) {
    final colors = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: AppTypography.h3(colors.textPrimary)),
              const SizedBox(height: 2),
              Text(member.role, style: AppTypography.caption(colors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      size: 16, color: colors.textPrimary),
                  Text(_formatAmount(member.aiSpend),
                      style: AppTypography.h3(colors.textPrimary)),
                  const Spacer(),
                  Text('AI spend', style: AppTypography.caption(colors.textSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('${member.toolsUsed}',
                      style: AppTypography.h3(colors.textPrimary)),
                  const Spacer(),
                  Text('Tools used', style: AppTypography.caption(colors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = _avatarColorFor(member.name);
    final initials = member.name.isNotEmpty
        ? member.name
            .trim()
            .split(RegExp(r'\s+'))
            .map((e) => e[0])
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final usageRatio = maxTools <= 0 ? 0.0 : (member.toolsUsed / maxTools).clamp(0.0, 1.0);

    return _ScaleOnTap(
      onTap: () => _showDetails(context),
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _UsageRing(
            ratio: usageRatio,
            color: colors.primary,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
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
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(member.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      size: 13, color: colors.textPrimary),
                  Text(_formatAmount(member.aiSpend),
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${member.toolsUsed} tools',
                    style: AppTypography.caption(colors.primary)
                        .copyWith(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// USAGE RING — small ring around the avatar showing this member's tool
// usage relative to the rest of the roster (reuses the hero card's
// circular-progress ring pattern at a smaller size).
// ---------------------------------------------------------------------------
class _UsageRing extends StatelessWidget {
  const _UsageRing(
      {required this.ratio, required this.color, required this.child});
  final double ratio;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 3,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(colors.border),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}