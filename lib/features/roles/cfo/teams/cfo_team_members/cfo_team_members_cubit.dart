import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/teams/cfo_teams_state.dart';
import 'cfo_team_members_state.dart';

/// Drives the Team Members roster screen: loads the member list for a
/// [DepartmentRoi], and applies filter-tab + column-sort selections.
///
/// TODO: replace [_loadMembers] with a real repository call
/// (e.g. `teamsRepository.fetchMembers(department.id)`), keeping the
/// filter/sort logic below as-is.
class CfoTeamMembersCubit extends Cubit<CfoTeamMembersState> {
  CfoTeamMembersCubit(this.department) : super(const CfoTeamMembersInitial()) {
    load();
  }

  final DepartmentRoi department;

  List<TeamMember> _allMembers = const [];
  late TeamMembersSummary _summary;
  MemberFilterTab _filterTab = MemberFilterTab.all;
  MemberSortColumn _sortColumn = MemberSortColumn.timeSaved;
  bool _sortAscending = false;

  Future<void> load() async {
    emit(const CfoTeamMembersLoading());
    try {
      final result = await _loadMembers();
      _allMembers = result.members;
      _summary = result.summary;
      _emitLoaded();
    } catch (e) {
      emit(CfoTeamMembersError('Could not load team members. $e'));
    }
  }

  Future<void> refresh() => load();

  void setFilterTab(MemberFilterTab tab) {
    _filterTab = tab;
    _emitLoaded();
  }

  void setSort(MemberSortColumn column) {
    if (_sortColumn == column) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = column;
      _sortAscending = false;
    }
    _emitLoaded();
  }

  void addMember({required String name, required String role}) {
    final member = TeamMember(
      name: name.trim(),
      role: role.trim(),
      avatarUrl: null,
      timeSavedHours: 0,
      timeSavedTrendPercent: 0,
      tasksCompleted: 0,
      tasksTrendPercent: 0,
      valueGenerated: 0,
      valueGeneratedTrendPercent: 0,
      roiPercent: 0,
    );

    _allMembers = [..._allMembers, member];
    _summary = _buildSummary(_allMembers);
    _emitLoaded();
  }

  TeamMembersSummary _buildSummary(List<TeamMember> members) {
    final totalTimeSavedHours = members.fold<double>(0, (sum, member) => sum + member.timeSavedHours);
    final totalTasksCompleted = members.fold<int>(0, (sum, member) => sum + member.tasksCompleted);
    final totalValueGenerated = members.fold<double>(0, (sum, member) => sum + member.valueGenerated);
    final avgRoiPercent = members.isEmpty
        ? 0.0
        : members.fold<double>(0, (sum, member) => sum + member.roiPercent) / members.length;

    return TeamMembersSummary(
      totalTimeSavedHours: totalTimeSavedHours,
      totalTimeSavedTrendPercent: 0,
      totalTasksCompleted: totalTasksCompleted,
      totalTasksTrendPercent: 0,
      totalValueGenerated: totalValueGenerated,
      totalValueTrendPercent: 0,
      avgRoiPercent: avgRoiPercent,
      avgRoiTrendPercent: 0,
    );
  }

  void _emitLoaded() {
    emit(CfoTeamMembersLoaded(
      CfoTeamMembersData(
        departmentName: department.name,
        totalMemberCount: _allMembers.length,
        summary: _summary,
        visibleMembers: _applyFilterAndSort(_allMembers),
        filterTab: _filterTab,
        sortColumn: _sortColumn,
        sortAscending: _sortAscending,
      ),
    ));
  }

  List<TeamMember> _applyFilterAndSort(List<TeamMember> source) {
    var members = List<TeamMember>.from(source);

    switch (_filterTab) {
      case MemberFilterTab.all:
        break;
      case MemberFilterTab.topPerformers:
        members.sort((a, b) => b.roiPercent.compareTo(a.roiPercent));
        members = members.take((members.length / 2).ceil()).toList();
        break;
      case MemberFilterTab.lowUsage:
        members.sort((a, b) => a.tasksCompleted.compareTo(b.tasksCompleted));
        members = members.take((members.length / 2).ceil()).toList();
        break;
    }

    int compare(TeamMember a, TeamMember b) {
      switch (_sortColumn) {
        case MemberSortColumn.timeSaved:
          return a.timeSavedHours.compareTo(b.timeSavedHours);
        case MemberSortColumn.tasks:
          return a.tasksCompleted.compareTo(b.tasksCompleted);
        case MemberSortColumn.valueGenerated:
          return a.valueGenerated.compareTo(b.valueGenerated);
        case MemberSortColumn.roi:
          return a.roiPercent.compareTo(b.roiPercent);
      }
    }

    members.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return members;
  }

  /// Mock data matching the department's aggregate summary. Swap this out
  /// for the real API/repository call.
  Future<({List<TeamMember> members, TeamMembersSummary summary})>
      _loadMembers() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    const members = [
      TeamMember(
        name: 'Sarah Johnson',
        role: 'Product Manager',
        timeSavedHours: 24,
        timeSavedTrendPercent: 12,
        tasksCompleted: 156,
        tasksTrendPercent: 10,
        valueGenerated: 96000,
        valueGeneratedTrendPercent: 14,
        roiPercent: 24,
      ),
      TeamMember(
        name: 'Michael Chen',
        role: 'Senior Developer',
        timeSavedHours: 18,
        timeSavedTrendPercent: 8,
        tasksCompleted: 128,
        tasksTrendPercent: 7,
        valueGenerated: 72000,
        valueGeneratedTrendPercent: 9,
        roiPercent: 18,
      ),
      TeamMember(
        name: 'Elena Patel',
        role: 'Financial Analyst',
        timeSavedHours: 15.5,
        timeSavedTrendPercent: 6,
        tasksCompleted: 112,
        tasksTrendPercent: 5,
        valueGenerated: 60500,
        valueGeneratedTrendPercent: 7,
        roiPercent: 16,
      ),
      TeamMember(
        name: 'David Ross',
        role: 'UX Designer',
        timeSavedHours: 12,
        timeSavedTrendPercent: 4,
        tasksCompleted: 86,
        tasksTrendPercent: 3,
        valueGenerated: 48000,
        valueGeneratedTrendPercent: 5,
        roiPercent: 12,
      ),
      TeamMember(
        name: 'Jessica Lee',
        role: 'Software Engineer',
        timeSavedHours: 11,
        timeSavedTrendPercent: 5,
        tasksCompleted: 78,
        tasksTrendPercent: 4,
        valueGenerated: 42000,
        valueGeneratedTrendPercent: 6,
        roiPercent: 11,
      ),
      TeamMember(
        name: 'Daniel Kim',
        role: 'DevOps Engineer',
        timeSavedHours: 9,
        timeSavedTrendPercent: 3,
        tasksCompleted: 64,
        tasksTrendPercent: 3,
        valueGenerated: 36500,
        valueGeneratedTrendPercent: 4,
        roiPercent: 10,
      ),
      TeamMember(
        name: 'Priya Sharma',
        role: 'QA Engineer',
        timeSavedHours: 8,
        timeSavedTrendPercent: 2,
        tasksCompleted: 58,
        tasksTrendPercent: 2,
        valueGenerated: 28000,
        valueGeneratedTrendPercent: 3,
        roiPercent: 8,
      ),
      TeamMember(
        name: 'James Wilson',
        role: 'Backend Developer',
        timeSavedHours: 7,
        timeSavedTrendPercent: 2,
        tasksCompleted: 50,
        tasksTrendPercent: 2,
        valueGenerated: 24500,
        valueGeneratedTrendPercent: 3,
        roiPercent: 7,
      ),
    ];

    const summary = TeamMembersSummary(
      totalTimeSavedHours: 96,
      totalTimeSavedTrendPercent: 18,
      totalTasksCompleted: 642,
      totalTasksTrendPercent: 16,
      totalValueGenerated: 385000,
      totalValueTrendPercent: 20,
      avgRoiPercent: 18,
      avgRoiTrendPercent: 3,
    );

    return (members: members, summary: summary);
  }
}