import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cfo_home_state.dart';

export 'cfo_home_state.dart';

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoHomeCubit extends Cubit<CfoHomeState> {
  CfoHomeCubit() : super(const CfoHomeInitial()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    emit(const CfoHomeLoading());
    try {
      final data = await _fetchDashboard();
      emit(CfoHomeLoaded(data));
    } catch (_) {
      emit(const CfoHomeError(
          'Could not load the CFO dashboard. Pull down to retry.'));
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<void> generateReport() async {
    final current = state;
    if (current is! CfoHomeLoaded) return;

    emit(current.copyWith(isGeneratingReport: true));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final newReport = RecentReport(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Custom Report',
        generatedLabel: 'Generated just now',
        icon: ReportIcon.document,
      );
      emit(current.copyWith(
        data: current.data.copyWith(
          recentReports: [newReport, ...current.data.recentReports],
        ),
        isGeneratingReport: false,
      ));
    } catch (_) {
      emit(current.copyWith(isGeneratingReport: false));
    }
  }

  Future<CfoHomeData> _fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));

    const departments = [
      DepartmentSpend(name: 'Engineering', actual: 1200000, budgeted: 1500000),
      DepartmentSpend(name: 'Marketing', actual: 600000, budgeted: 650000),
      DepartmentSpend(name: 'Sales', actual: 400000, budgeted: 600000),
      DepartmentSpend(name: 'HR & Admin', actual: 200000, budgeted: 150000),
    ];

    const recentReports = [
      RecentReport(
        id: 'report_1',
        title: 'Q2 Actuals vs Reforecast',
        generatedLabel: 'Generated 2h ago',
        icon: ReportIcon.document,
      ),
      RecentReport(
        id: 'report_2',
        title: 'Vendor Spends > \$50k',
        generatedLabel: 'Generated Yesterday',
        icon: ReportIcon.document,
      ),
      RecentReport(
        id: 'report_3',
        title: 'Headcount Plan Variance',
        generatedLabel: 'Generated Aug 12',
        icon: ReportIcon.chart,
      ),
    ];

    final overBudgetCount = departments.where((d) => d.isOverBudget).length;

    return CfoHomeData(
      userName: 'Priya Nair',
      roleLabel: 'Finance Runtime',
      periodTitle: 'Q3 Budget Overview',
      periodSubtitle: 'Enterprise Wide Performance',
      budgetSummary: const BudgetSummary(
        totalSpend: 2400000,
        totalBudget: 3100000,
        status: SpendStatus.onTrack,
      ),
      costOptimization: const CostOptimizationInsight(
        potentialSavingsPerMonth: 1200,
        description:
            'By consolidating redundant software licenses in Engineering.',
      ),
      departments: departments,
      recentReports: recentReports,
      extraMetrics: [
        OverviewMetric(label: 'Departments', value: '${departments.length}'),
        OverviewMetric(label: 'Reports', value: '${recentReports.length}'),
        OverviewMetric(
            label: 'Avg Utilization',
            value:
                '${((departments.fold<double>(0, (s, d) => s + d.progress) / departments.length) * 100).round()}%'),
      ],
      statCards: [
        OverviewStatCard(
          icon: Icons.groups_outlined,
          value: '${departments.length}',
          label: 'Departments Tracked',
          trendLabel: '+0',
          trendUp: true,
        ),
        OverviewStatCard(
          icon: Icons.description_outlined,
          value: '${recentReports.length}',
          label: 'Reports This Month',
          trendLabel: '+2',
          trendUp: true,
        ),
        OverviewStatCard(
          icon: Icons.warning_amber_rounded,
          value: '$overBudgetCount',
          label: 'Over Budget',
          trendLabel: overBudgetCount > 0 ? '+1' : '0',
          trendUp: overBudgetCount == 0,
        ),
        OverviewStatCard(
          icon: Icons.savings_outlined,
          value: '\$1.2k',
          label: 'Savings Found',
          trendLabel: '+8%',
          trendUp: true,
        ),
      ],
    );
  }
}