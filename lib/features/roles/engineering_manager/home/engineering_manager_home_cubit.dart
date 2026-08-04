import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Workload level shown as a colored dot on a team member's avatar.
enum WorkloadLevel { light, moderate, heavy }

extension WorkloadLevelColor on WorkloadLevel {
  Color get dotColor {
    switch (this) {
      case WorkloadLevel.light:
        return const Color(0xFF639922);
      case WorkloadLevel.moderate:
        return const Color(0xFFEF9F27);
      case WorkloadLevel.heavy:
        return const Color(0xFFE24B4A);
    }
  }
}

class TeamMemberSnapshot {
  const TeamMemberSnapshot({
    required this.name,
    required this.initials,
    required this.workload,
    required this.avatarColor,
    required this.avatarTextColor,
  });

  final String name;
  final String initials;
  final WorkloadLevel workload;
  final Color avatarColor;
  final Color avatarTextColor;
}

class PendingPrReview {
  const PendingPrReview({
    required this.title,
    required this.author,
    required this.repo,
    required this.timeAgo,
  });

  final String title;
  final String author;
  final String repo;
  final String timeAgo;
}

/// Snapshot of everything the Home dashboard needs to render.
class EngineeringManagerHomeData {
  const EngineeringManagerHomeData({
    required this.managerName,
    required this.hasUnreadNotifications,
    required this.sprintName,
    required this.sprintDaysLeft,
    required this.pointsCompleted,
    required this.pointsTotal,
    required this.team,
    required this.overflowTeamCount,
    required this.criticalBugCount,
    required this.openBugCount,
    required this.pendingPrReviews,
  });

  final String managerName;
  final bool hasUnreadNotifications;

  final String sprintName;
  final int sprintDaysLeft;
  final int pointsCompleted;
  final int pointsTotal;

  final List<TeamMemberSnapshot> team;
  final int overflowTeamCount;

  final int criticalBugCount;
  final int openBugCount;

  final List<PendingPrReview> pendingPrReviews;

  double get sprintProgress =>
      pointsTotal == 0 ? 0 : pointsCompleted / pointsTotal;
}

/// State for Engineering Manager · Home.
sealed class EngineeringManagerHomeState {
  const EngineeringManagerHomeState();
}

class EngineeringManagerHomeInitial extends EngineeringManagerHomeState {
  const EngineeringManagerHomeInitial();
}

class EngineeringManagerHomeLoading extends EngineeringManagerHomeState {
  const EngineeringManagerHomeLoading();
}

class EngineeringManagerHomeLoaded extends EngineeringManagerHomeState {
  const EngineeringManagerHomeLoaded(this.data);

  final EngineeringManagerHomeData data;
}

class EngineeringManagerHomeError extends EngineeringManagerHomeState {
  const EngineeringManagerHomeError(this.message);

  final String message;
}

/// Cubit for Engineering Manager · Home.
///
/// `loadDashboard()` currently calls a mock repository method with an
/// artificial delay per spec section 12. Swap `_fetchMockDashboard()` for a
/// real repository call once the API is available — the state shape should
/// not need to change.
class EngineeringManagerHomeCubit extends Cubit<EngineeringManagerHomeState> {
  EngineeringManagerHomeCubit() : super(const EngineeringManagerHomeInitial());

  Future<void> loadDashboard() async {
    emit(const EngineeringManagerHomeLoading());
    try {
      final data = await _fetchMockDashboard();
      emit(EngineeringManagerHomeLoaded(data));
    } catch (e) {
      emit(EngineeringManagerHomeError(e.toString()));
    }
  }

  Future<void> refresh() => loadDashboard();

  Future<EngineeringManagerHomeData> _fetchMockDashboard() async {
    await Future.delayed(const Duration(milliseconds: 700));

    return const EngineeringManagerHomeData(
      managerName: 'Priya Nair',
      hasUnreadNotifications: true,
      sprintName: 'Sprint 14',
      sprintDaysLeft: 4,
      pointsCompleted: 27,
      pointsTotal: 40,
      team: [
        TeamMemberSnapshot(
          name: 'Arjun',
          initials: 'AK',
          workload: WorkloadLevel.light,
          avatarColor: Color(0xFFCECBF6),
          avatarTextColor: Color(0xFF26215C),
        ),
        TeamMemberSnapshot(
          name: 'Sara',
          initials: 'SM',
          workload: WorkloadLevel.moderate,
          avatarColor: Color(0xFFF0997B),
          avatarTextColor: Color(0xFF4A1B0C),
        ),
        TeamMemberSnapshot(
          name: 'Rohan',
          initials: 'RV',
          workload: WorkloadLevel.heavy,
          avatarColor: Color(0xFFED93B1),
          avatarTextColor: Color(0xFF4B1528),
        ),
        TeamMemberSnapshot(
          name: 'Neha',
          initials: 'NP',
          workload: WorkloadLevel.light,
          avatarColor: Color(0xFF9FE1CB),
          avatarTextColor: Color(0xFF04342C),
        ),
      ],
      overflowTeamCount: 3,
      criticalBugCount: 3,
      openBugCount: 17,
      pendingPrReviews: [
        PendingPrReview(
          title: 'Fix payment retry logic',
          author: 'Arjun',
          repo: 'api-service',
          timeAgo: '2h ago',
        ),
        PendingPrReview(
          title: 'Refactor onboarding flow',
          author: 'Neha',
          repo: 'mobile-app',
          timeAgo: '5h ago',
        ),
        PendingPrReview(
          title: 'Add rate limiting middleware',
          author: 'Sara',
          repo: 'api-service',
          timeAgo: '1d ago',
        ),
      ],
    );
  }
}