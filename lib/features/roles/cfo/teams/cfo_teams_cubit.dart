import 'package:flutter_bloc/flutter_bloc.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

class TeamSpend {
  const TeamSpend({
    required this.id,
    required this.name,
    required this.spend,
    required this.trendPercent, // positive = up, negative = down
    required this.memberCount,
  });

  final String id;
  final String name;
  final double spend;
  final double trendPercent;
  final int memberCount;
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
  const CfoTeamsLoaded(this.teams);

  final List<TeamSpend> teams;
}

class CfoTeamsError extends CfoTeamsState {
  const CfoTeamsError(this.message);

  final String message;
}

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
      final teams = await _fetchTeams();
      emit(CfoTeamsLoaded(teams));
    } catch (_) {
      emit(const CfoTeamsError('Could not load teams. Pull down to retry.'));
    }
  }

  Future<void> refresh() => load();

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<List<TeamSpend>> _fetchTeams() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      TeamSpend(id: 'team_1', name: 'Engineering', spend: 11200000, trendPercent: 4.2, memberCount: 38),
      TeamSpend(id: 'team_2', name: 'Sales & marketing', spend: 5420000, trendPercent: 20.4, memberCount: 22),
      TeamSpend(id: 'team_3', name: 'Operations', spend: 1960000, trendPercent: -6.1, memberCount: 14),
      TeamSpend(id: 'team_4', name: 'Product & design', spend: 2870000, trendPercent: 1.8, memberCount: 11),
      TeamSpend(id: 'team_5', name: 'Customer success', spend: 1330000, trendPercent: -2.4, memberCount: 9),
      TeamSpend(id: 'team_6', name: 'People & finance', spend: 980000, trendPercent: 0.5, memberCount: 6),
    ];
  }
}