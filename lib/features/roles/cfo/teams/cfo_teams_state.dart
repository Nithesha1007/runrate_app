/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

/// The four summary metrics shown at the top of the Teams Overview.
class TeamsOverviewMetrics {
  const TeamsOverviewMetrics({
    required this.totalTimeSavedHours,
    required this.totalTimeSavedTrendPercent,
    required this.tasksCompleted,
    required this.tasksCompletedTrendPercent,
    required this.valueGenerated,
    required this.valueGeneratedTrendPercent,
    required this.avgRoiPercent,
    required this.avgRoiTrendPercent,
  });

  final double totalTimeSavedHours;
  final double totalTimeSavedTrendPercent;
  final int tasksCompleted;
  final double tasksCompletedTrendPercent;

  /// Stored in INR (₹), displayed with the Cr/L compact formatter.
  final double valueGenerated;
  final double valueGeneratedTrendPercent;
  final double avgRoiPercent;
  final double avgRoiTrendPercent;
}

/// Which departments are visible in the "Department Performance" list.
enum DepartmentScope { allDepartments, directReports }

enum DepartmentIcon { engineering, marketing, sales, product }

class DepartmentRoi {
  const DepartmentRoi({
    required this.id,
    required this.name,
    required this.icon,
    required this.memberCount,
    required this.timeSavedHours,
    required this.timeSavedBarProgress,
    required this.roiPercent,
    required this.isDirectReport,
  });

  final String id;
  final String name;
  final DepartmentIcon icon;
  final int memberCount;
  final double timeSavedHours;

  /// 0.0–1.0 fill for the "Time Saved" progress bar.
  final double timeSavedBarProgress;
  final double roiPercent;

  /// Whether this department reports directly to the current CFO — used
  /// to filter the "Direct Reports" scope tab.
  final bool isDirectReport;
}

class RoiTool {
  const RoiTool({
    required this.id,
    required this.name,
    required this.metricLabel,
    required this.icon,
    required this.color,
  });

  final String id;
  final String name;
  final String metricLabel;

  /// Material icon codepoint name is resolved in the widget layer; this
  /// enum just tags which glyph to use.
  final ToolIcon icon;
  final ToolColor color;
}

enum ToolIcon { codeAssistant, chat }

enum ToolColor { dark, teal }

class BudgetRequestsSummary {
  const BudgetRequestsSummary({
    required this.pendingCount,
    required this.title,
    required this.subtitle,
  });

  final int pendingCount;
  final String title;
  final String subtitle;
}

enum LeaderboardMetric { timeSaved, tasksCompleted }

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.rank,
    required this.name,
    required this.role,
    required this.timeSavedHours,
    required this.tasksCompleted,
    this.trendLabel,
    this.nextRankHint,
    this.isCurrentUser = false,
    this.avatarUrl,
  });

  final String id;
  final int rank;
  final String name;
  final String role;
  final double timeSavedHours;
  final int tasksCompleted;

  /// e.g. "+12% vs last week" — only shown for the top entry in the mock.
  final String? trendLabel;

  /// e.g. "2.5h to rank #4" — only shown for the current user's row.
  final String? nextRankHint;
  final bool isCurrentUser;
  final String? avatarUrl;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class CfoTeamsData {
  const CfoTeamsData({
    required this.overviewMetrics,
    required this.departments,
    required this.roiTools,
    required this.budgetRequests,
    required this.leaderboard,
    this.scope = DepartmentScope.allDepartments,
    this.leaderboardMetric = LeaderboardMetric.timeSaved,
  });

  final TeamsOverviewMetrics overviewMetrics;
  final List<DepartmentRoi> departments;
  final List<RoiTool> roiTools;
  final BudgetRequestsSummary budgetRequests;
  final List<LeaderboardEntry> leaderboard;
  final DepartmentScope scope;
  final LeaderboardMetric leaderboardMetric;

  /// Departments filtered by the currently selected scope tab.
  List<DepartmentRoi> get visibleDepartments {
    if (scope == DepartmentScope.allDepartments) return departments;
    return departments.where((d) => d.isDirectReport).toList();
  }

  CfoTeamsData copyWith({
    DepartmentScope? scope,
    LeaderboardMetric? leaderboardMetric,
  }) {
    return CfoTeamsData(
      overviewMetrics: overviewMetrics,
      departments: departments,
      roiTools: roiTools,
      budgetRequests: budgetRequests,
      leaderboard: leaderboard,
      scope: scope ?? this.scope,
      leaderboardMetric: leaderboardMetric ?? this.leaderboardMetric,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoTeamsState {
  const CfoTeamsState();
}

class CfoTeamsInitial extends CfoTeamsState {
  const CfoTeamsInitial();
}

class CfoTeamsLoading extends CfoTeamsState {
  const CfoTeamsLoading();
}

class CfoTeamsLoaded extends CfoTeamsState {
  const CfoTeamsLoaded(this.data);

  final CfoTeamsData data;

  CfoTeamsLoaded copyWith({CfoTeamsData? data}) {
    return CfoTeamsLoaded(data ?? this.data);
  }
}

class CfoTeamsError extends CfoTeamsState {
  const CfoTeamsError(this.message);

  final String message;
}