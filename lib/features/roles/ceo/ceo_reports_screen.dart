import 'package:flutter/material.dart';
import 'package:runrate/features/roles/ceo/data/ceo_mock_repository.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/report_model.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/simple_bar_chart.dart';
import '../../../../shared/widgets/toast.dart';

/// CEO · Report Center — list of board/finance reports. Tapping a report
/// opens a detail viewer with a chart and a mock "Preparing PDF..." export.
class CeoReportsScreen extends StatefulWidget {
  const CeoReportsScreen({super.key});

  @override
  State<CeoReportsScreen> createState() => _CeoReportsScreenState();
}

class _CeoReportsScreenState extends State<CeoReportsScreen> {
  final _repo = CeoMockRepository();
  late Future<List<ReportModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Center')),
      body: FutureBuilder<List<ReportModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, __) => const SkeletonLoader(height: 88),
            );
          }
          final reports = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final r = reports[i];
              return AppCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CeoReportDetailScreen(report: r))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text(r.period, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class CeoReportDetailScreen extends StatefulWidget {
  final ReportModel report;
  const CeoReportDetailScreen({super.key, required this.report});

  @override
  State<CeoReportDetailScreen> createState() => _CeoReportDetailScreenState();
}

class _CeoReportDetailScreenState extends State<CeoReportDetailScreen> {
  bool _exporting = false;

  Future<void> _export() async {
    setState(() => _exporting = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _exporting = false);
    showAppToast(context, 'PDF ready — "\${widget.report.title}.pdf"');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.report;
    final points = [for (var i = 0; i < r.chartValues.length; i++) BarChartPoint(label: r.chartLabels[i], value: r.chartValues[i])];
    return Scaffold(
      appBar: AppBar(title: Text(r.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(r.period, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            AppCard(child: SimpleBarChart(points: points)),
            const SizedBox(height: AppSpacing.lg),
            Text(r.summary, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.download),
              label: Text(_exporting ? 'Preparing PDF...' : 'Export PDF'),
            ),
          ],
        ),
      ),
    );
  }
}