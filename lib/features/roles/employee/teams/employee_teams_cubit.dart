import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Per-member delivery status shown as a pill on their card.
enum MemberStatus { onTrack, needsAttention }

/// Which AI tool (if any) a member primarily uses — drives the small
/// icon + label chip on their card.
enum AiToolUsed { copilot, claude, none }

class TeamMemberSummary {
  const TeamMemberSummary({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    required this.aiTool,
    required this.points,
    required this.highAdoption,
  });

  final String id;
  final String name;
  final String role;
  final MemberStatus status;
  final AiToolUsed aiTool;
  final int points;

  /// Drives the "High adoption" filter tab — independent of [status],
  /// since a member can be on track *and* a high adopter, or needing
  /// attention while still adopting tools well.
  final bool highAdoption;
}

/// The employee's own team — its health metrics plus the member roster.
/// Employees only ever see this one team; there is no cross-team browsing.
class MyTeamDetail {
  const MyTeamDetail({
    required this.teamName,
    required this.tagline,
    required this.onTrackPercent,
    required this.monthlySpend,
    required this.adoptionPercent,
    required this.velocityPercent,
    required this.openPrsCount,
    required this.members,
  });

  final String teamName;
  final String tagline;
  final int onTrackPercent;
  final double monthlySpend;
  final int adoptionPercent;
  final int velocityPercent;
  final int openPrsCount;
  final List<TeamMemberSummary> members;

  int get memberCount => members.length;
  int get highAdoptionCount => members.where((m) => m.highAdoption).length;
  int get needsAttentionCount =>
      members.where((m) => m.status == MemberStatus.needsAttention).length;
}

enum EmployeeTeamsStatus { initial, loading, loaded, error }

@immutable
class EmployeeTeamsState {
  const EmployeeTeamsState({
    this.status = EmployeeTeamsStatus.initial,
    this.team,
    this.errorMessage,
  });

  final EmployeeTeamsStatus status;
  final MyTeamDetail? team;
  final String? errorMessage;

  bool get isLoading => status == EmployeeTeamsStatus.loading;
  bool get hasError => status == EmployeeTeamsStatus.error;
  bool get hasTeam => team != null;

  EmployeeTeamsState copyWith({
    EmployeeTeamsStatus? status,
    MyTeamDetail? team,
    String? errorMessage,
  }) {
    return EmployeeTeamsState(
      status: status ?? this.status,
      team: team ?? this.team,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Employee · Teams ("My Team").
///
/// Employees can only see their own team — its health metrics and its
/// member roster. There is no way to browse into other teams from here;
/// that's a manager/CFO-level capability, not an employee one.
///
/// Backed by a mock repository call (artificial delay) until the real
/// teams API is wired up. Swap [_fetchMyTeam] for an actual repository call.
class EmployeeTeamsCubit extends Cubit<EmployeeTeamsState> {
  EmployeeTeamsCubit() : super(const EmployeeTeamsState()) {
    loadMyTeam();
  }

  Future<void> loadMyTeam() async {
    emit(state.copyWith(status: EmployeeTeamsStatus.loading));
    try {
      final team = await _fetchMyTeam();
      emit(state.copyWith(status: EmployeeTeamsStatus.loaded, team: team));
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeTeamsStatus.error,
          errorMessage: 'Could not load your team. Pull to refresh.',
        ),
      );
    }
  }

  Future<MyTeamDetail> _fetchMyTeam() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return const MyTeamDetail(
      teamName: 'Engineering',
      tagline: 'Engineering · sprint & AI activity',
      onTrackPercent: 50,
      monthlySpend: 1570,
      adoptionPercent: 63,
      velocityPercent: 81,
      openPrsCount: 15,
      members: [
        TeamMemberSummary(
          id: 'm1',
          name: 'Arun Kumar',
          role: 'Senior Software Engineer',
          status: MemberStatus.onTrack,
          aiTool: AiToolUsed.copilot,
          points: 11,
          highAdoption: true,
        ),
        TeamMemberSummary(
          id: 'm2',
          name: 'Priya Nair',
          role: 'Flutter Developer',
          status: MemberStatus.onTrack,
          aiTool: AiToolUsed.claude,
          points: 9,
          highAdoption: true,
        ),
        TeamMemberSummary(
          id: 'm3',
          name: 'Karthik Subramaniam',
          role: 'Backend Engineer',
          status: MemberStatus.needsAttention,
          aiTool: AiToolUsed.copilot,
          points: 8,
          highAdoption: false,
        ),
        TeamMemberSummary(
          id: 'm4',
          name: 'Divya Raghavan',
          role: 'QA Engineer',
          status: MemberStatus.onTrack,
          aiTool: AiToolUsed.claude,
          points: 7,
          highAdoption: true,
        ),
        TeamMemberSummary(
          id: 'm5',
          name: 'Rahul Verma',
          role: 'DevOps Engineer',
          status: MemberStatus.needsAttention,
          aiTool: AiToolUsed.claude,
          points: 15,
          highAdoption: false,
        ),
        TeamMemberSummary(
          id: 'm6',
          name: 'Vikram Chauhan',
          role: 'Mobile Developer',
          status: MemberStatus.needsAttention,
          aiTool: AiToolUsed.none,
          points: 5,
          highAdoption: false,
        ),
        TeamMemberSummary(
          id: 'm7',
          name: 'Meera Pillai',
          role: 'Backend Engineer',
          status: MemberStatus.needsAttention,
          aiTool: AiToolUsed.copilot,
          points: 6,
          highAdoption: false,
        ),
        TeamMemberSummary(
          id: 'm8',
          name: 'Sanjay Iyer',
          role: 'Frontend Developer',
          status: MemberStatus.onTrack,
          aiTool: AiToolUsed.claude,
          points: 10,
          highAdoption: false,
        ),
      ],
    );
  }
}