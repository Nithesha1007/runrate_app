import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_teams_state.dart';

class CeoTeamsCubit extends Cubit<CeoTeamsState> {
  final CeoMockRepository _repo;
  CeoTeamsCubit(this._repo) : super(const CeoTeamsState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final departments = await _repo.fetchDepartmentSummaries();
    emit(state.copyWith(allDepartments: departments, loading: false));
  }

  void search(String query) => emit(state.copyWith(query: query));
}