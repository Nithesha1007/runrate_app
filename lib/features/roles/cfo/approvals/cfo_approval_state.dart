import 'package:flutter/material.dart';

enum ApprovalStatus { pending, approved, rejected }

enum ApprovalPriority { urgent, normal }

extension ApprovalPriorityX on ApprovalPriority {
  String get label => this == ApprovalPriority.urgent ? 'URGENT' : 'NORMAL';
}

enum ApprovalFilter { all, urgent, normal }

enum ApprovalTab { pending, history }

@immutable
class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.categoryLabel,
    required this.requesterName,
    required this.requesterRole,
    required this.requestedDate,
    required this.amount,
    required this.priority,
    required this.businessJustification,
    required this.department,
    required this.currentUsage,
    required this.budgetLimit,
    required this.status,
    this.rejectionMessage,
    this.decidedDate,
  });

  final String id;
  final String title;
  final String categoryLabel;
  final String requesterName;
  final String requesterRole;
  final DateTime requestedDate;
  final double amount;
  final ApprovalPriority priority;
  final String businessJustification;
  final String department;
  final double currentUsage;
  final double budgetLimit;
  final ApprovalStatus status;
  final String? rejectionMessage;
  final DateTime? decidedDate;

  double get budgetImpactRatio {
    if (budgetLimit <= 0) return 0;
    return ((currentUsage + amount) / budgetLimit).clamp(0, 1).toDouble();
  }

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    String? rejectionMessage,
    DateTime? decidedDate,
  }) {
    return ApprovalRequest(
      id: id,
      title: title,
      categoryLabel: categoryLabel,
      requesterName: requesterName,
      requesterRole: requesterRole,
      requestedDate: requestedDate,
      amount: amount,
      priority: priority,
      businessJustification: businessJustification,
      department: department,
      currentUsage: currentUsage,
      budgetLimit: budgetLimit,
      status: status ?? this.status,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
      decidedDate: decidedDate ?? this.decidedDate,
    );
  }
}

abstract class CfoApprovalsState {
  const CfoApprovalsState();
}

class CfoApprovalsInitial extends CfoApprovalsState {
  const CfoApprovalsInitial();
}

class CfoApprovalsLoading extends CfoApprovalsState {
  const CfoApprovalsLoading();
}

class CfoApprovalsError extends CfoApprovalsState {
  const CfoApprovalsError(this.message);
  final String message;
}


class CfoApprovalsLoaded extends CfoApprovalsState {
  const CfoApprovalsLoaded(
    this.requests, {
    this.filter = ApprovalFilter.all,
    this.activeTab = ApprovalTab.pending,
    this.actionInFlightId,
  });

  final List<ApprovalRequest> requests;
  final ApprovalFilter filter;
  final ApprovalTab activeTab;
  final String? actionInFlightId;

  List<ApprovalRequest> get pendingRequests =>
      requests.where((r) => r.status == ApprovalStatus.pending).toList();

  List<ApprovalRequest> get historyRequests =>
      requests.where((r) => r.status != ApprovalStatus.pending).toList()
        ..sort((a, b) => (b.decidedDate ?? b.requestedDate)
            .compareTo(a.decidedDate ?? a.requestedDate));

  int get urgentPendingCount =>
      pendingRequests.where((r) => r.priority == ApprovalPriority.urgent).length;

  int get normalPendingCount =>
      pendingRequests.where((r) => r.priority == ApprovalPriority.normal).length;

  double get totalPendingValue =>
      pendingRequests.fold(0, (sum, r) => sum + r.amount);

  int get approvedThisMonthCount {
    final now = DateTime.now();
    return requests.where((r) {
      final d = r.decidedDate;
      return r.status == ApprovalStatus.approved &&
          d != null &&
          d.year == now.year &&
          d.month == now.month;
    }).length;
  }

  ApprovalRequest? requestById(String id) {
    for (final r in requests) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<ApprovalRequest> get filteredRequests {
    final base =
        activeTab == ApprovalTab.pending ? pendingRequests : historyRequests;
    if (activeTab == ApprovalTab.history) return base;
    switch (filter) {
      case ApprovalFilter.urgent:
        return base.where((r) => r.priority == ApprovalPriority.urgent).toList();
      case ApprovalFilter.normal:
        return base.where((r) => r.priority == ApprovalPriority.normal).toList();
      case ApprovalFilter.all:
        return base;
    }
  }

  CfoApprovalsLoaded copyWith({
    List<ApprovalRequest>? requests,
    ApprovalFilter? filter,
    ApprovalTab? activeTab,
    String? actionInFlightId,
    bool clearActionInFlightId = false,
  }) {
    return CfoApprovalsLoaded(
      requests ?? this.requests,
      filter: filter ?? this.filter,
      activeTab: activeTab ?? this.activeTab,
      actionInFlightId:
          clearActionInFlightId ? null : (actionInFlightId ?? this.actionInFlightId),
    );
  }
}

String formatInr(num value) {
  final s = value.round().toString();
  final buffer = StringBuffer();
  final digits = s.split('').reversed.toList();
  for (int i = 0; i < digits.length; i++) {
    if (i == 3) {
      buffer.write(',');
    } else if (i > 3 && (i - 3) % 2 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return '₹${buffer.toString().split('').reversed.join()}';
}

String formatShortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
