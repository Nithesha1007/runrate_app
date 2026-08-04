import 'package:flutter_bloc/flutter_bloc.dart';

/// Tracks which of the 5 bottom-nav tabs (Home, AI, Teams, Approvals, More)
/// is active. Paired with IndexedStack in the role home shells so switching
/// tabs preserves scroll position and state.
class BottomNavCubit extends Cubit<int> {
  BottomNavCubit() : super(0);

  void setIndex(int index) => emit(index);
}
