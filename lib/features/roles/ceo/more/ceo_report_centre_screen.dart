import 'package:flutter/material.dart';
import 'package:runrate/core/theme/app_colors_data.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/toast.dart';

enum ReportType { financial, adoption, department, compliance }

extension ReportTypeX on ReportType {
  String get label => switch (this) {
        ReportType.financial => 'Financial',
        ReportType.adoption => 'Adoption',
        ReportType.department => 'Department',
        ReportType.compliance => 'Compliance',
      };

  IconData get icon => switch (this) {
        ReportType.financial => Icons.pie_chart_rounded,
        ReportType.adoption => Icons.trending_up_rounded,
        ReportType.department => Icons.apartment_rounded,
        ReportType.compliance => Icons.gavel_rounded,
      };
}

class ReportItem {
  const ReportItem({
    required this.name,
    required this.type,
    required this.generatedOn,
    required this.fileSizeMb,
  });

  final String name;
  final ReportType type;
  final DateTime generatedOn;
  final double fileSizeMb;
}

final _mockReports = <ReportItem>[
  ReportItem(
    name: 'Q3 Financial Summary',
    type: ReportType.financial,
    generatedOn: DateTime(2026, 8, 2),
    fileSizeMb: 2.4,
  ),
  ReportItem(
    name: 'Monthly Spend Breakdown',
    type: ReportType.financial,
    generatedOn: DateTime(2026, 8, 6),
    fileSizeMb: 1.1,
  ),
  ReportItem(
    name: 'Copilot Adoption Trends',
    type: ReportType.adoption,
    generatedOn: DateTime(2026, 8, 1),
    fileSizeMb: 0.8,
  ),
  ReportItem(
    name: 'Engineering Dept Overview',
    type: ReportType.department,
    generatedOn: DateTime(2026, 7, 28),
    fileSizeMb: 1.6,
  ),
  ReportItem(
    name: 'Sales Dept Overview',
    type: ReportType.department,
    generatedOn: DateTime(2026, 7, 28),
    fileSizeMb: 1.4,
  ),
  ReportItem(
    name: 'SOC 2 Compliance Audit',
    type: ReportType.compliance,
    generatedOn: DateTime(2026, 7, 15),
    fileSizeMb: 3.2,
  ),
];

/// Report Center — search + type filter over generated reports, each with
/// a View / Download action.
class CeoReportCenterScreen extends StatefulWidget {
  const CeoReportCenterScreen({super.key});

  @override
  State<CeoReportCenterScreen> createState() => _CeoReportCenterScreenState();
}

class _CeoReportCenterScreenState extends State<CeoReportCenterScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  ReportType? _activeFilter;
  bool _loading = true;
  List<ReportItem>? _reports;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _reports = _mockReports;
      _loading = false;
    });
  }

  List<ReportItem> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return (_reports ?? [])
        .where((r) => _activeFilter == null || r.type == _activeFilter)
        .where((r) => query.isEmpty || r.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final filtered = _filtered;
    final total = _reports?.length ?? 0;
    final lastGenerated = (_reports == null || _reports!.isEmpty)
        ? null
        : _reports!
            .map((r) => r.generatedOn)
            .reduce((a, b) => a.isAfter(b) ? a : b);

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
                        Text('Report Center',
                            style: AppTypography.h2(colors.textPrimary)),
                        Text('Generated reports across your org',
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
                    total: total,
                    lastGenerated: lastGenerated,
                  )),
              const SizedBox(height: AppSpacing.xl),
              _Staggered(index: 1, child: _buildSearch(colors)),
              const SizedBox(height: AppSpacing.md),
              _Staggered(index: 1, child: _buildFilterRow(colors)),
              const SizedBox(height: AppSpacing.xl),
              if (_loading)
                for (var i = 0; i < 4; i++) ...[
                  _SkeletonCard(colors: colors),
                  const SizedBox(height: AppSpacing.md),
                ]
              else if (filtered.isEmpty)
                _EmptyState(colors: colors)
              else
                for (var i = 0; i < filtered.length; i++) ...[
                  _Staggered(
                    index: i + 2,
                    child: _ReportCard(item: filtered[i]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(AppColorsData colors) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _searchFocus.hasFocus ? colors.primary : colors.border,
          width: _searchFocus.hasFocus ? 1.6 : 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        style: AppTypography.body(colors.textPrimary),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          hintText: 'Search reports...',
          hintStyle: AppTypography.body(colors.textSecondary),
          prefixIcon: Icon(Icons.search_rounded, color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _buildFilterRow(AppColorsData colors) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _FilterChip(
            label: 'All',
            selected: _activeFilter == null,
            onTap: () => setState(() => _activeFilter = null),
          ),
          for (final type in ReportType.values) ...[
            const SizedBox(width: AppSpacing.sm),
            _FilterChip(
              label: type.label,
              selected: _activeFilter == type,
              onTap: () => setState(() => _activeFilter = type),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary(
      {required this.colors, required this.total, required this.lastGenerated});
  final AppColorsData colors;
  final int total;
  final DateTime? lastGenerated;

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
                  Text('$total',
                      style: AppTypography.h1(Colors.white)),
                  Text('Reports available',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.85))),
                ],
              ),
            ),
            Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.3)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastGenerated == null
                          ? '—'
                          : '${lastGenerated!.day}/${lastGenerated!.month}/${lastGenerated!.year}',
                      style: AppTypography.h3(Colors.white),
                    ),
                    Text('Last generated',
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

class _FilterChip extends StatelessWidget {
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? colors.primary : colors.border),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: AppTypography.caption(
                    selected ? Colors.white : colors.textSecondary)
                .copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.item});
  final ReportItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.type.icon, color: colors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${item.generatedOn.day}/${item.generatedOn.month}/${item.generatedOn.year} · '
                  '${item.fileSizeMb.toStringAsFixed(1)} MB',
                  style: AppTypography.caption(colors.textSecondary),
                ),
              ],
            ),
          ),
          _ScaleOnTap(
            onTap: () => showAppToast(context, 'Opening ${item.name}...'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.visibility_outlined,
                  size: 18, color: colors.textSecondary),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ScaleOnTap(
            onTap: () => showAppToast(context, 'Downloading ${item.name}...'),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 6),
              decoration: BoxDecoration(
                color: colors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.download_rounded,
                  size: 18, color: Colors.white),
            ),
          ),
        ],
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
          height: 74,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: widget.colors.surfaceElevated.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(18),
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
          Icon(Icons.folder_off_outlined,
              color: colors.textSecondary, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text('No reports match your filters',
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
