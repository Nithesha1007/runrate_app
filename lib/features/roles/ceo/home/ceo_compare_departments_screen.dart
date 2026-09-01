// ceo_compare_departments_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'ceo_home_cubit.dart';
import 'ceo_home_screen.dart' show kDeptBrands, DeptBrand;

enum _SortBy { spend, utilization, adoption }

/// Full-screen destination for the "Compare Departments" quick action.
///
/// v2 — futuristic redesign, matching the Budget Forecast screen's
/// language (dark glass hero, glow orbs, custom-painted charts, animated
/// counters). Same data and sort behavior as before — sort every
/// department by spend, budget utilization, or AI adoption — plus:
///   - a dark glass hero with live totals and a custom-painted grouped
///     bar chart comparing every department's budget utilization at a
///     glance
///   - department cards get a status-colored glow + left accent bar,
///     a circular adoption ring, and an animated spend-vs-budget bar
class CeoCompareDepartmentsScreen extends StatefulWidget {
  const CeoCompareDepartmentsScreen({super.key, required this.departments});

  final List<DepartmentSummary> departments;

  @override
  State<CeoCompareDepartmentsScreen> createState() =>
      _CeoCompareDepartmentsScreenState();
}

class _CeoCompareDepartmentsScreenState
    extends State<CeoCompareDepartmentsScreen> {
  _SortBy _sortBy = _SortBy.utilization;

  List<DepartmentSummary> get _sorted {
    final list = [...widget.departments];
    switch (_sortBy) {
      case _SortBy.spend:
        list.sort((a, b) => b.spend.compareTo(a.spend));
      case _SortBy.utilization:
        list.sort((a, b) => b.utilization.compareTo(a.utilization));
      case _SortBy.adoption:
        list.sort((a, b) => b.adoptionRate.compareTo(a.adoptionRate));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final departments = _sorted;
    final overBudget =
        widget.departments.where((d) => d.utilization >= 0.95).length;
    final underBudget =
        widget.departments.where((d) => d.utilization < 0.6).length;
    final avgAdoption = widget.departments.isEmpty
        ? 0.0
        : widget.departments.fold<double>(0, (s, d) => s + d.adoptionRate) /
            widget.departments.length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Compare Departments'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        children: [
          _CompareHeroPanel(
            departments: widget.departments,
            overBudget: overBudget,
            underBudget: underBudget,
            avgAdoption: avgAdoption,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Text('Sort by', style: AppTypography.caption(colors.textSecondary)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _SortChip(
                        label: 'Budget used',
                        selected: _sortBy == _SortBy.utilization,
                        onTap: () =>
                            setState(() => _sortBy = _SortBy.utilization),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _SortChip(
                        label: 'Spend',
                        selected: _sortBy == _SortBy.spend,
                        onTap: () => setState(() => _sortBy = _SortBy.spend),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      _SortChip(
                        label: 'Adoption',
                        selected: _sortBy == _SortBy.adoption,
                        onTap: () =>
                            setState(() => _sortBy = _SortBy.adoption),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < departments.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 380 + i * 80),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, (1 - value) * 14), child: child),
                ),
                child: _CompareRow(dept: departments[i]),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO PANEL — dark glass, glow orbs, live counters, grouped bar chart
// comparing every department's budget utilization.
// ---------------------------------------------------------------------------
class _CompareHeroPanel extends StatelessWidget {
  const _CompareHeroPanel({
    required this.departments,
    required this.overBudget,
    required this.underBudget,
    required this.avgAdoption,
  });

  final List<DepartmentSummary> departments;
  final int overBudget;
  final int underBudget;
  final double avgAdoption;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B0F2B), Color(0xFF161B4D), Color(0xFF0B0F2B)],
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -30,
            child: _GlowOrb(color: colors.secondary, size: 160),
          ),
          Positioned(
            bottom: -50,
            right: -40,
            child: _GlowOrb(color: colors.primary, size: 180),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0.1, sigmaY: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.insights_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('Live comparison',
                                style: AppTypography.caption(Colors.white)
                                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text('${departments.length} departments',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          label: 'Over budget',
                          value: '$overBudget',
                          color: const Color(0xFFFF6B6B),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.12)),
                      Expanded(
                        child: _HeroStat(
                          label: 'Under 60% used',
                          value: '$underBudget',
                          color: const Color(0xFF38EF7D),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 32,
                          color: Colors.white.withValues(alpha: 0.12)),
                      Expanded(
                        child: _HeroStat(
                          label: 'Avg adoption',
                          value: '${(avgAdoption * 100).toInt()}%',
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Budget utilization by department',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    height: 84,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) => CustomPaint(
                        painter: _UtilizationBarsPainter(
                          departments: departments,
                          progress: progress,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(
              begin: 0, end: double.tryParse(value.replaceAll('%', '')) ?? 0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            value.contains('%')
                ? '${animated.toInt()}%'
                : '${animated.toInt()}',
            style: AppTypography.h2(Colors.white).copyWith(
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.5), blurRadius: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: AppTypography.caption(Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

/// Grouped vertical bars — one per department — showing budget utilization
/// as a fraction of a 100% reference line, color-coded by status.
class _UtilizationBarsPainter extends CustomPainter {
  _UtilizationBarsPainter({required this.departments, required this.progress});

  final List<DepartmentSummary> departments;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (departments.isEmpty) return;
    const gap = 8.0;
    final barWidth =
        (size.width - gap * (departments.length - 1)) / departments.length;

    // 100% reference line
    final refY = size.height * 0.08;
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, refY), Offset(size.width, refY), refPaint);

    for (var i = 0; i < departments.length; i++) {
      final dept = departments[i];
      final x = i * (barWidth + gap);
      final fraction = dept.utilization.clamp(0.0, 1.2) / 1.2;
      final barHeight = size.height * fraction * progress;

      final color = dept.utilization >= 0.95
          ? const Color(0xFFFF6B6B)
          : dept.utilization >= 0.8
              ? const Color(0xFFF2C94C)
              : const Color(0xFF38EF7D);

      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      );
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withValues(alpha: 0.45)],
        ).createShader(Rect.fromLTWH(x, size.height - barHeight, barWidth, barHeight));
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _UtilizationBarsPainter oldDelegate) =>
      oldDelegate.departments != departments || oldDelegate.progress != progress;
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.45), color.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(colors: [colors.primary, colors.secondary])
              : null,
          color: selected ? null : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? Colors.transparent : colors.border),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: AppTypography.caption(
                  selected ? Colors.white : colors.textPrimary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COMPARE ROW — status glow + accent bar, adoption ring, animated
// spend-vs-budget bar.
// ---------------------------------------------------------------------------
class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.dept});

  final DepartmentSummary dept;

  DeptBrand get _brand =>
      kDeptBrands[dept.name] ??
      const DeptBrand(
        initials: 'DP',
        color: Color(0xFF6C5CE7),
        bg: Color(0xFFEFECFD),
        imageUrl: '',
      );

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final statusColor = dept.utilization >= 0.95
        ? colors.danger
        : dept.utilization >= 0.8
            ? colors.warning
            : colors.success;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [statusColor, statusColor.withValues(alpha: 0.3)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _brand.bg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(_brand.initials,
                              style: TextStyle(
                                  color: _brand.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(dept.name,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          width: 34,
                          height: 34,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(
                                    begin: 0, end: dept.adoptionRate.clamp(0, 1)),
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.easeOutCubic,
                                builder: (context, value, _) =>
                                    CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 3.5,
                                  strokeCap: StrokeCap.round,
                                  backgroundColor: colors.border,
                                  valueColor:
                                      AlwaysStoppedAnimation(_brand.color),
                                ),
                              ),
                              Text('${(dept.adoptionRate * 100).toInt()}',
                                  style: AppTypography.caption(colors.textPrimary)
                                      .copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                            child: _ColStat(
                                label: 'Spend',
                                value: '\$${_compact(dept.spend)}',
                                colors: colors)),
                        Expanded(
                            child: _ColStat(
                                label: 'Budget',
                                value: '\$${_compact(dept.budget)}',
                                colors: colors)),
                        Expanded(
                            child: _ColStat(
                                label: 'People',
                                value: '${dept.headcount}',
                                colors: colors)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('${(dept.utilization * 100).toInt()}%',
                              style: AppTypography.caption(statusColor).copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                            begin: 0, end: dept.utilization.clamp(0.0, 1.0)),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          color: statusColor,
                          backgroundColor: colors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColStat extends StatelessWidget {
  const _ColStat(
      {required this.label, required this.value, required this.colors});

  final String label;
  final String value;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: AppTypography.caption(colors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTypography.caption(colors.textSecondary)
                .copyWith(fontSize: 10)),
      ],
    );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}