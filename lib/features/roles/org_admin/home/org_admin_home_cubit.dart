import 'package:flutter_bloc/flutter_bloc.dart';

enum OrgAdminHomeStatus { initial, loading, loaded, error }

enum AdminRoleType { admin, manager, staff, viewer }

class SystemHealth {
  const SystemHealth({
    required this.uptimePercent,
    required this.activeSessions,
    required this.isOperational,
  });

  final double uptimePercent;
  final int activeSessions;
  final bool isOperational;
}

class UserManagementSummary {
  const UserManagementSummary({
    required this.totalUsers,
    required this.newSignups,
    required this.pendingApprovals,
  });

  final int totalUsers;
  final int newSignups;
  final int pendingApprovals;
}

class RoleSummary {
  const RoleSummary({
    required this.type,
    required this.label,
    required this.memberCount,
  });

  final AdminRoleType type;
  final String label;
  final int memberCount;
}

class ActivityLogEntry {
  const ActivityLogEntry({required this.message, required this.timeAgo});

  final String message;
  final String timeAgo;
}

class OrgAdminHomeData {
  const OrgAdminHomeData({
    required this.adminName,
    required this.orgName,
    required this.systemHealth,
    required this.userSummary,
    required this.roles,
    required this.activity,
  });

  final String adminName;
  final String orgName;
  final SystemHealth systemHealth;
  final UserManagementSummary userSummary;
  final List<RoleSummary> roles;
  final List<ActivityLogEntry> activity;
}

class OrgAdminHomeState {
  const OrgAdminHomeState({
    this.status = OrgAdminHomeStatus.initial,
    this.data,
    this.errorMessage,
  });

  final OrgAdminHomeStatus status;
  final OrgAdminHomeData? data;
  final String? errorMessage;

  OrgAdminHomeState copyWith({
    OrgAdminHomeStatus? status,
    OrgAdminHomeData? data,
    String? errorMessage,
  }) {
    return OrgAdminHomeState(
      status: status ?? this.status,
      data: data ?? this.data,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Org Admin · Home.
/// Loads dashboard data from a mock repository call (Future with an
/// artificial delay, per spec section 12). Replace [_fetchMockDashboard]
/// with a real repository call when the backend is available.
class OrgAdminHomeCubit extends Cubit<OrgAdminHomeState> {
  OrgAdminHomeCubit() : super(const OrgAdminHomeState());

  Future<void> fetchDashboard() async {
    emit(state.copyWith(status: OrgAdminHomeStatus.loading));
    try {
      final data = await _fetchMockDashboard();
      emit(state.copyWith(status: OrgAdminHomeStatus.loaded, data: data));
    } catch (e) {
      emit(OrgAdminHomeState(
        status: OrgAdminHomeStatus.error,
        errorMessage: 'Could not load dashboard. Pull down to try again.',
      ));
    }
  }

  Future<OrgAdminHomeData> _fetchMockDashboard() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const OrgAdminHomeData(
      adminName: 'Rhea',
      orgName: 'BizBharat',
      systemHealth: SystemHealth(
        uptimePercent: 99.98,
        activeSessions: 1284,
        isOperational: true,
      ),
      userSummary: UserManagementSummary(
        totalUsers: 4820,
        newSignups: 156,
        pendingApprovals: 12,
      ),
      roles: [
        RoleSummary(type: AdminRoleType.admin, label: 'Admin', memberCount: 6),
        RoleSummary(type: AdminRoleType.manager, label: 'Manager', memberCount: 24),
        RoleSummary(type: AdminRoleType.staff, label: 'Staff', memberCount: 312),
        RoleSummary(type: AdminRoleType.viewer, label: 'Viewer', memberCount: 48),
      ],
      activity: [
        ActivityLogEntry(message: 'Priya approved a spend request', timeAgo: '2m ago'),
        ActivityLogEntry(message: 'New team "Growth" created', timeAgo: '1h ago'),
        ActivityLogEntry(message: "Rohit's role changed to Manager", timeAgo: '3h ago'),
      ],
    );
  }
}