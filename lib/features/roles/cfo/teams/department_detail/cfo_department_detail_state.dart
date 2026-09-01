/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

enum DepartmentDetailTab { overview, teamMembers, aiTools }

class DepartmentSummaryMetrics {
  const DepartmentSummaryMetrics({
    required this.timeSavedHours,
    required this.timeSavedTrendPercent,
    required this.tasksCompleted,
    required this.tasksCompletedTrendPercent,
    required this.valueGenerated,
    required this.valueGeneratedTrendPercent,
    required this.avgRoiPercent,
    required this.avgRoiTrendPercent,
  });

  final double timeSavedHours;
  final double timeSavedTrendPercent;
  final int tasksCompleted;
  final double tasksCompletedTrendPercent;

  /// Stored in INR (₹), displayed with the Cr/L compact formatter.
  final double valueGenerated;
  final double valueGeneratedTrendPercent;
  final double avgRoiPercent;
  final double avgRoiTrendPercent;
}

/// A dense efficiency-over-time series plus the sparse axis tick labels
/// shown underneath the chart (e.g. one label per week).
class EfficiencyTrend {
  const EfficiencyTrend({
    required this.values,
    required this.axisLabels,
    required this.periodLabel,
  });

  /// 0–100 percent samples, evenly spaced across the period.
  final List<double> values;

  /// Sparse x-axis tick labels (e.g. "May 3", "May 10", ...), evenly
  /// spaced under the chart regardless of how many [values] there are.
  final List<String> axisLabels;

  /// e.g. "Last 4 Weeks" — shown in the card's dropdown affordance.
  final String periodLabel;
}

enum AiToolGlyph { copilot, chatgpt, notion }

class AiToolUsage {
  const AiToolUsage({
    required this.id,
    required this.name,
    required this.usagePercent,
    required this.glyph,
  });

  final String id;
  final String name;

  /// 0.0–1.0 share of usage among the department's AI tools.
  final double usagePercent;
  final AiToolGlyph glyph;
}

/// A single bullet in "Key Insights". [highlight], when present, is the
/// exact substring of [text] that should be rendered in the accent color
/// (e.g. "18%").
class KeyInsight {
  const KeyInsight({required this.text, this.highlight});

  final String text;
  final String? highlight;
}

class DepartmentDetailData {
  const DepartmentDetailData({
    required this.departmentId,
    required this.departmentName,
    required this.summary,
    required this.trend,
    required this.aiTools,
    required this.insights,
    this.selectedTab = DepartmentDetailTab.overview,
  });

  final String departmentId;
  final String departmentName;
  final DepartmentSummaryMetrics summary;
  final EfficiencyTrend trend;
  final List<AiToolUsage> aiTools;
  final List<KeyInsight> insights;
  final DepartmentDetailTab selectedTab;

  DepartmentDetailData copyWith({DepartmentDetailTab? selectedTab}) {
    return DepartmentDetailData(
      departmentId: departmentId,
      departmentName: departmentName,
      summary: summary,
      trend: trend,
      aiTools: aiTools,
      insights: insights,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoDepartmentDetailState {
  const CfoDepartmentDetailState();
}

class CfoDepartmentDetailInitial extends CfoDepartmentDetailState {
  const CfoDepartmentDetailInitial();
}

class CfoDepartmentDetailLoading extends CfoDepartmentDetailState {
  const CfoDepartmentDetailLoading();
}

class CfoDepartmentDetailLoaded extends CfoDepartmentDetailState {
  const CfoDepartmentDetailLoaded(this.data);

  final DepartmentDetailData data;

  CfoDepartmentDetailLoaded copyWith({DepartmentDetailData? data}) {
    return CfoDepartmentDetailLoaded(data ?? this.data);
  }
}

class CfoDepartmentDetailError extends CfoDepartmentDetailState {
  const CfoDepartmentDetailError(this.message);

  final String message;
}