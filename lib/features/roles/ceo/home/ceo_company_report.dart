// ceo_company_report_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'ceo_home_cubit.dart';
import 'ceo_home_screen.dart' show kDeptBrands, DeptBrand;

/// Full-screen destination for the "Company Report" quick action.
///
/// v2 — futuristic redesign, matching the Budget Forecast and Compare
/// Departments screens (dark glass hero, glow orbs, custom-painted
/// charts, animated counters), so all three quick-action drill-downs now
/// read as one consistent set instead of three different styles.
///
///   - dark glass hero: executive summary + four animated key metrics,
///     plus a custom-painted donut chart showing each department's share
///     of total AI spend
///   - department rows: status-colored glow + accent bar, animated
///     spend-vs-budget progress bar (same visual language as Compare
///     Departments)
///   - AI tool rows: glowing usage-level dot, animated spend bar relative
///     to the top tool
class CeoCompanyReportScreen extends StatelessWidget {
  const CeoCompanyReportScreen({super.key, required this.data});

  final CeoHomeData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final topToolSpend = data.aiToolUsage.isEmpty
        ? 0.0
        : data.aiToolUsage.map((t) => t.spend).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Company Report'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Share report',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing — coming soon')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        children: [
          _ReportHeroPanel(data: data),
          const SizedBox(height: AppSpacing.xl),
          Text('Spend by department', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < data.departments.length; i++)
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
                child: _ReportDepartmentRow(dept: data.departments[i]),
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
          Text('Spend by AI tool', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < data.aiToolUsage.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ReportToolRow(
                tool: data.aiToolUsage[i],
                maxSpend: topToolSpend,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO PANEL — dark glass, glow orbs, exec summary, animated metrics grid,
// donut chart of department spend share.
// ---------------------------------------------------------------------------
class _ReportHeroPanel extends StatelessWidget {
  const _ReportHeroPanel({required this.data});

  final CeoHomeData data;

  static const _donutColors = [
    Color(0xFF6C5CE7),
    Color(0xFF2F80ED),
    Color(0xFF11998E),
    Color(0xFFF2994A),
    Color(0xFFE85D75),
    Color(0xFF9B51E0),
  ];

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
            right: -30,
            child: _GlowOrb(color: colors.primary, size: 160),
          ),
          Positioned(
            bottom: -50,
            left: -40,
            child: _GlowOrb(color: colors.secondary, size: 180),
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
                            const Icon(Icons.description_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('Executive rollup',
                                style: AppTypography.caption(Colors.white)
                                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(data.todayLabel,
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.6))),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(data.companyName,
                      style: AppTypography.h2(Colors.white)
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    data.aiExecutiveSummary,
                    style: AppTypography.body(Colors.white.withValues(alpha: 0.78)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 92,
                        height: 92,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, _) => CustomPaint(
                            painter: _DonutPainter(
                              departments: data.departments,
                              colors: _donutColors,
                              progress: progress,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('\$${_compact(data.totalSpend)}',
                                      style: AppTypography.caption(Colors.white)
                                          .copyWith(fontWeight: FontWeight.w800)),
                                  Text('total',
                                      style: AppTypography.caption(
                                          Colors.white.withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.xs,
                          children: [
                            for (var i = 0; i < data.departments.length; i++)
                              _LegendChip(
                                label: data.departments[i].name,
                                color: _donutColors[i % _donutColors.length],
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroMetric(
                          label: 'Remaining',
                          value: '\$${_compact(data.remainingBudget)}',
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.12)),
                      Expanded(
                        child: _HeroMetric(
                          label: 'AI ROI',
                          value: '${data.roiScore.toInt()}',
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 30,
                          color: Colors.white.withValues(alpha: 0.12)),
                      Expanded(
                        child: _HeroMetric(
                          label: 'Active users',
                          value: '${data.totalActiveUsers}',
                        ),
                      ),
                    ],
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

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final numeric =
        double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final prefix = value.startsWith('\$') ? '\$' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: numeric),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Text(
            prefix.isEmpty
                ? '${animated.toInt()}'
                : '$prefix${_compact(animated)}',
            style: AppTypography.h3(Colors.white).copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        Text(label, style: AppTypography.caption(Colors.white.withValues(alpha: 0.65))),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
      ],
    );
  }
}

/// Donut chart of each department's share of total spend.
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.departments,
    required this.colors,
    required this.progress,
  });

  final List<DepartmentSummary> departments;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (departments.isEmpty) return;
    final total = departments.fold<double>(0, (s, d) => s + d.spend);
    if (total <= 0) return;

    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    const strokeWidth = 11.0;
    var startAngle = -math.pi / 2;

    for (var i = 0; i < departments.length; i++) {
      final sweep = (departments[i].spend / total) * 2 * math.pi * progress;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += (departments[i].spend / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
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

// ---------------------------------------------------------------------------
// DEPARTMENT ROW — status glow + accent bar, animated spend-vs-budget bar.
// ---------------------------------------------------------------------------
class _ReportDepartmentRow extends StatelessWidget {
  const _ReportDepartmentRow({required this.dept});

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                    const BorderRadius.horizontal(left: Radius.circular(18)),
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
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: _brand.bg,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          alignment: Alignment.center,
                          child: Text(_brand.initials,
                              style: TextStyle(
                                  color: _brand.color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11)),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(dept.name,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        Text('\$${_compact(dept.spend)} ',
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text('/ \$${_compact(dept.budget)}',
                            style: AppTypography.caption(colors.textSecondary)),
                        const SizedBox(width: AppSpacing.sm),
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

// ---------------------------------------------------------------------------
// AI TOOL ROW — glowing usage-level dot, animated bar relative to top tool.
// ---------------------------------------------------------------------------
class _ReportToolRow extends StatelessWidget {
  const _ReportToolRow({required this.tool, required this.maxSpend});

  final AiToolUsage tool;
  final double maxSpend;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final levelColor = switch (tool.usageLevel) {
      AiUsageLevel.high => colors.success,
      AiUsageLevel.medium => colors.warning,
      AiUsageLevel.low => colors.danger,
    };
    final fraction = maxSpend == 0 ? 0.0 : tool.spend / maxSpend;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: levelColor.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: levelColor.withValues(alpha: 0.6), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(tool.toolName,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
              Text('${tool.userCount} users  ',
                  style: AppTypography.caption(colors.textSecondary)),
              Text('\$${_compact(tool.spend)}',
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 5,
                color: levelColor,
                backgroundColor: colors.border,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}