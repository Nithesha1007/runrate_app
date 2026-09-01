import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_team_members/cfo_team_members_screen.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_teams_state.dart';
import 'cfo_department_detail_cubit.dart';

// ---------------------------------------------------------------------------
// Palette — shared gradient language used across the CFO surface
// (Approvals, Teams, Team Members, Department Detail).
// ---------------------------------------------------------------------------
const _kGradientStart = Color(0xFF6C5CE7);
const _kGradientEnd = Color(0xFF4C6FEF);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 20.0;

/// CFO · Teams · Department Detail
/// Drill-down for a single department: gradient summary hero, an
/// efficiency trend chart, top AI tools by usage, and key insights —
/// wired to [CfoDepartmentDetailCubit]. Pushed from a department card on
/// the Teams Overview screen.
class CfoDepartmentDetailScreen extends StatelessWidget {
  const CfoDepartmentDetailScreen({super.key, required this.department});

  final DepartmentRoi department;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoDepartmentDetailCubit(department),
      child: const _CfoDepartmentDetailView(),
    );
  }
}

class _CfoDepartmentDetailView extends StatelessWidget {
  const _CfoDepartmentDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: BlocBuilder<CfoDepartmentDetailCubit, CfoDepartmentDetailState>(
          builder: (context, state) {
            if (state is CfoDepartmentDetailLoading ||
                state is CfoDepartmentDetailInitial) {
              return Column(
                children: [
                  _Header(title: '', onBack: () => Navigator.of(context).pop()),
                  const Expanded(child: Center(child: CircularProgressIndicator())),
                ],
              );
            }

            if (state is CfoDepartmentDetailError) {
              return Column(
                children: [
                  _Header(title: '', onBack: () => Navigator.of(context).pop()),
                  Expanded(
                    child: _ErrorView(
                      message: state.message,
                      onRetry: () => context.read<CfoDepartmentDetailCubit>().load(),
                    ),
                  ),
                ],
              );
            }

            final data = (state as CfoDepartmentDetailLoaded).data;

            return RefreshIndicator(
              onRefresh: () => context.read<CfoDepartmentDetailCubit>().refresh(),
              child: Column(
                children: [
                  _Header(
                    title: '${data.departmentName} Department',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                    child: _DetailTabs(
                      selected: data.selectedTab,
                      onChanged: (tab) =>
                          context.read<CfoDepartmentDetailCubit>().setTab(tab),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: data.selectedTab == DepartmentDetailTab.overview
                          ? _OverviewTab(data: data)
                          : data.selectedTab == DepartmentDetailTab.aiTools
                              ? _AiToolsTab(tools: data.aiTools)
                              : _PlaceholderTab(tab: data.selectedTab),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Header — back button, title, overflow menu
/// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Colors.black),
            ),
          ),
          InkWell(
            onTap: () {
              // TODO: show department overflow menu (export, share, etc).
            },
            customBorder: const CircleBorder(),
            child: Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Icon(Icons.more_horiz_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Overview / Team Members / AI Tools tab selector
/// ---------------------------------------------------------------------

class _DetailTabs extends StatelessWidget {
  const _DetailTabs({required this.selected, required this.onChanged});

  final DepartmentDetailTab selected;
  final ValueChanged<DepartmentDetailTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DetailTabChip(
          label: 'Overview',
          isSelected: selected == DepartmentDetailTab.overview,
          onTap: () => onChanged(DepartmentDetailTab.overview),
        ),
        const SizedBox(width: AppSpacing.sm),
        _DetailTabChip(
          label: 'Team Members',
          isSelected: selected == DepartmentDetailTab.teamMembers,
          onTap: () {
            final department = context.read<CfoDepartmentDetailCubit>().department;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CfoTeamMembersScreen(department: department),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _DetailTabChip(
          label: 'AI Tools',
          isSelected: selected == DepartmentDetailTab.aiTools,
          onTap: () => onChanged(DepartmentDetailTab.aiTools),
        ),
      ],
    );
  }
}

class _DetailTabChip extends StatelessWidget {
  const _DetailTabChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(colors: [_kGradientStart, _kGradientEnd]) : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Overview tab
/// ---------------------------------------------------------------------

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data});

  final DepartmentDetailData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _SummaryHero(summary: data.summary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _EfficiencyTrendCard(trend: data.trend),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _AiToolsUsageCard(tools: data.aiTools),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: _KeyInsightsCard(insights: data.insights),
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(color: _kGradientEnd.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CfoTeamMembersScreen(
                      department: context.read<CfoDepartmentDetailCubit>().department,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: const StadiumBorder(),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_rounded, size: 18),
                    SizedBox(width: 12),
                    Text('View Team Members', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Department summary hero — gradient card with ROI ring + 2x2 stat grid
/// ---------------------------------------------------------------------

class _SummaryHero extends StatelessWidget {
  const _SummaryHero({required this.summary});

  final DepartmentSummaryMetrics summary;

  static String _trimZero(double value) {
    return value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final ringPercent = summary.avgRoiPercent.clamp(0, 100) / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kGradientStart, _kGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: _kGradientEnd.withOpacity(0.3), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Department Summary',
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const _DropdownAffordance(label: 'This Week', light: true),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: ringPercent.toDouble(),
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.22),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Text(
                      '+${summary.avgRoiPercent.toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Avg. ROI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.arrow_upward_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 2),
                        Text(
                          '${summary.avgRoiTrendPercent.toStringAsFixed(0)}% vs last week',
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  icon: Icons.schedule_rounded,
                  value: '${_trimZero(summary.timeSavedHours)}h',
                  label: 'Time Saved',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.check_circle_outline_rounded,
                  value: '${summary.tasksCompleted}',
                  label: 'Tasks Done',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  icon: Icons.currency_rupee_rounded,
                  value: formatInrCompact(summary.valueGenerated),
                  label: 'Value Gen.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.white.withOpacity(0.9)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Efficiency trend card — custom-painted line chart (no chart package)
/// ---------------------------------------------------------------------

class _EfficiencyTrendCard extends StatelessWidget {
  const _EfficiencyTrendCard({required this.trend});

  final EfficiencyTrend trend;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Efficiency Trend', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              _DropdownAffordance(label: trend.periodLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(height: 190, child: _EfficiencyTrendChart(trend: trend)),
        ],
      ),
    );
  }
}

class _EfficiencyTrendChart extends StatelessWidget {
  const _EfficiencyTrendChart({required this.trend});

  final EfficiencyTrend trend;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _TrendLinePainter(
            values: trend.values,
            axisLabels: trend.axisLabels,
            lineColor: _kGradientStart,
            fillColor: _kGradientStart.withOpacity(0.10),
            gridColor: Colors.grey.shade200,
            axisTextColor: Colors.grey.shade500,
            labelBg: _kGradientStart,
            labelText: Colors.white,
          ),
        );
      },
    );
  }
}

class _TrendLinePainter extends CustomPainter {
  _TrendLinePainter({
    required this.values,
    required this.axisLabels,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.axisTextColor,
    required this.labelBg,
    required this.labelText,
  });

  final List<double> values;
  final List<String> axisLabels;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color axisTextColor;
  final Color labelBg;
  final Color labelText;

  static const double _leftAxisWidth = 34;
  static const double _bottomAxisHeight = 22;
  static const double _topPadding = 24;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final chartWidth = size.width - _leftAxisWidth;
    final chartHeight = size.height - _bottomAxisHeight - _topPadding;
    final chartTop = _topPadding;
    final chartLeft = _leftAxisWidth;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chartTop + chartHeight - (chartHeight * i / 4);
      canvas.drawLine(Offset(chartLeft, y), Offset(size.width, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(text: '${i * 25}%', style: TextStyle(color: axisTextColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    for (var i = 0; i < axisLabels.length; i++) {
      final x = chartLeft +
          (axisLabels.length == 1 ? chartWidth / 2 : chartWidth * i / (axisLabels.length - 1));
      final tp = TextPainter(
        text: TextSpan(text: axisLabels[i], style: TextStyle(color: axisTextColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = i == 0 ? x : (i == axisLabels.length - 1 ? x - tp.width : x - tp.width / 2);
      tp.paint(canvas, Offset(dx, size.height - _bottomAxisHeight + 6));
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = chartLeft + (values.length == 1 ? chartWidth / 2 : chartWidth * i / (values.length - 1));
      final normalized = (values[i].clamp(0, 100)) / 100;
      final y = chartTop + chartHeight - (chartHeight * normalized);
      points.add(Offset(x, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      linePath.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(points.last.dx, chartTop + chartHeight)
      ..lineTo(points.first.dx, chartTop + chartHeight)
      ..close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final last = points.last;
    canvas.drawCircle(last, 5, Paint()..color = lineColor);
    canvas.drawCircle(
      last,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final labelValue = '${values.last.round()}%';
    final labelTp = TextPainter(
      text: TextSpan(text: labelValue, style: TextStyle(color: labelText, fontSize: 11, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();

    final bubbleWidth = labelTp.width + 14;
    const bubbleHeight = 20.0;
    var bubbleLeft = last.dx - bubbleWidth / 2;
    bubbleLeft = bubbleLeft.clamp(chartLeft, size.width - bubbleWidth);
    final bubbleRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(bubbleLeft, last.dy - bubbleHeight - 10, bubbleWidth, bubbleHeight),
      const Radius.circular(10),
    );
    canvas.drawRRect(bubbleRect, Paint()..color = labelBg);
    labelTp.paint(canvas, Offset(bubbleRect.left + 7, bubbleRect.top + 4));
  }

  @override
  bool shouldRepaint(covariant _TrendLinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.axisLabels != axisLabels;
  }
}

/// ---------------------------------------------------------------------
/// Top AI tools by usage card
/// ---------------------------------------------------------------------

class _AiToolsUsageCard extends StatelessWidget {
  const _AiToolsUsageCard({required this.tools});

  final List<AiToolUsage> tools;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top AI Tools by Usage', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const _DropdownAffordance(label: 'This Week'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < tools.length; i++) ...[
            _AiToolUsageRow(tool: tools[i]),
            if (i != tools.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AiToolUsageRow extends StatelessWidget {
  const _AiToolUsageRow({required this.tool});

  final AiToolUsage tool;

  ({IconData icon, Color bg}) get _style {
    switch (tool.glyph) {
      case AiToolGlyph.copilot:
        return (icon: Icons.integration_instructions_rounded, bg: const Color(0xFF15161A));
      case AiToolGlyph.chatgpt:
        return (icon: Icons.chat_bubble_outline_rounded, bg: const Color(0xFF0F9B8E));
      case AiToolGlyph.notion:
        return (icon: Icons.edit_note_rounded, bg: const Color(0xFF15161A));
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: style.bg, borderRadius: BorderRadius.circular(9)),
          child: Icon(style.icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          flex: 2,
          child: Text(
            tool.name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: tool.usagePercent.clamp(0, 1),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation(_kGradientStart),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 34,
          child: Text(
            '${(tool.usagePercent * 100).round()}%',
            textAlign: TextAlign.right,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Key insights card
/// ---------------------------------------------------------------------

class _KeyInsightsCard extends StatelessWidget {
  const _KeyInsightsCard({required this.insights});

  final List<KeyInsight> insights;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(color: _kGradientStart.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.lightbulb_outline_rounded, size: 14, color: _kGradientStart),
              ),
              const SizedBox(width: 8),
              const Text('Key Insights', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final insight in insights)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: _InsightText(insight: insight)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InsightText extends StatelessWidget {
  const _InsightText({required this.insight});

  final KeyInsight insight;

  @override
  Widget build(BuildContext context) {
    const baseStyle = TextStyle(fontSize: 13.5, height: 1.4, color: Colors.black87);
    final highlight = insight.highlight;

    if (highlight == null || !insight.text.contains(highlight)) {
      return Text(insight.text, style: baseStyle);
    }

    final index = insight.text.indexOf(highlight);
    final before = insight.text.substring(0, index);
    final after = insight.text.substring(index + highlight.length);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(
            text: highlight,
            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w700),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Placeholder for non-overview tabs
/// ---------------------------------------------------------------------

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.tab});

  final DepartmentDetailTab tab;

  @override
  Widget build(BuildContext context) {
    final label = tab == DepartmentDetailTab.teamMembers ? 'Team Members' : 'AI Tools';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Center(
        child: Text('$label view coming soon.', style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}

class _AiToolsTab extends StatelessWidget {
  const _AiToolsTab({required this.tools});

  final List<AiToolUsage> tools;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'AI Tools Used by This Department',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.lg),
          _AiToolsUsageCard(tools: tools),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Shared card shell + small affordances
/// ---------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }
}

class _DropdownAffordance extends StatelessWidget {
  const _DropdownAffordance({required this.label, this.light = false});

  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : _kGradientStart;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Error state
/// ---------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Color(0xFFE5484D)),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: AppSpacing.md),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_kGradientStart, _kGradientEnd]),
                borderRadius: BorderRadius.circular(100),
              ),
              child: FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — Indian currency (Cr / L)
/// ---------------------------------------------------------------------

String formatInrCompact(double value) {
  if (value >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  }
  if (value >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(2)}L';
  }
  return '₹${value.toStringAsFixed(0)}';
}