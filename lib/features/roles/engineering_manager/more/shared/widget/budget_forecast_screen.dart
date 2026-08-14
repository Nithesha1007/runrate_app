import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Budget & Forecast
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
  const _ToolSpend(this.name, this.monthlyCost, this.percentOfBudget);
  final String name;
  final double monthlyCost;
  final double percentOfBudget;
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
  final List<_ToolSpend> _toolBreakdown = const [
    _ToolSpend('GitHub Copilot', 62000, 17.4),
    _ToolSpend('Claude', 48000, 13.5),
    _ToolSpend('ChatGPT', 41000, 11.5),
    _ToolSpend('Gemini', 19000, 5.3),
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
        ],
      ),
    );
  }
}

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
        ((allocatedBudget - currentSpend).clamp(0, double.infinity)) as double;
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

class _BurnRateTrendCard extends StatelessWidget {
  const _BurnRateTrendCard({required this.history});
  final List<double> history;

  static const _months = ['Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug'];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final maxValue = history.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Burn rate — last 6 months',
              style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < history.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: history[i] / maxValue),
                            duration: Duration(milliseconds: 500 + i * 80),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return Container(
                                height: 84 * value,
                                decoration: BoxDecoration(
                                  color: i == history.length - 1
                                      ? colors.primary
                                      : colors.primary.withValues(alpha: 0.35),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          Text(_months[i],
                              style:
                                  AppTypography.caption(colors.textSecondary)),
                        ],
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quarter Forecast', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projected spend',
                        style: AppTypography.caption(colors.textSecondary)),
                    RupeeAmount(
                        amount: forecastedQuarter,
                        style: AppTypography.bodyLarge(colors.textPrimary)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Allocated',
                        style: AppTypography.caption(colors.textSecondary)),
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
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'At the current burn rate, you\'ll use ${quarterPercent.toStringAsFixed(0)}% '
              'of the quarterly budget by month 3.',
              style:
                  AppTypography.body(colors.textPrimary).copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBreakdownCard extends StatelessWidget {
  const _ToolBreakdownCard({required this.tools});
  final List<_ToolSpend> tools;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Per-tool spend', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          for (final tool in tools) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(tool.name,
                        style: AppTypography.body(colors.textPrimary)),
                  ),
                  RupeeAmount(
                      amount: tool.monthlyCost,
                      style: AppTypography.body(colors.textPrimary)),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${tool.percentOfBudget.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: AppTypography.caption(colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
