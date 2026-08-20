import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Budget & Forecast (Premium / Futuristic rebuild)
///
/// Keeps `EmGradientHero`, `RupeeAmount`, `StatusPill`, `StatusTone` from
/// `em_shared_widget.dart` since those are shared across other EM screens
/// and already carry the hero gradient — redesigning those here would
/// desync the look everywhere else they're used. Everything below that
/// (trend card, forecast card, per-tool card) is rebuilt local to this
/// file with a glass / neon-accent treatment matching the new
/// Notifications screen.
///
/// TODO — IMPORTANT: the numbers on this screen (`_currentSpend`,
/// `_allocatedBudget`, `_monthlyBurn`, `_monthlyHistory`,
/// `_toolBreakdown`) are local mock fields so this screen compiles and
/// looks right standalone. Per the build spec, these must come from the
/// SAME source already powering EM Home/Teams (e.g.
/// `EngineeringManagerHomeCubit` / `EngineeringManagerTeamsCubit`) so
/// figures never drift out of sync across screens. Wire a
/// `BlocBuilder`/`context.watch` on that cubit here and delete the
/// mock fields once the real fields are confirmed.
class BudgetForecastScreen extends StatefulWidget {
  const BudgetForecastScreen({super.key});

  @override
  State<BudgetForecastScreen> createState() => _BudgetForecastScreenState();
}

class _ToolSpend {
  const _ToolSpend(
      this.name, this.monthlyCost, this.percentOfBudget, this.accent);
  final String name;
  final double monthlyCost;
  final double percentOfBudget;
  final Color Function(AppColorsData) accent;
}

class _BudgetForecastScreenState extends State<BudgetForecastScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 4;

  // Mock data — see TODO above.
  final double _allocatedBudget = 500000;
  final double _currentSpend = 356000;
  final double _monthlyBurn = 118000;
  final List<double> _monthlyHistory = const [
    82000,
    95000,
    101000,
    108000,
    112000,
    118000
  ];
  final List<_ToolSpend> _toolBreakdown = [
    _ToolSpend('GitHub Copilot', 62000, 17.4, (c) => c.primary),
    _ToolSpend('Claude', 48000, 13.5, (c) => c.secondary),
    _ToolSpend('ChatGPT', 41000, 11.5, (c) => c.info),
    _ToolSpend('Gemini', 19000, 5.3, (c) => c.warning),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  double get _utilization => (_currentSpend / _allocatedBudget).clamp(0, 1.5);
  double get _forecastedMonthEnd => _currentSpend + _monthlyBurn * 0.4;
  double get _forecastedQuarter => _monthlyBurn * 3;

  (String, StatusTone) get _status {
    if (_utilization >= 1.0) return ('Over Budget', StatusTone.critical);
    if (_utilization >= 0.85) return ('Near Limit', StatusTone.warning);
    return ('On Track', StatusTone.positive);
  }

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusTone) = _status;
    final quarterPercent =
        (_forecastedQuarter / (_allocatedBudget * 1.2) * 100).clamp(0, 999);

    return EmScreenScaffold(
      title: 'Budget & Forecast',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFade(
            index: 0,
            total: _blockCount,
            controller: _entrance,
            child: _BudgetHero(
              currentSpend: _currentSpend,
              allocatedBudget: _allocatedBudget,
              burnRate: _monthlyBurn,
              forecastedMonthEnd: _forecastedMonthEnd,
              utilization: _utilization,
              statusLabel: statusLabel,
              statusTone: statusTone,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 1,
            total: _blockCount,
            controller: _entrance,
            child: _BurnRateTrendCard(history: _monthlyHistory),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 2,
            total: _blockCount,
            controller: _entrance,
            child: _QuarterForecastCard(
              forecastedQuarter: _forecastedQuarter,
              allocatedQuarterBudget: _allocatedBudget * 1.2,
              quarterPercent: quarterPercent.toDouble(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 3,
            total: _blockCount,
            controller: _entrance,
            child: _ToolBreakdownCard(tools: _toolBreakdown),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Hero — unchanged shared widget, just fed the same data
// ─────────────────────────────────────────────────────────────────────────

class _BudgetHero extends StatelessWidget {
  const _BudgetHero({
    required this.currentSpend,
    required this.allocatedBudget,
    required this.burnRate,
    required this.forecastedMonthEnd,
    required this.utilization,
    required this.statusLabel,
    required this.statusTone,
  });

  final double currentSpend;
  final double allocatedBudget;
  final double burnRate;
  final double forecastedMonthEnd;
  final double utilization;
  final String statusLabel;
  final StatusTone statusTone;

  @override
  Widget build(BuildContext context) {
    final remaining =
        (allocatedBudget - currentSpend).clamp(0, double.infinity).toDouble();
    return EmGradientHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current spend',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.85))),
                    const SizedBox(height: 2),
                    RupeeAmount(
                      amount: currentSpend,
                      style: AppTypography.h1(Colors.white),
                      iconColor: Colors.white,
                    ),
                  ],
                ),
              ),
              StatusPill(label: statusLabel, tone: statusTone),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: utilization.clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _HeroStat(label: 'Remaining', amount: remaining),
              _HeroStat(label: 'Burn rate/mo', amount: burnRate),
              _HeroStat(
                  label: 'Month-end forecast', amount: forecastedMonthEnd),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.amount});
  final String label;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 2),
          RupeeAmount(
            amount: amount,
            compact: true,
            iconColor: Colors.white,
            style: AppTypography.bodyLarge(Colors.white)
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Shared glass-card shell + section label, matching the Notifications look
// ─────────────────────────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.colors,
    required this.title,
    required this.accent,
    required this.child,
    this.trailing,
  });

  final AppColorsData colors;
  final String title;
  final Color accent;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.textPrimary.withOpacity(0.05),
                colors.textPrimary.withOpacity(0.02),
              ],
            ),
            border: Border.all(
              color: colors.textSecondary.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Burn rate trend — glowing gradient bars
// ─────────────────────────────────────────────────────────────────────────

class _BurnRateTrendCard extends StatelessWidget {
  const _BurnRateTrendCard({required this.history});
  final List<double> history;

  static const _months = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final maxValue = history.reduce((a, b) => a > b ? a : b);
    final momChange = ((history.last - history[history.length - 2]) /
        history[history.length - 2] *
        100);

    return _GlassCard(
      colors: colors,
      title: 'Burn rate — last 6 months',
      accent: colors.primary,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            momChange >= 0
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            size: 13,
            color: momChange >= 0 ? colors.warning : colors.info,
          ),
          const SizedBox(width: 2),
          Text(
            '${momChange.abs().toStringAsFixed(0)}% MoM',
            style: TextStyle(
              color: momChange >= 0 ? colors.warning : colors.info,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      child: SizedBox(
        height: 132,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < history.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _compact(history[i]),
                        style: TextStyle(
                          color: i == history.length - 1
                              ? colors.primary
                              : colors.textSecondary,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: history[i] / maxValue),
                        duration: Duration(milliseconds: 550 + i * 90),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          final isLast = i == history.length - 1;
                          return Container(
                            height: 84 * value,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: isLast
                                    ? [
                                        colors.primary,
                                        colors.primary.withOpacity(0.55),
                                      ]
                                    : [
                                        colors.primary.withOpacity(0.28),
                                        colors.primary.withOpacity(0.12),
                                      ],
                              ),
                              boxShadow: isLast
                                  ? [
                                      BoxShadow(
                                        color: colors.primary.withOpacity(0.5),
                                        blurRadius: 12,
                                        spreadRadius: 0.5,
                                      ),
                                    ]
                                  : [],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(_months[i],
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 11,
                            fontWeight: i == history.length - 1
                                ? FontWeight.w700
                                : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _compact(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Quarter forecast — radial progress ring + gradient callout
// ─────────────────────────────────────────────────────────────────────────

class _QuarterForecastCard extends StatelessWidget {
  const _QuarterForecastCard({
    required this.forecastedQuarter,
    required this.allocatedQuarterBudget,
    required this.quarterPercent,
  });

  final double forecastedQuarter;
  final double allocatedQuarterBudget;
  final double quarterPercent;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final ringColor = quarterPercent >= 100 ? colors.warning : colors.info;

    return _GlassCard(
      colors: colors,
      title: 'Quarter forecast',
      accent: colors.info,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: (quarterPercent / 100).clamp(0, 1)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CustomPaint(
                  size: const Size(72, 72),
                  painter: _RingPainter(
                    progress: value,
                    trackColor: colors.textSecondary.withOpacity(0.10),
                    progressColor: ringColor,
                  ),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: Center(
                      child: Text(
                        '${quarterPercent.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projected spend',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12)),
                    RupeeAmount(
                        amount: forecastedQuarter,
                        style: AppTypography.bodyLarge(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text('Allocated',
                        style: TextStyle(
                            color: colors.textSecondary, fontSize: 12)),
                    RupeeAmount(
                        amount: allocatedQuarterBudget,
                        style: AppTypography.bodyLarge(colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  colors.info.withOpacity(0.16),
                  colors.info.withOpacity(0.06),
                ],
              ),
              border: Border.all(color: colors.info.withOpacity(0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.bolt_rounded, size: 16, color: colors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'At the current burn rate, you\'ll use '
                    '${quarterPercent.toStringAsFixed(0)}% of the quarterly '
                    'budget by month 3.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;
    const strokeWidth = 7.0;

    final track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, track);

    final glow = Paint()
      ..color = progressColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 3
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final fg = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress.clamp(0, 1);
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    if (progress > 0) {
      canvas.drawArc(rect, start, sweep, false, glow);
      canvas.drawArc(rect, start, sweep, false, fg);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.progressColor != progressColor;
}

// ─────────────────────────────────────────────────────────────────────────
// Per-tool spend — colored dot + inline bar per row
// ─────────────────────────────────────────────────────────────────────────

class _ToolBreakdownCard extends StatelessWidget {
  const _ToolBreakdownCard({required this.tools});
  final List<_ToolSpend> tools;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final maxPercent =
        tools.map((t) => t.percentOfBudget).reduce((a, b) => a > b ? a : b);

    return _GlassCard(
      colors: colors,
      title: 'Per-tool spend',
      accent: colors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            _ToolRow(
              tool: tools[i],
              colors: colors,
              accent: tools[i].accent(colors),
              fraction: tools[i].percentOfBudget / maxPercent,
              delayMs: i * 90,
            ),
            if (i != tools.length - 1) const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  const _ToolRow({
    required this.tool,
    required this.colors,
    required this.accent,
    required this.fraction,
    required this.delayMs,
  });

  final _ToolSpend tool;
  final AppColorsData colors;
  final Color accent;
  final double fraction;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(tool.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            RupeeAmount(
              amount: tool.monthlyCost,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 42,
              child: Text(
                '${tool.percentOfBudget.toStringAsFixed(1)}%',
                textAlign: TextAlign.right,
                style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 5,
            color: colors.textSecondary.withOpacity(0.08),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
              duration: Duration(milliseconds: 600 + delayMs),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      colors: [accent, accent.withOpacity(0.55)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.45),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
