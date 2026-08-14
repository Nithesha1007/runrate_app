import 'package:flutter/material.dart';
import 'package:runrate/core/theme/app_colors_data.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/toast.dart';

enum BoardReportStatus { draft, final_ }

extension BoardReportStatusX on BoardReportStatus {
  String get label =>
      this == BoardReportStatus.draft ? 'Draft' : 'Final';
}

class BoardReport {
  const BoardReport({
    required this.period,
    required this.summary,
    required this.status,
  });

  final String period;
  final String summary;
  final BoardReportStatus status;
}

final _mockBoardReports = <BoardReport>[
  BoardReport(
    period: 'Q3 2026',
    summary:
        'Revenue up 14% QoQ with disciplined spend growth across all '
        'departments; AI Copilot adoption crossed 60% of active teams.',
    status: BoardReportStatus.draft,
  ),
  BoardReport(
    period: 'Q2 2026',
    summary:
        'Operating margin held steady despite headcount growth in '
        'Engineering; approvals cycle time dropped by two days on average.',
    status: BoardReportStatus.final_,
  ),
  BoardReport(
    period: 'Q1 2026',
    summary:
        'Kicked off the year with a renewed budget framework across '
        'departments and completed the SOC 2 compliance audit on schedule.',
    status: BoardReportStatus.final_,
  ),
  BoardReport(
    period: 'Q4 2025',
    summary:
        'Closed the fiscal year ahead of target with strong retention '
        'across enterprise accounts and a healthy cash runway.',
    status: BoardReportStatus.final_,
  ),
];

/// Board Reports — quarterly, investor-ready report cards with a status
/// badge and View / Share / Export PDF actions.
class CeoBoardReportsScreen extends StatefulWidget {
  const CeoBoardReportsScreen({super.key});

  @override
  State<CeoBoardReportsScreen> createState() => _CeoBoardReportsScreenState();
}

class _CeoBoardReportsScreenState extends State<CeoBoardReportsScreen> {
  bool _loading = true;
  List<BoardReport>? _reports;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _reports = _mockBoardReports;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reports = _reports ?? [];
    final finalCount =
        reports.where((r) => r.status == BoardReportStatus.final_).length;
    final latestPeriod = reports.isNotEmpty ? reports.first.period : '—';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: colors.primary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100),
            children: [
              Row(
                children: [
                  _ScaleOnTap(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.border),
                      ),
                      child: Icon(Icons.arrow_back_rounded,
                          color: colors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Board Reports',
                            style: AppTypography.h2(colors.textPrimary)),
                        Text('Quarterly, investor-ready summaries',
                            style:
                                AppTypography.caption(colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              _Staggered(
                index: 0,
                child: _HeroSummary(
                  colors: colors,
                  total: reports.length,
                  finalCount: finalCount,
                  latestPeriod: latestPeriod,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_loading)
                for (var i = 0; i < 3; i++) ...[
                  _SkeletonCard(colors: colors),
                  const SizedBox(height: AppSpacing.md),
                ]
              else if (reports.isEmpty)
                _EmptyState(colors: colors)
              else
                for (var i = 0; i < reports.length; i++) ...[
                  _Staggered(
                    index: i + 1,
                    child: _BoardReportCard(report: reports[i]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({
    required this.colors,
    required this.total,
    required this.finalCount,
    required this.latestPeriod,
  });

  final AppColorsData colors;
  final int total;
  final int finalCount;
  final String latestPeriod;

  @override
  Widget build(BuildContext context) {
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
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$total', style: AppTypography.h1(Colors.white)),
                  Text('Total reports',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Container(
                width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$finalCount',
                        style: AppTypography.h3(Colors.white)),
                    Text('Finalized',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.85))),
                  ],
                ),
              ),
            ),
            Container(
                width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(latestPeriod,
                        style: AppTypography.h3(Colors.white)),
                    Text('Latest period',
                        style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.85))),
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

class _BoardReportCard extends StatelessWidget {
  const _BoardReportCard({required this.report});
  final BoardReport report;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isFinal = report.status == BoardReportStatus.final_;
    final statusColor = isFinal ? colors.success : colors.warning;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF9B51E0).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.slideshow_rounded,
                    color: Color(0xFF9B51E0), size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(report.period,
                    style: AppTypography.h3(colors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(report.status.label,
                    style: AppTypography.caption(statusColor)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(report.summary,
              style: AppTypography.caption(colors.textSecondary)
                  .copyWith(height: 1.5)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.visibility_outlined,
                  label: 'View',
                  onTap: () =>
                      showAppToast(context, 'Opening ${report.period}...'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () =>
                      showAppToast(context, 'Sharing ${report.period}...'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ActionButton(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'Export',
                  filled: true,
                  onTap: () => showAppToast(
                      context, 'Exporting ${report.period} as PDF...'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(12),
          border: filled ? null : Border.all(color: colors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 17, color: filled ? Colors.white : colors.textSecondary),
            const SizedBox(height: 3),
            Text(label,
                style: AppTypography.caption(
                        filled ? Colors.white : colors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard({required this.colors});
  final AppColorsData colors;

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.5 + (_controller.value * 0.3);
        return Container(
          height: 150,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: widget.colors.surfaceElevated.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: widget.colors.border),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.slideshow_outlined,
              color: colors.textSecondary, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text('No board reports yet',
              style: AppTypography.body(colors.textSecondary)),
        ],
      ),
    );
  }
}

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 480)),
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
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}
