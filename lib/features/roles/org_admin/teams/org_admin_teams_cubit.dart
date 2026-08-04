import 'package:flutter_bloc/flutter_bloc.dart';

enum OrgAdminTeamsStatus { initial, loading, loaded, error }

enum SpendTrend { up, down, flat }

class TeamSummary {
  const TeamSummary({
    required this.name,
    required this.spend,
    required this.trend,
    required this.trendPercent,
  });

  final String name;
  final double spend;
  final SpendTrend trend;
  final double trendPercent;
}

class OrgAdminTeamsState {
  const OrgAdminTeamsState({
    this.status = OrgAdminTeamsStatus.initial,
    this.teams = const [],
    this.errorMessage,
  });

  final OrgAdminTeamsStatus status;
  final List<TeamSummary> teams;
  final String? errorMessage;

  OrgAdminTeamsState copyWith({
    OrgAdminTeamsStatus? status,
    List<TeamSummary>? teams,
    String? errorMessage,
  }) {
    return OrgAdminTeamsState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Org Admin · Teams.
/// Loads team spend summaries from a mock repository call (Future with an
/// artificial delay, per spec section 12).
class OrgAdminTeamsCubit extends Cubit<OrgAdminTeamsState> {
  OrgAdminTeamsCubit() : super(const OrgAdminTeamsState());

  Future<void> loadTeams() async {
    emit(state.copyWith(status: OrgAdminTeamsStatus.loading));
    try {
      final teams = await _fetchMockTeams();
      emit(state.copyWith(status: OrgAdminTeamsStatus.loaded, teams: teams));
    } catch (e) {
      emit(state.copyWith(
        status: OrgAdminTeamsStatus.error,
        errorMessage: 'Could not load teams. Pull down to try again.',
      ));
    }
  }

  Future<List<TeamSummary>> _fetchMockTeams() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      TeamSummary(name: 'Marketing', spend: 128400, trend: SpendTrend.up, trendPercent: 12.4),
      TeamSummary(name: 'Engineering', spend: 342100, trend: SpendTrend.flat, trendPercent: 0.6),
      TeamSummary(name: 'Sales', spend: 96700, trend: SpendTrend.down, trendPercent: 5.1),
      TeamSummary(name: 'Growth', spend: 41200, trend: SpendTrend.up, trendPercent: 22.8),
      TeamSummary(name: 'Operations', spend: 63900, trend: SpendTrend.up, trendPercent: 3.2),
    ];
  }
}