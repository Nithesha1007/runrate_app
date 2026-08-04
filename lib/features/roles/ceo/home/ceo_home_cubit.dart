import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_home_state.dart';

class CeoHomeCubit extends Cubit<CeoHomeState> {
  final CeoMockRepository _repo;
  CeoHomeCubit(this._repo) : super(CeoHomeLoading()) {
    load();
  }

  Future<void> load() async {
    emit(CeoHomeLoading());
    try {
      final kpis = await _repo.fetchKpis();
      final chart = await _repo.fetchDeptSpendChart();
      final insights = await _repo.fetchInsights();
      emit(CeoHomeLoaded(kpis: kpis, deptChart: chart, insights: insights));
    } catch (e) {
      emit(CeoHomeError(e.toString()));
    }
  }

  Future<void> refresh() => load();
}
