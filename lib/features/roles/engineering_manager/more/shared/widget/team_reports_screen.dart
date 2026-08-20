import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/staggered.dart';

enum _ReportType { spend, budget, aiAdoption }

class _Report {
  _Report({
    required this.name,
    required this.type,
    required this.dateRange,
    required this.generatedOn,
    required this.sizeLabel,
  });

  final String name;
  final _ReportType type;
  final String dateRange;
  final String generatedOn;
  final String sizeLabel;
}

/// More → Team Reports (Premium / Futuristic rebuild)
///
/// Keeps `EmGradientHero`, `ScaleOnTap`, `EmSkeletonBox`, `EmEmptyState`
/// from `em_shared_widget.dart` since those are shared across other EM
/// screens. Search field, filter chips, and report cards are rebuilt
/// local to this file with the glass / neon-accent treatment used on
/// the Notifications and Budget & Forecast screens.
///
/// TODO: `_fetchReports()` below returns mock data after an artificial
/// delay, matching the pattern already used by
/// `EngineeringManagerMoreCubit._fetchMockProfile()`. Replace with your
/// real reports-listing endpoint. "Generate Report" should call your
/// real report-generation job/endpoint instead of the local snackbar.
class TeamReportsScreen extends StatefulWidget {
  const TeamReportsScreen({super.key});

  @override
  State<TeamReportsScreen> createState() => _TeamReportsScreenState();
}

class _TeamReportsScreenState extends State<TeamReportsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  bool _loading = true;
  List<_Report> _allReports = [];
  _ReportType? _activeFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _allReports = [
        _Report(
          name: 'Engineering Spend — August',
          type: _ReportType.spend,
          dateRange: '1–14 Aug 2026',
          generatedOn: 'Today',
          sizeLabel: '1.2 MB',
        ),
        _Report(
          name: 'Budget Utilization — Q3',
          type: _ReportType.budget,
          dateRange: 'Jul–Sep 2026',
          generatedOn: '2 days ago',
          sizeLabel: '860 KB',
        ),
        _Report(
          name: 'AI Adoption — July',
          type: _ReportType.aiAdoption,
          dateRange: '1–31 Jul 2026',
          generatedOn: '1 week ago',
          sizeLabel: '640 KB',
        ),
        _Report(
          name: 'Engineering Spend — July',
          type: _ReportType.spend,
          dateRange: '1–31 Jul 2026',
          generatedOn: '2 weeks ago',
          sizeLabel: '1.1 MB',
        ),
      ];
      _loading = false;
    });
    _entrance.forward(from: 0);
  }

  List<_Report> get _filteredReports {
    return _allReports.where((r) {
      final matchesFilter = _activeFilter == null || r.type == _activeFilter;
      final matchesQuery =
          _query.isEmpty || r.name.toLowerCase().contains(_query.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  void _generateReport() {
    // TODO: call your real report-generation endpoint/job here.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating a new report…')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final reports = _filteredReports;

    return EmScreenScaffold(
      title: 'Team Reports',
      padded: false,
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            EmGradientHero(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _loading ? '—' : '${_allReports.length}',
                          style: AppTypography.h1(Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text('reports available',
                            style: AppTypography.caption(
                                Colors.white.withValues(alpha: 0.9))),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _loading
                              ? 'Loading…'
                              : 'Last generated ${_allReports.first.generatedOn}',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  ScaleOnTap(
                    onTap: _generateReport,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 11),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Generate',
                              style: AppTypography.caption(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _GlassSearchField(
              colors: colors,
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                      colors: colors,
                      label: 'All',
                      selected: _activeFilter == null,
                      onTap: () => setState(() => _activeFilter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      colors: colors,
                      label: 'Spend',
                      selected: _activeFilter == _ReportType.spend,
                      onTap: () =>
                          setState(() => _activeFilter = _ReportType.spend)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      colors: colors,
                      label: 'Budget',
                      selected: _activeFilter == _ReportType.budget,
                      onTap: () =>
                          setState(() => _activeFilter = _ReportType.budget)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      colors: colors,
                      label: 'AI Adoption',
                      selected: _activeFilter == _ReportType.aiAdoption,
                      onTap: () => setState(
                          () => _activeFilter = _ReportType.aiAdoption)),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_loading)
              Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: EmSkeletonBox(height: 76, radius: 18),
                  ),
                ),
              )
            else if (reports.isEmpty)
              EmEmptyState(
                icon: Icons.description_outlined,
                title: 'No reports found',
                message: 'Try a different filter or search term.',
              )
            else
              for (var i = 0; i < reports.length; i++) ...[
                StaggeredFade(
                  index: i,
                  total: reports.length,
                  controller: _entrance,
                  child: _ReportCard(report: reports[i]),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Glass search field
// ─────────────────────────────────────────────────────────────────────────

class _GlassSearchField extends StatelessWidget {
  const _GlassSearchField({required this.colors, required this.onChanged});
  final AppColorsData colors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.textPrimary.withOpacity(0.05),
            colors.textPrimary.withOpacity(0.02),
          ],
        ),
        border: Border.all(color: colors.textSecondary.withOpacity(0.14)),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: colors.textPrimary, fontSize: 14),
        cursorColor: colors.primary,
        decoration: InputDecoration(
          hintText: 'Search reports',
          hintStyle: TextStyle(color: colors.textSecondary, fontSize: 14),
          prefixIcon:
              Icon(Icons.search_rounded, color: colors.textSecondary, size: 20),
          filled: false,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Filter chip — glowing pill when selected
// ─────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.colors,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppColorsData colors;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [
                    colors.primary.withOpacity(0.9),
                    colors.primary.withOpacity(0.6),
                  ],
                )
              : null,
          color: selected ? null : colors.textPrimary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? colors.primary.withOpacity(0.8)
                : colors.textSecondary.withOpacity(0.14),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 0.5,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textSecondary,
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Report card — glass, gradient icon badge, glow action buttons
// ─────────────────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final _Report report;

  IconData get _icon => switch (report.type) {
        _ReportType.spend => Icons.bar_chart_rounded,
        _ReportType.budget => Icons.donut_large_rounded,
        _ReportType.aiAdoption => Icons.auto_awesome_rounded,
      };

  Color _accent(AppColorsData colors) => switch (report.type) {
        _ReportType.spend => colors.primary,
        _ReportType.budget => colors.warning,
        _ReportType.aiAdoption => colors.secondary,
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = _accent(colors);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.textPrimary.withOpacity(0.05),
            colors.textPrimary.withOpacity(0.02),
          ],
        ),
        border: Border.all(color: colors.textSecondary.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withOpacity(0.30), accent.withOpacity(0.10)],
              ),
              border: Border.all(color: accent.withOpacity(0.45)),
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Icon(_icon, size: 19, color: accent),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 3),
                Text(
                  '${report.dateRange} · ${report.generatedOn} · ${report.sizeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _GlowIconButton(
            icon: Icons.visibility_outlined,
            color: colors.textSecondary,
            onTap: () {
              // TODO: open your real report viewer.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${report.name}…')),
              );
            },
          ),
          const SizedBox(width: 6),
          _GlowIconButton(
            icon: Icons.download_rounded,
            color: accent,
            onTap: () {
              // TODO: wire to your real download/export flow.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${report.name}…')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GlowIconButton extends StatelessWidget {
  const _GlowIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
