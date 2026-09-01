import 'package:flutter_bloc/flutter_bloc.dart';

import 'cfo_teams_state.dart';

export 'cfo_teams_state.dart';

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoTeamsCubit extends Cubit<CfoTeamsState> {
  CfoTeamsCubit() : super(const CfoTeamsInitial()) {
    load();
  }

  Future<void> load() async {
    emit(const CfoTeamsLoading());
    try {
      final data = await _fetchTeamsData();
      emit(CfoTeamsLoaded(data));
    } catch (_) {
      emit(const CfoTeamsError('Could not load teams. Pull down to retry.'));
    }
  }

  Future<void> refresh() => load();

  void setScope(DepartmentScope scope) {
    final current = state;
    if (current is! CfoTeamsLoaded) return;
    emit(current.copyWith(data: current.data.copyWith(scope: scope)));
  }

  void setLeaderboardMetric(LeaderboardMetric metric) {
    final current = state;
    if (current is! CfoTeamsLoaded) return;
    emit(current.copyWith(
      data: current.data.copyWith(leaderboardMetric: metric),
    ));
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<CfoTeamsData> _fetchTeamsData() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const CfoTeamsData(
      overviewMetrics: TeamsOverviewMetrics(
        totalTimeSavedHours: 184,
        totalTimeSavedTrendPercent: 12.5,
        tasksCompleted: 1248,
        tasksCompletedTrendPercent: 18.3,
        valueGenerated: 745000, // ₹7.45L
        valueGeneratedTrendPercent: 15.7,
        avgRoiPercent: 18.6,
        avgRoiTrendPercent: 2.4,
      ),
      departments: [
        DepartmentRoi(
          id: 'dept_engineering',
          name: 'Engineering',
          icon: DepartmentIcon.engineering,
          memberCount: 142,
          timeSavedHours: 96,
          timeSavedBarProgress: 0.68,
          roiPercent: 18,
          isDirectReport: true,
        ),
        DepartmentRoi(
          id: 'dept_marketing',
          name: 'Marketing',
          icon: DepartmentIcon.marketing,
          memberCount: 45,
          timeSavedHours: 32,
          timeSavedBarProgress: 0.45,
          roiPercent: 12,
          isDirectReport: false,
        ),
        DepartmentRoi(
          id: 'dept_sales',
          name: 'Sales',
          icon: DepartmentIcon.sales,
          memberCount: 86,
          timeSavedHours: 56,
          timeSavedBarProgress: 0.62,
          roiPercent: 24,
          isDirectReport: true,
        ),
        DepartmentRoi(
          id: 'dept_product',
          name: 'Product',
          icon: DepartmentIcon.product,
          memberCount: 38,
          timeSavedHours: 28,
          timeSavedBarProgress: 0.40,
          roiPercent: 10,
          isDirectReport: false,
        ),
      ],
      roiTools: [
        RoiTool(
          id: 'tool_copilot',
          name: 'GitHub Copilot',
          metricLabel: '2.4k hrs saved',
          icon: ToolIcon.codeAssistant,
          color: ToolColor.dark,
        ),
        RoiTool(
          id: 'tool_chatgpt',
          name: 'ChatGPT Ent.',
          metricLabel: '\$45k val. gen.',
          icon: ToolIcon.chat,
          color: ToolColor.teal,
        ),
      ],
      budgetRequests: BudgetRequestsSummary(
        pendingCount: 3,
        title: 'Budget Requests',
        subtitle: 'Pending CFO Review',
      ),
      leaderboard: [
        LeaderboardEntry(
          id: 'user_sarah',
          rank: 1,
          name: 'Sarah Johnson',
          role: 'Product Manager',
          timeSavedHours: 24,
          tasksCompleted: 61,
          trendLabel: '+12% vs last week',
        ),
        LeaderboardEntry(
          id: 'user_michael',
          rank: 2,
          name: 'Michael Chen',
          role: 'Senior Developer',
          timeSavedHours: 18,
          tasksCompleted: 52,
        ),
        LeaderboardEntry(
          id: 'user_elena',
          rank: 3,
          name: 'Elena Patel',
          role: 'Financial Analyst',
          timeSavedHours: 15.5,
          tasksCompleted: 47,
        ),
        LeaderboardEntry(
          id: 'user_david',
          rank: 4,
          name: 'David Ross',
          role: 'UX Designer',
          timeSavedHours: 12,
          tasksCompleted: 39,
        ),
        LeaderboardEntry(
          id: 'user_you',
          rank: 5,
          name: 'You',
          role: 'Finance Leader',
          timeSavedHours: 9.5,
          tasksCompleted: 31,
          nextRankHint: '2.5h to rank #4',
          isCurrentUser: true,
        ),
      ],
    );
  }
}