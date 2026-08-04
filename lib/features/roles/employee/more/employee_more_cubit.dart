import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum EmployeeMoreStatus { initial, loading, loaded, error }

@immutable
class EmployeeMoreState {
  const EmployeeMoreState({
    this.status = EmployeeMoreStatus.initial,
    this.employeeName = '',
    this.employeeInitials = '',
    this.role = '',
    this.isLoggingOut = false,
    this.errorMessage,
  });

  final EmployeeMoreStatus status;
  final String employeeName;
  final String employeeInitials;
  final String role;
  final bool isLoggingOut;
  final String? errorMessage;

  bool get isLoading => status == EmployeeMoreStatus.loading;
  bool get hasError => status == EmployeeMoreStatus.error;

  EmployeeMoreState copyWith({
    EmployeeMoreStatus? status,
    String? employeeName,
    String? employeeInitials,
    String? role,
    bool? isLoggingOut,
    String? errorMessage,
  }) {
    return EmployeeMoreState(
      status: status ?? this.status,
      employeeName: employeeName ?? this.employeeName,
      employeeInitials: employeeInitials ?? this.employeeInitials,
      role: role ?? this.role,
      isLoggingOut: isLoggingOut ?? this.isLoggingOut,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Employee · More.
///
/// Backed by a mock repository call (artificial delay) until the real
/// profile/auth services are wired up. Swap [_fetchProfile] / [logOut]'s
/// body for actual repository/auth calls when ready.
class EmployeeMoreCubit extends Cubit<EmployeeMoreState> {
  EmployeeMoreCubit() : super(const EmployeeMoreState()) {
    _load();
  }

  Future<void> _load() async {
    emit(state.copyWith(status: EmployeeMoreStatus.loading));
    try {
      final profile = await _fetchProfile();
      emit(profile.copyWith(status: EmployeeMoreStatus.loaded));
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeMoreStatus.error,
          errorMessage: 'Could not load your profile.',
        ),
      );
    }
  }

  Future<void> logOut() async {
    if (state.isLoggingOut) return;
    emit(state.copyWith(isLoggingOut: true));
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      // TODO: clear auth session / tokens and navigate to the sign-in flow.
    } finally {
      emit(state.copyWith(isLoggingOut: false));
    }
  }

  Future<EmployeeMoreState> _fetchProfile() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return state.copyWith(
      employeeName: 'Ravi Kumar',
      employeeInitials: 'RK',
      role: 'Software Engineer',
    );
  }
}