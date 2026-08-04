import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status of a task shown on the Home dashboard.
enum EmployeeTaskStatus { pending, inProgress, done }

extension EmployeeTaskStatusX on EmployeeTaskStatus {
  String get label {
    switch (this) {
      case EmployeeTaskStatus.pending:
        return 'Pending';
      case EmployeeTaskStatus.inProgress:
        return 'In progress';
      case EmployeeTaskStatus.done:
        return 'Done';
    }
  }

  Color foreground(BuildContext context) {
    switch (this) {
      case EmployeeTaskStatus.pending:
        return const Color(0xFF633806);
      case EmployeeTaskStatus.inProgress:
        return const Color(0xFF0C447C);
      case EmployeeTaskStatus.done:
        return const Color(0xFF27500A);
    }
  }

  Color background(BuildContext context) {
    switch (this) {
      case EmployeeTaskStatus.pending:
        return const Color(0xFFFAC775);
      case EmployeeTaskStatus.inProgress:
        return const Color(0xFFB5D4F4);
      case EmployeeTaskStatus.done:
        return const Color(0xFFC0DD97);
    }
  }
}

class EmployeeTaskItem {
  const EmployeeTaskItem({
    required this.id,
    required this.title,
    required this.status,
  });

  final String id;
  final String title;
  final EmployeeTaskStatus status;
}

class EmployeeAnnouncement {
  const EmployeeAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.postedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime postedAt;
}

enum EmployeeHomeStatus { initial, loading, loaded, error }

@immutable
class EmployeeHomeState {
  const EmployeeHomeState({
    this.status = EmployeeHomeStatus.initial,
    this.employeeName = '',
    this.employeeInitials = '',
    this.isCheckedIn = false,
    this.checkInTime,
    this.tasks = const [],
    this.leaveBalanceDays = 0,
    this.announcements = const [],
    this.unreadNotifications = 0,
    this.errorMessage,
    this.isCheckingIn = false,
  });

  final EmployeeHomeStatus status;
  final String employeeName;
  final String employeeInitials;
  final bool isCheckedIn;
  final DateTime? checkInTime;
  final List<EmployeeTaskItem> tasks;
  final int leaveBalanceDays;
  final List<EmployeeAnnouncement> announcements;
  final int unreadNotifications;
  final String? errorMessage;
  final bool isCheckingIn;

  bool get isLoading => status == EmployeeHomeStatus.loading;
  bool get hasError => status == EmployeeHomeStatus.error;

  EmployeeHomeState copyWith({
    EmployeeHomeStatus? status,
    String? employeeName,
    String? employeeInitials,
    bool? isCheckedIn,
    DateTime? checkInTime,
    List<EmployeeTaskItem>? tasks,
    int? leaveBalanceDays,
    List<EmployeeAnnouncement>? announcements,
    int? unreadNotifications,
    String? errorMessage,
    bool? isCheckingIn,
  }) {
    return EmployeeHomeState(
      status: status ?? this.status,
      employeeName: employeeName ?? this.employeeName,
      employeeInitials: employeeInitials ?? this.employeeInitials,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkInTime: checkInTime ?? this.checkInTime,
      tasks: tasks ?? this.tasks,
      leaveBalanceDays: leaveBalanceDays ?? this.leaveBalanceDays,
      announcements: announcements ?? this.announcements,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      errorMessage: errorMessage,
      isCheckingIn: isCheckingIn ?? this.isCheckingIn,
    );
  }
}

/// State/cubit for Employee · Home.
///
/// Backed by a mock repository call (artificial delay) until the real
/// dashboard API is wired up. Swap [_fetchDashboard] / [checkIn]'s body for
/// actual repository/service calls when the backend is ready.
class EmployeeHomeCubit extends Cubit<EmployeeHomeState> {
  EmployeeHomeCubit() : super(const EmployeeHomeState()) {
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: EmployeeHomeStatus.loading));
    try {
      final data = await _fetchDashboard();
      emit(data.copyWith(status: EmployeeHomeStatus.loaded));
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeHomeStatus.error,
          errorMessage: 'Could not load your dashboard. Pull to refresh.',
        ),
      );
    }
  }

  Future<void> checkIn() async {
    if (state.isCheckedIn || state.isCheckingIn) return;
    emit(state.copyWith(isCheckingIn: true));
    try {
      await Future.delayed(const Duration(milliseconds: 700));
      emit(
        state.copyWith(
          isCheckedIn: true,
          checkInTime: DateTime.now(),
          isCheckingIn: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isCheckingIn: false,
          errorMessage: 'Check-in failed. Try again.',
        ),
      );
    }
  }

  Future<EmployeeHomeState> _fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return state.copyWith(
      employeeName: 'Ravi Kumar',
      employeeInitials: 'RK',
      isCheckedIn: false,
      leaveBalanceDays: 12,
      unreadNotifications: 3,
      tasks: const [
        EmployeeTaskItem(
          id: 't1',
          title: 'Submit expense report',
          status: EmployeeTaskStatus.pending,
        ),
        EmployeeTaskItem(
          id: 't2',
          title: 'Client proposal review',
          status: EmployeeTaskStatus.done,
        ),
        EmployeeTaskItem(
          id: 't3',
          title: 'Team standup notes',
          status: EmployeeTaskStatus.inProgress,
        ),
      ],
      announcements: [
        EmployeeAnnouncement(
          id: 'a1',
          title: 'Office closed 15 Aug',
          body:
              'Office closed on 15 Aug for Independence Day. Plan your leaves accordingly.',
          postedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    );
  }
}