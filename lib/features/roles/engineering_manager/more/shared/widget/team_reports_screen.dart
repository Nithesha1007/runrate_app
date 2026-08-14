import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
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

/// More → Team Reports
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
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('Generate',
                              style: AppTypography.caption(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search reports',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                      label: 'All',
                      selected: _activeFilter == null,
                      onTap: () => setState(() => _activeFilter = null)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Spend',
                      selected: _activeFilter == _ReportType.spend,
                      onTap: () =>
                          setState(() => _activeFilter = _ReportType.spend)),
                  const SizedBox(width: 8),
                  _FilterChip(
                      label: 'Budget',
                      selected: _activeFilter == _ReportType.budget,
                      onTap: () =>
                          setState(() => _activeFilter = _ReportType.budget)),
                  const SizedBox(width: 8),
                  _FilterChip(
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
                    child: EmSkeletonBox(height: 72, radius: 16),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: AppTypography.caption(
                  selected ? colors.primary : colors.textSecondary)
              .copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final _Report report;

  IconData get _icon => switch (report.type) {
        _ReportType.spend => Icons.bar_chart_outlined,
        _ReportType.budget => Icons.pie_chart_outline,
        _ReportType.aiAdoption => Icons.auto_awesome_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, size: 18, color: colors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyLarge(colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  '${report.dateRange} · Generated ${report.generatedOn} · ${report.sizeLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
          ScaleOnTap(
            onTap: () {
              // TODO: open your real report viewer.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening ${report.name}…')),
              );
            },
            child: Icon(Icons.visibility_outlined,
                size: 20, color: colors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          ScaleOnTap(
            onTap: () {
              // TODO: wire to your real download/export flow.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading ${report.name}…')),
              );
            },
            child:
                Icon(Icons.download_outlined, size: 20, color: colors.primary),
          ),
        ],
      ),
    );
  }
}

