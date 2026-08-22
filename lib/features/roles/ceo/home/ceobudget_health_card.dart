// ceo_budget_health_card.dart
//
// Drop-in replacement for the private `_BudgetHealthCard` widget in
// ceo_home_screen.dart.
//
// v3 — a full redesign, not a tweak. v2's light card with 4 icon tiles was
// functional but visually flat and disconnected from the rest of the page;
// it also looked like a smaller, less important cousin of the gradient
// "Company AI overview" hero card above it on Home. This version borrows
// that hero card's dark-gradient language directly — big gauge, bold
// numbers, glass footer chips — so budget health reads as an equally
// important, premium metric instead of an afterthought below it.
//
// Overflow safety is unchanged from v2: every value sits in a FittedBox and
// every tile/chip is intrinsically sized (Column/Row with mainAxisSize.min),
// so nothing can be shorter than its own content.
//
// USAGE — in ceo_home_screen.dart:
//   1. Add: import 'ceo_budget_health_card.dart';
//   2. Replace `_BudgetHealthCard(data: data.budgetHealth)` with
//      `CeoBudgetHealthCard(data: data.budgetHealth)`.

import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'ceo_home_cubit.dart' show CeoBudgetHealthData;

enum BudgetHealthStatus { healthy, warning, critical }

BudgetHealthStatus budgetHealthStatusFor(double utilization) {
  if (utilization >= 0.95) return BudgetHealthStatus.critical;
  if (utilization >= 0.8) return BudgetHealthStatus.warning;
  return BudgetHealthStatus.healthy;
}
String budgetHealthLabelFor(BudgetHealthStatus status) => switch (status) {
      BudgetHealthStatus.healthy => 'Healthy',
      BudgetHealthStatus.warning => 'Warning',
      BudgetHealthStatus.critical => 'Critical',
    };
class CeoBudgetHealthCard extends StatelessWidget {
  const CeoBudgetHealthCard({super.key, required this.data});
  final CeoBudgetHealthData data;
  static const _bgTop = Color(0xFF15192E);
  static const _bgBottom = Color(0xFF23294A);

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);
    final status = budgetHealthStatusFor(data.utilization);
    final statusColor = switch (status) {
      BudgetHealthStatus.healthy => const Color(0xFF3DDC84),
      BudgetHealthStatus.warning => const Color(0xFFFFC24B),
      BudgetHealthStatus.critical => const Color(0xFFFF6B6B),
    };
    final forecastUp = data.forecast >= data.utilization;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgTop, _bgBottom],
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Company budget health',
                    style: AppTypography.h3(Colors.white)),
              ),
              _StatusPill(
                  label: budgetHealthLabelFor(status), color: statusColor),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _UtilizationGauge(
                utilization: data.utilization,
                ringColor: statusColor,
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '\$${_compact(data.used)}',
                              style: AppTypography.h1(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w800),
                            ),
                            TextSpan(
                              text: ' / \$${_compact(data.budget)}',
                              style: AppTypography.body(
                                      Colors.white.withValues(alpha: 0.6))
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('spent this cycle',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.65))),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          forecastUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Forecast ${(data.forecast * 100).toInt()}% by month-end',
                            style: AppTypography.caption(
                                Colors.white.withValues(alpha: 0.8)),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SpendBar(
            spend: data.used,
            remaining: data.remaining,
            spendColor: statusColor,
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _GlassChip(
                  icon: Icons.savings_rounded,
                  label: 'Remaining',
                  value: '\$${_compact(data.remaining)}',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GlassChip(
                  icon: Icons.event_available_rounded,
                  label: 'Month-end est.',
                  value: '\$${_compact(data.expectedMonthEndSpend)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Gauge
// -----------------------------------------------------------------------
class _UtilizationGauge extends StatelessWidget {
  const _UtilizationGauge({required this.utilization, required this.ringColor});
  final double utilization;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              valueColor: AlwaysStoppedAnimation(
                  Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: utilization.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(ringColor),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: utilization.clamp(0.0, 1.4)),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  '${(value * 100).toInt()}%',
                  style: AppTypography.h3(Colors.white),
                ),
              ),
              Text('used',
                  style: AppTypography.caption(
                      Colors.white.withValues(alpha: 0.6))),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// Spend bar — a single stacked bar (spend vs remaining) with a small
// legend, instead of a plain LinearProgressIndicator, so the redesign
// reads as a different component and not just a recolored old one.
// -----------------------------------------------------------------------
class _SpendBar extends StatelessWidget {
  const _SpendBar({
    required this.spend,
    required this.remaining,
    required this.spendColor,
  });

  final double spend;
  final double remaining;
  final Color spendColor;

  @override
  Widget build(BuildContext context) {
    final total = spend + remaining;
    final fraction = total <= 0 ? 0.0 : (spend / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 10,
            child: Stack(
              children: [
                Container(color: Colors.white.withValues(alpha: 0.10)),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: fraction),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            spendColor,
                            spendColor.withValues(alpha: 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _LegendDot(color: spendColor, label: 'Spend \$${_compact(spend)}'),
            const SizedBox(width: AppSpacing.md),
            _LegendDot(
                color: Colors.white.withValues(alpha: 0.25),
                label: 'Remaining \$${_compact(remaining)}'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

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
        Flexible(
          child: Text(
            label,
            style: AppTypography.caption(Colors.white.withValues(alpha: 0.75)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------
// Glass footer chip — intrinsically sized + FittedBox value, so it can
// never overflow regardless of text-scale settings or number length.
// -----------------------------------------------------------------------
class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption(
                      Colors.white.withValues(alpha: 0.65)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AppTypography.body(Colors.white)
                  .copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
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
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
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
          Text(label,
              style: AppTypography.caption(Colors.white)
                  .copyWith(fontWeight: FontWeight.w700)),
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