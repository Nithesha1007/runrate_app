import 'package:flutter_bloc/flutter_bloc.dart';
import 'cfo_more_state.dart';

export 'cfo_more_state.dart';

class CfoMoreCubit extends Cubit<CfoMoreState> {
  CfoMoreCubit() : super(const CfoMoreInitial()) {
    load();
  }

  Future<void> load() async {
    emit(const CfoMoreLoading());
    try {
      final data = await _fetchMoreData();
      emit(data);
    } catch (_) {
      emit(const CfoMoreError('Could not load this screen. Pull down to retry.'));
    }
  }

  Future<void> logOut() async {
    final current = state;
    if (current is! CfoMoreLoaded) return;

    emit(current.copyWith(isLoggingOut: true));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      emit(const CfoMoreLoggedOut());
    } catch (_) {
      emit(current.copyWith(isLoggingOut: false));
    }
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<CfoMoreLoaded> _fetchMoreData() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    return const CfoMoreLoaded(
      profile: CfoProfile(
        name: 'Sarah Jenkins',
        roleLabel: 'CFO / Finance',
        department: 'Finance',
        avatarUrl: null,
      ),
      departmentsManaged: 12,
      aiBudgetAllocation: '\$3.10M allocation',
      walletBalance: '\$14.2k available',
      savingsInsightsNewCount: 14,
      notificationsCount: 3,
      appVersion: 'v2.4.1',
    );
  }
}