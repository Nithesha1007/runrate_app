import 'package:flutter_bloc/flutter_bloc.dart';

class TeamSummary {
  const TeamSummary({
    required this.name,
    required this.memberCount,
    required this.monthlySpend,
    required this.trendPercent,
    required this.trendIsUp,
  });

  final String name;
  final int memberCount;
  final double monthlySpend;
  final double trendPercent;
  final bool trendIsUp;
}

class EngineeringManagerTeamsData {
  const EngineeringManagerTeamsData({required this.teams});

  final List<TeamSummary> teams;
}

sealed class EngineeringManagerTeamsState {
  const EngineeringManagerTeamsState();
}

class EngineeringManagerTeamsInitial extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsInitial();
}

class EngineeringManagerTeamsLoading extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsLoading();
}

class EngineeringManagerTeamsLoaded extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsLoaded(this.data);

  final EngineeringManagerTeamsData data;
}

class EngineeringManagerTeamsError extends EngineeringManagerTeamsState {
  const EngineeringManagerTeamsError(this.message);

  final String message;
}

/// Cubit for Engineering Manager · Teams.
///
/// `loadTeams()` calls a mock repository method with an artificial delay
/// per spec section 12. Swap `_fetchMockTeams()` for a real repository call
/// once the API is available.
class EngineeringManagerTeamsCubit extends Cubit<EngineeringManagerTeamsState> {
  EngineeringManagerTeamsCubit() : super(const EngineeringManagerTeamsInitial());

  Future<void> loadTeams() async {
    emit(const EngineeringManagerTeamsLoading());
    try {
      final teams = await _fetchMockTeams();
      emit(EngineeringManagerTeamsLoaded(EngineeringManagerTeamsData(teams: teams)));
    } catch (e) {
      emit(EngineeringManagerTeamsError(e.toString()));
    }
  }

  Future<void> refresh() => loadTeams();

  Future<List<TeamSummary>> _fetchMockTeams() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      TeamSummary(
        name: 'Platform',
        memberCount: 8,
        monthlySpend: 42800,
        trendPercent: 6.4,
        trendIsUp: true,
      ),
      TeamSummary(
        name: 'Mobile',
        memberCount: 6,
        monthlySpend: 31200,
        trendPercent: 2.1,
        trendIsUp: false,
      ),
      TeamSummary(
        name: 'API services',
        memberCount: 10,
        monthlySpend: 55600,
        trendPercent: 11.8,
        trendIsUp: true,
      ),
      TeamSummary(
        name: 'Data infrastructure',
        memberCount: 5,
        monthlySpend: 27400,
        trendPercent: 3.5,
        trendIsUp: false,
      ),
      TeamSummary(
        name: 'QA & release',
        memberCount: 4,
        monthlySpend: 18900,
        trendPercent: 0.8,
        trendIsUp: true,
      ),
    ];
  }
}