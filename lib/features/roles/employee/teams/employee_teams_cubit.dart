import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum SpendTrend { up, down, flat }

class TeamSummary {
  const TeamSummary({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.spendThisMonth,
    required this.trend,
    required this.trendPercent,
  });

  final String id;
  final String name;
  final int memberCount;
  final double spendThisMonth;
  final SpendTrend trend;
  final double trendPercent;
}

enum EmployeeTeamsStatus { initial, loading, loaded, error }

@immutable
class EmployeeTeamsState {
  const EmployeeTeamsState({
    this.status = EmployeeTeamsStatus.initial,
    this.teams = const [],
    this.errorMessage,
  });

  final EmployeeTeamsStatus status;
  final List<TeamSummary> teams;
  final String? errorMessage;

  bool get isLoading => status == EmployeeTeamsStatus.loading;
  bool get hasError => status == EmployeeTeamsStatus.error;

  EmployeeTeamsState copyWith({
    EmployeeTeamsStatus? status,
    List<TeamSummary>? teams,
    String? errorMessage,
  }) {
    return EmployeeTeamsState(
      status: status ?? this.status,
      teams: teams ?? this.teams,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Employee · Teams.
///
/// Backed by a mock repository call (artificial delay) until the real
/// teams API is wired up. Swap [_fetchTeams] for an actual repository call.
class EmployeeTeamsCubit extends Cubit<EmployeeTeamsState> {
  EmployeeTeamsCubit() : super(const EmployeeTeamsState()) {
    loadTeams();
  }

  Future<void> loadTeams() async {
    emit(state.copyWith(status: EmployeeTeamsStatus.loading));
    try {
      final teams = await _fetchTeams();
      emit(state.copyWith(status: EmployeeTeamsStatus.loaded, teams: teams));
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeTeamsStatus.error,
          errorMessage: 'Could not load teams. Pull to refresh.',
        ),
      );
    }
  }

  Future<List<TeamSummary>> _fetchTeams() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return const [
      TeamSummary(
        id: 'team1',
        name: 'Sales - West',
        memberCount: 12,
        spendThisMonth: 184500,
        trend: SpendTrend.up,
        trendPercent: 14,
      ),
      TeamSummary(
        id: 'team2',
        name: 'Engineering',
        memberCount: 28,
        spendThisMonth: 96200,
        trend: SpendTrend.down,
        trendPercent: 6,
      ),
      TeamSummary(
        id: 'team3',
        name: 'Marketing',
        memberCount: 9,
        spendThisMonth: 54300,
        trend: SpendTrend.flat,
        trendPercent: 0,
      ),
      TeamSummary(
        id: 'team4',
        name: 'Customer support',
        memberCount: 15,
        spendThisMonth: 31200,
        trend: SpendTrend.up,
        trendPercent: 3,
      ),
    ];
  }
}