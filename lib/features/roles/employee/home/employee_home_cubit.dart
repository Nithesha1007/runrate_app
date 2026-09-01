import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Status of a submitted AI-tool request shown on the Home dashboard.
enum ToolRequestStatus { approved, pending, rejected }

extension ToolRequestStatusX on ToolRequestStatus {
  String get label {
    switch (this) {
      case ToolRequestStatus.approved:
        return 'Approved';
      case ToolRequestStatus.pending:
        return 'Pending';
      case ToolRequestStatus.rejected:
        return 'Rejected';
    }
  }

  Color get foreground {
    switch (this) {
      case ToolRequestStatus.approved:
        return const Color(0xFF15803D);
      case ToolRequestStatus.pending:
        return const Color(0xFFB45309);
      case ToolRequestStatus.rejected:
        return const Color(0xFFB91C1C);
    }
  }

  Color get background {
    switch (this) {
      case ToolRequestStatus.approved:
        return const Color(0xFFDCFCE7);
      case ToolRequestStatus.pending:
        return const Color(0xFFFEF3C7);
      case ToolRequestStatus.rejected:
        return const Color(0xFFFEE2E2);
    }
  }
}

/// A single KPI-style stat card (value + trend) on the Home dashboard.
class EmployeeStatCard {
  const EmployeeStatCard({
    required this.id,
    required this.label,
    required this.value,
    required this.icon,
    this.trendLabel,
    this.trendUp = true,
  });

  final String id;
  final String label;
  final String value;
  final IconData icon;
  final String? trendLabel;
  final bool trendUp;
}

/// An active AI-tool subscription billed to the employee's wallet.
class EmployeeSubscription {
  const EmployeeSubscription({
    required this.id,
    required this.name,
    required this.planLabel,
    required this.priceLabel,
    required this.icon,
  });

  final String id;
  final String name;
  final String planLabel;
  final String priceLabel;
  final IconData icon;
}

/// A submitted request for a new AI tool, and its approval status.
class EmployeeToolRequest {
  const EmployeeToolRequest({
    required this.id,
    required this.toolName,
    required this.status,
  });

  final String id;
  final String toolName;
  final ToolRequestStatus status;
}

/// A recent alert (policy update, action required, etc.) for the employee.
class EmployeeAlert {
  const EmployeeAlert({
    required this.id,
    required this.title,
    required this.timeAgo,
    this.actionLabel,
  });

  final String id;
  final String title;
  final String timeAgo;
  final String? actionLabel;
}

enum EmployeeHomeStatus { initial, loading, loaded, error }

@immutable
class EmployeeHomeState {
  const EmployeeHomeState({
    this.status = EmployeeHomeStatus.initial,
    this.employeeName = '',
    this.employeeInitials = '',
    this.roleLabel = 'Employee',
    this.budgetAssigned = 0,
    this.budgetUsed = 0,
    this.unreadNotifications = 0,
    this.statCards = const [],
    this.subscriptions = const [],
    this.toolRequests = const [],
    this.alerts = const [],
    this.errorMessage,
  });

  final EmployeeHomeStatus status;
  final String employeeName;
  final String employeeInitials;
  final String roleLabel;
  final double budgetAssigned;
  final double budgetUsed;
  final int unreadNotifications;
  final List<EmployeeStatCard> statCards;
  final List<EmployeeSubscription> subscriptions;
  final List<EmployeeToolRequest> toolRequests;
  final List<EmployeeAlert> alerts;
  final String? errorMessage;

  bool get isLoading => status == EmployeeHomeStatus.loading;
  bool get hasError => status == EmployeeHomeStatus.error;

  double get budgetRemaining =>
      (budgetAssigned - budgetUsed).clamp(0, budgetAssigned).toDouble();

  /// 0.0–1.0 usage ratio for the progress ring / bar.
  double get budgetUsedFraction =>
      budgetAssigned <= 0 ? 0 : (budgetUsed / budgetAssigned).clamp(0, 1);

  int get budgetUsedPercent => (budgetUsedFraction * 100).round();

  /// Health label + color for the budget status chip, driven by usage.
  String get budgetHealthLabel {
    if (budgetUsedFraction >= 0.95) return 'Over budget';
    if (budgetUsedFraction >= 0.8) return 'Near limit';
    return 'Healthy';
  }

  EmployeeHomeState copyWith({
    EmployeeHomeStatus? status,
    String? employeeName,
    String? employeeInitials,
    String? roleLabel,
    double? budgetAssigned,
    double? budgetUsed,
    int? unreadNotifications,
    List<EmployeeStatCard>? statCards,
    List<EmployeeSubscription>? subscriptions,
    List<EmployeeToolRequest>? toolRequests,
    List<EmployeeAlert>? alerts,
    String? errorMessage,
  }) {
    return EmployeeHomeState(
      status: status ?? this.status,
      employeeName: employeeName ?? this.employeeName,
      employeeInitials: employeeInitials ?? this.employeeInitials,
      roleLabel: roleLabel ?? this.roleLabel,
      budgetAssigned: budgetAssigned ?? this.budgetAssigned,
      budgetUsed: budgetUsed ?? this.budgetUsed,
      unreadNotifications: unreadNotifications ?? this.unreadNotifications,
      statCards: statCards ?? this.statCards,
      subscriptions: subscriptions ?? this.subscriptions,
      toolRequests: toolRequests ?? this.toolRequests,
      alerts: alerts ?? this.alerts,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Employee · Home.
///
/// Backed by a mock repository call (artificial delay) until the real
/// spend/wallet API is wired up. Swap [_fetchDashboard]'s body for an
/// actual repository/service call when the backend is ready.
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
          errorMessage: 'Could not load your AI spend overview. Pull to refresh.',
        ),
      );
    }
  }

  Future<EmployeeHomeState> _fetchDashboard() async {
    await Future.delayed(const Duration(milliseconds: 900));
    return state.copyWith(
      employeeName: 'Alex',
      employeeInitials: 'A',
      roleLabel: 'Employee',
      budgetAssigned: 100,
      budgetUsed: 70,
      unreadNotifications: 1,
      statCards: const [
        EmployeeStatCard(
          id: 's1',
          label: 'Active Subscriptions',
          value: '3',
          icon: Icons.apps_outlined,
          trendLabel: '+1',
          trendUp: true,
        ),
        EmployeeStatCard(
          id: 's2',
          label: 'Monthly AI Spend',
          value: '\$70',
          icon: Icons.bolt_outlined,
          trendLabel: '12%',
          trendUp: true,
        ),
        EmployeeStatCard(
          id: 's3',
          label: 'Pending Requests',
          value: '1',
          icon: Icons.pending_actions_outlined,
          trendLabel: 'New',
          trendUp: true,
        ),
        EmployeeStatCard(
          id: 's4',
          label: 'Budget Used',
          value: '70%',
          icon: Icons.donut_large_outlined,
          trendLabel: '8%',
          trendUp: true,
        ),
      ],
      subscriptions: const [
        EmployeeSubscription(
          id: 'sub1',
          name: 'ChatGPT Plus',
          planLabel: 'Monthly Subscription',
          priceLabel: '\$20.00/mo',
          icon: Icons.chat_bubble_outline,
        ),
        EmployeeSubscription(
          id: 'sub2',
          name: 'Claude Pro',
          planLabel: 'Monthly Subscription',
          priceLabel: '\$20.00/mo',
          icon: Icons.auto_awesome_outlined,
        ),
        EmployeeSubscription(
          id: 'sub3',
          name: 'Midjourney',
          planLabel: 'Monthly Subscription',
          priceLabel: '\$30.00/mo',
          icon: Icons.brush_outlined,
        ),
      ],
      toolRequests: const [
        EmployeeToolRequest(
          id: 'r1',
          toolName: 'Github Copilot',
          status: ToolRequestStatus.approved,
        ),
        EmployeeToolRequest(
          id: 'r2',
          toolName: 'Jasper AI',
          status: ToolRequestStatus.pending,
        ),
      ],
      alerts: const [
        EmployeeAlert(
          id: 'a1',
          title: 'Policy update: new limits on generative image AI tools.',
          timeAgo: '2h ago',
        ),
        EmployeeAlert(
          id: 'a2',
          title: 'Action required: verify your ChatGPT Plus receipt for March.',
          timeAgo: '1d ago',
          actionLabel: 'Verify',
        ),
      ],
    );
  }
}