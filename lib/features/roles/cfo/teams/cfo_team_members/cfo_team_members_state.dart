import 'package:equatable/equatable.dart';

/// CFO · Teams · Department Detail · Team Members
/// Models + state for the full-screen member roster (pushed from the
/// "View Team Members" CTA on the department overview tab).

enum MemberFilterTab { all, topPerformers, lowUsage }

extension MemberFilterTabLabel on MemberFilterTab {
  String get label {
    switch (this) {
      case MemberFilterTab.all:
        return 'All Members';
      case MemberFilterTab.topPerformers:
        return 'Top Performers';
      case MemberFilterTab.lowUsage:
        return 'Low Usage';
    }
  }
}

enum MemberSortColumn { timeSaved, tasks, valueGenerated, roi }

class TeamMember extends Equatable {
  const TeamMember({
    required this.name,
    required this.role,
    required this.timeSavedHours,
    required this.timeSavedTrendPercent,
    required this.tasksCompleted,
    required this.tasksTrendPercent,
    required this.valueGenerated,
    required this.valueGeneratedTrendPercent,
    required this.roiPercent,
    this.avatarUrl,
  });

  final String name;
  final String role;
  final String? avatarUrl;
  final double timeSavedHours;
  final double timeSavedTrendPercent;
  final int tasksCompleted;
  final double tasksTrendPercent;
  final double valueGenerated;
  final double valueGeneratedTrendPercent;
  final double roiPercent;

  @override
  List<Object?> get props => [
        name,
        role,
        avatarUrl,
        timeSavedHours,
        timeSavedTrendPercent,
        tasksCompleted,
        tasksTrendPercent,
        valueGenerated,
        valueGeneratedTrendPercent,
        roiPercent,
      ];
}

class TeamMembersSummary extends Equatable {
  const TeamMembersSummary({
    required this.totalTimeSavedHours,
    required this.totalTimeSavedTrendPercent,
    required this.totalTasksCompleted,
    required this.totalTasksTrendPercent,
    required this.totalValueGenerated,
    required this.totalValueTrendPercent,
    required this.avgRoiPercent,
    required this.avgRoiTrendPercent,
  });

  final double totalTimeSavedHours;
  final double totalTimeSavedTrendPercent;
  final int totalTasksCompleted;
  final double totalTasksTrendPercent;
  final double totalValueGenerated;
  final double totalValueTrendPercent;
  final double avgRoiPercent;
  final double avgRoiTrendPercent;

  @override
  List<Object?> get props => [
        totalTimeSavedHours,
        totalTimeSavedTrendPercent,
        totalTasksCompleted,
        totalTasksTrendPercent,
        totalValueGenerated,
        totalValueTrendPercent,
        avgRoiPercent,
        avgRoiTrendPercent,
      ];
}

/// Fully-resolved view data: already filtered + sorted for the current
/// [filterTab] / [sortColumn] / [sortAscending] selection.
class CfoTeamMembersData extends Equatable {
  const CfoTeamMembersData({
    required this.departmentName,
    required this.totalMemberCount,
    required this.summary,
    required this.visibleMembers,
    required this.filterTab,
    required this.sortColumn,
    required this.sortAscending,
  });

  final String departmentName;
  final int totalMemberCount;
  final TeamMembersSummary summary;
  final List<TeamMember> visibleMembers;
  final MemberFilterTab filterTab;
  final MemberSortColumn sortColumn;
  final bool sortAscending;

  CfoTeamMembersData copyWith({
    List<TeamMember>? visibleMembers,
    MemberFilterTab? filterTab,
    MemberSortColumn? sortColumn,
    bool? sortAscending,
  }) {
    return CfoTeamMembersData(
      departmentName: departmentName,
      totalMemberCount: totalMemberCount,
      summary: summary,
      visibleMembers: visibleMembers ?? this.visibleMembers,
      filterTab: filterTab ?? this.filterTab,
      sortColumn: sortColumn ?? this.sortColumn,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        departmentName,
        totalMemberCount,
        summary,
        visibleMembers,
        filterTab,
        sortColumn,
        sortAscending,
      ];
}

abstract class CfoTeamMembersState extends Equatable {
  const CfoTeamMembersState();

  @override
  List<Object?> get props => [];
}

class CfoTeamMembersInitial extends CfoTeamMembersState {
  const CfoTeamMembersInitial();
}

class CfoTeamMembersLoading extends CfoTeamMembersState {
  const CfoTeamMembersLoading();
}

class CfoTeamMembersLoaded extends CfoTeamMembersState {
  const CfoTeamMembersLoaded(this.data);
  final CfoTeamMembersData data;

  @override
  List<Object?> get props => [data];
}

class CfoTeamMembersError extends CfoTeamMembersState {
  const CfoTeamMembersError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}