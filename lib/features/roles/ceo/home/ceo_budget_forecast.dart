// ceo_budget_forecast_screen.dart
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'ceo_home_cubit.dart';

/// Full-screen destination for the "Budget Forecast" quick action.
///
/// v2 — futuristic redesign. Same underlying projection model as before
/// (per-department monthly rate driven by trend direction, compounded
/// forward), but now:
///   - the horizon is adjustable (3 / 6 / 12 months) via a segmented
///     control, which re-drives the chart and every card
///   - a glassmorphic hero shows the projected total inside a glowing
///     dark panel with soft blurred orbs behind it, animated counters,
///     and a confidence ring
///   - a custom-painted gradient area chart traces the monthly
///     projection curve instead of a static number
///   - department rows get a colored glow + left accent bar keyed to
///     trend direction, with an animated current-vs-projected bar
///
/// `_monthlyRateFor` is still the one heuristic in the file — swap it for
/// a real backend projection endpoint when one exists.
class CeoBudgetForecastScreen extends StatefulWidget {
  const CeoBudgetForecastScreen({super.key, required this.data});

  final CeoHomeData data;

  @override
  State<CeoBudgetForecastScreen> createState() =>
      _CeoBudgetForecastScreenState();
}

class _CeoBudgetForecastScreenState extends State<CeoBudgetForecastScreen> {
  int _horizonMonths = 3;

  double _monthlyRateFor(DepartmentTrend trend) {
    switch (trend) {
      case DepartmentTrend.up:
        return 0.08;
      case DepartmentTrend.flat:
        return 0.02;
      case DepartmentTrend.down:
        return -0.05;
    }
  }

  /// Monthly projected spend points for one department, `_horizonMonths`
  /// long (not cumulative — this month's projected spend, each month).
  List<double> _monthlyPoints(DepartmentSummary dept) {
    final rate = _monthlyRateFor(dept.trend);
    var spend = dept.spend;
    final points = <double>[];
    for (var m = 0; m < _horizonMonths; m++) {
      spend *= (1 + rate);
      points.add(spend);
    }
    return points;
  }

  List<double> get _companyMonthlyPoints {
    final points = List<double>.filled(_horizonMonths, 0);
    for (final dept in widget.data.departments) {
      final deptPoints = _monthlyPoints(dept);
      for (var i = 0; i < deptPoints.length; i++) {
        points[i] += deptPoints[i];
      }
    }
    return points;
  }

  double _projectedTotal(DepartmentSummary dept) =>
      _monthlyPoints(dept).fold(0.0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final departments = widget.data.departments;
    final monthlyPoints = _companyMonthlyPoints;
    final projectedTotal = monthlyPoints.fold(0.0, (a, b) => a + b);
    final currentBaseline =
        departments.fold<double>(0, (s, d) => s + d.spend) * _horizonMonths;
    final deltaPct = currentBaseline == 0
        ? 0.0
        : (projectedTotal - currentBaseline) / currentBaseline * 100;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Budget Forecast'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        children: [
          _HorizonSelector(
            selected: _horizonMonths,
            onChanged: (m) => setState(() => _horizonMonths = m),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ForecastHeroPanel(
            projectedTotal: projectedTotal,
            deltaPct: deltaPct,
            horizonMonths: _horizonMonths,
            monthlyPoints: monthlyPoints,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child:
                    Text('By department', style: AppTypography.h3(colors.textPrimary)),
              ),
              Text('$_horizonMonths-mo projection',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < departments.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 420 + i * 90),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                      offset: Offset(0, (1 - value) * 14), child: child),
                ),
                child: _DepartmentForecastCard(
                  dept: departments[i],
                  currentTotal: departments[i].spend * _horizonMonths,
                  projectedTotal: _projectedTotal(departments[i]),
                  monthlyPoints: _monthlyPoints(departments[i]),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Forecast is a model-driven estimate based on current spend and recent trend direction, not a guarantee.',
                  style: AppTypography.caption(colors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HORIZON SELECTOR — 3 / 6 / 12 month segmented control.
// ---------------------------------------------------------------------------
class _HorizonSelector extends StatelessWidget {
  const _HorizonSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  static const _options = [3, 6, 12];

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
        children: _options.map((m) {
          final isSelected = m == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: isSelected
                      ? LinearGradient(colors: [colors.primary, colors.secondary])
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${m}M',
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
// HERO PANEL — dark glass panel, blurred glow orbs, animated total, ring,
// and a gradient area chart tracing the monthly projection curve.
// ---------------------------------------------------------------------------
class _ForecastHeroPanel extends StatelessWidget {
  const _ForecastHeroPanel({
    required this.projectedTotal,
    required this.deltaPct,
    required this.horizonMonths,
    required this.monthlyPoints,
  });

  final double projectedTotal;
  final double deltaPct;
  final int horizonMonths;
  final List<double> monthlyPoints;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isUp = deltaPct >= 0;
    final trendColor = isUp ? const Color(0xFFFF6B6B) : const Color(0xFF38EF7D);

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
                            const Icon(Icons.bolt_rounded,
                                color: Colors.white, size: 12),
                            const SizedBox(width: 4),
                            Text('AI-projected',
                                style: AppTypography.caption(Colors.white)
                                    .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.trending_up_rounded,
                          color: Colors.white.withValues(alpha: 0.5), size: 16),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Projected $horizonMonths-month AI spend',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.7))),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _AnimatedMoneyText(target: projectedTotal),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: trendColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                isUp
                                    ? Icons.arrow_upward_rounded
                                    : Icons.arrow_downward_rounded,
                                color: trendColor,
                                size: 12),
                            Text('${deltaPct.abs().toStringAsFixed(1)}%',
                                style: AppTypography.caption(trendColor)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: 90,
                    width: double.infinity,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 1100),
                      curve: Curves.easeOutCubic,
                      builder: (context, progress, _) => CustomPaint(
                        painter: _AreaChartPainter(
                          points: monthlyPoints,
                          progress: progress,
                          lineColor: Colors.white,
                          fillColorTop: colors.primary.withValues(alpha: 0.55),
                          fillColorBottom: colors.primary.withValues(alpha: 0.0),
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

class _AnimatedMoneyText extends StatelessWidget {
  const _AnimatedMoneyText({required this.target});
  final double target;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text(
        '\$${_compact(value)}',
        style: AppTypography.h1(Colors.white).copyWith(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          shadows: [
            Shadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 18),
          ],
        ),
      ),
    );
  }
}

/// Gradient area/line chart for a monthly points series. `progress` (0..1)
/// animates the line being drawn left-to-right.
class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.points,
    required this.progress,
    required this.lineColor,
    required this.fillColorTop,
    required this.fillColorBottom,
  });

  final List<double> points;
  final double progress;
  final Color lineColor;
  final Color fillColorTop;
  final Color fillColorBottom;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1.0 : (maxVal - minVal);

    final stepX = points.length > 1 ? size.width / (points.length - 1) : size.width;
    final visibleCount = (points.length * progress).clamp(1, points.length).toDouble();

    final coords = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      if (i > visibleCount) break;
      final x = i * stepX;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - (normalized * (size.height - 10)) - 4;
      coords.add(Offset(x, y));
    }
    if (coords.length < 2) return;

    final linePath = Path()..moveTo(coords.first.dx, coords.first.dy);
    for (var i = 1; i < coords.length; i++) {
      final prev = coords[i - 1];
      final curr = coords[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      linePath.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    linePath.lineTo(coords.last.dx, coords.last.dy);

    final fillPath = Path.from(linePath)
      ..lineTo(coords.last.dx, size.height)
      ..lineTo(coords.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillColorTop, fillColorBottom],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    canvas.drawCircle(coords.last, 4, dotPaint);
    canvas.drawCircle(
      coords.last,
      7,
      Paint()..color = lineColor.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}

// ---------------------------------------------------------------------------
// DEPARTMENT FORECAST CARD — glow accent bar keyed to trend, animated
// current-vs-projected comparison bar, mini sparkline.
// ---------------------------------------------------------------------------
class _DepartmentForecastCard extends StatelessWidget {
  const _DepartmentForecastCard({
    required this.dept,
    required this.currentTotal,
    required this.projectedTotal,
    required this.monthlyPoints,
  });

  final DepartmentSummary dept;
  final double currentTotal;
  final double projectedTotal;
  final List<double> monthlyPoints;

  Color _trendColor(AppColorsData colors) => switch (dept.trend) {
        DepartmentTrend.up => colors.danger,
        DepartmentTrend.down => colors.success,
        DepartmentTrend.flat => colors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = _trendColor(colors);
    final deltaPct = currentTotal == 0
        ? 0.0
        : (projectedTotal - currentTotal) / currentTotal * 100;
    final maxOf = projectedTotal > currentTotal ? projectedTotal : currentTotal;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.14),
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
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent, accent.withValues(alpha: 0.3)],
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
                        Expanded(
                          child: Text(dept.name,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        SizedBox(
                          width: 46,
                          height: 22,
                          child: CustomPaint(
                            painter: _SparklinePainter(
                              points: monthlyPoints,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${deltaPct >= 0 ? '+' : ''}${deltaPct.toStringAsFixed(1)}%',
                            style: AppTypography.caption(accent)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text('Now \$${_compact(currentTotal)}',
                            style: AppTypography.caption(colors.textSecondary)),
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.arrow_right_alt_rounded,
                            size: 14, color: colors.textSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Projected \$${_compact(projectedTotal)}',
                            style: AppTypography.caption(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 6,
                        child: Stack(
                          children: [
                            Container(color: colors.border),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0,
                                  end: maxOf == 0 ? 0 : currentTotal / maxOf),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  FractionallySizedBox(
                                widthFactor: value,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                    color: colors.textSecondary.withValues(alpha: 0.4)),
                              ),
                            ),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0,
                                  end: maxOf == 0 ? 0 : projectedTotal / maxOf),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  FractionallySizedBox(
                                widthFactor: value,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                                      accent,
                                      accent.withValues(alpha: 0.6),
                                    ]),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.points, required this.color});
  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final maxVal = points.reduce((a, b) => a > b ? a : b);
    final minVal = points.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).abs() < 1 ? 1.0 : (maxVal - minVal);
    final stepX = size.width / (points.length - 1);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * stepX;
      final normalized = (points[i] - minVal) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}