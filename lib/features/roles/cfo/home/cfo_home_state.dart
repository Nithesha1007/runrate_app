import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

/// Overall status badge shown on the spend-vs-budget hero card.
enum SpendStatus { onTrack, atRisk, overBudget }

extension SpendStatusX on SpendStatus {
  String get label {
    switch (this) {
      case SpendStatus.onTrack:
        return 'Healthy';
      case SpendStatus.atRisk:
        return 'At Risk';
      case SpendStatus.overBudget:
        return 'Over Budget';
    }
  }
}

class BudgetSummary {
  const BudgetSummary({
    required this.totalSpend,
    required this.totalBudget,
    required this.status,
  });

  final double totalSpend;
  final double totalBudget;
  final SpendStatus status;

  double get percentConsumed =>
      totalBudget <= 0 ? 0 : (totalSpend / totalBudget).clamp(0, 1);

  double get remaining =>
      (totalBudget - totalSpend) < 0 ? 0 : (totalBudget - totalSpend);
}

class CostOptimizationInsight {
  const CostOptimizationInsight({
    required this.potentialSavingsPerMonth,
    required this.description,
  });

  final double potentialSavingsPerMonth;
  final String description;
}

class DepartmentSpend {
  const DepartmentSpend({
    required this.name,
    required this.actual,
    required this.budgeted,
  });

  final String name;
  final double actual;
  final double budgeted;

  double get progress => budgeted <= 0 ? 0 : (actual / budgeted);
  bool get isOverBudget => actual > budgeted;
}

enum ReportIcon { document, chart }

class RecentReport {
  const RecentReport({
    required this.id,
    required this.title,
    required this.generatedLabel,
    required this.icon,
  });

  final String id;
  final String title;
  final String generatedLabel;
  final ReportIcon icon;
}

/// A single pill of extra context shown under the spend/remaining pills
/// on the overview card (e.g. "Departments · 4").
class OverviewMetric {
  const OverviewMetric({required this.label, required this.value});

  final String label;
  final String value;
}

/// One of the four quick-action tiles under the overview card.
class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
}

/// One of the small stat cards (e.g. "18 · Team Members · ▲11%").
class OverviewStatCard {
  const OverviewStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.trendLabel,
    required this.trendUp,
  });

  final IconData icon;
  final String value;
  final String label;
  final String trendLabel;
  final bool trendUp;
}

class CfoHomeData {
  const CfoHomeData({
    required this.userName,
    required this.roleLabel,
    required this.periodTitle,
    required this.periodSubtitle,
    required this.budgetSummary,
    required this.costOptimization,
    required this.departments,
    required this.recentReports,
    required this.extraMetrics,
    required this.statCards,
  });

  final String userName;
  final String roleLabel;
  final String periodTitle;
  final String periodSubtitle;
  final BudgetSummary budgetSummary;
  final CostOptimizationInsight costOptimization;
  final List<DepartmentSpend> departments;
  final List<RecentReport> recentReports;
  final List<OverviewMetric> extraMetrics;
  final List<OverviewStatCard> statCards;

  String get userInitials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  CfoHomeData copyWith({
    List<RecentReport>? recentReports,
  }) {
    return CfoHomeData(
      userName: userName,
      roleLabel: roleLabel,
      periodTitle: periodTitle,
      periodSubtitle: periodSubtitle,
      budgetSummary: budgetSummary,
      costOptimization: costOptimization,
      departments: departments,
      recentReports: recentReports ?? this.recentReports,
      extraMetrics: extraMetrics,
      statCards: statCards,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoHomeState {
  const CfoHomeState();
}

class CfoHomeInitial extends CfoHomeState {
  const CfoHomeInitial();
}

class CfoHomeLoading extends CfoHomeState {
  const CfoHomeLoading();
}

class CfoHomeLoaded extends CfoHomeState {
  const CfoHomeLoaded(this.data, {this.isGeneratingReport = false});

  final CfoHomeData data;
  final bool isGeneratingReport;

  CfoHomeLoaded copyWith({
    CfoHomeData? data,
    bool? isGeneratingReport,
  }) {
    return CfoHomeLoaded(
      data ?? this.data,
      isGeneratingReport: isGeneratingReport ?? this.isGeneratingReport,
    );
  }
}

class CfoHomeError extends CfoHomeState {
  const CfoHomeError(this.message);

  final String message;
}