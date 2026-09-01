import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Category of the thing being requested — drives both the category badge
/// and the icon shown on a card.
enum ApprovalRequestType { subscription, infrastructure, creativeTool, travel, other }

String typeLabel(ApprovalRequestType type) {
  switch (type) {
    case ApprovalRequestType.subscription:
      return 'Software';
    case ApprovalRequestType.infrastructure:
      return 'Infrastructure';
    case ApprovalRequestType.creativeTool:
      return 'Creative';
    case ApprovalRequestType.travel:
      return 'Travel';
    case ApprovalRequestType.other:
      return 'Other';
  }
}

/// How time-sensitive the request is. Only meaningful while a request is
/// still pending — it's the employee's own read on urgency, set at
/// submission time.
enum ApprovalUrgency { urgent, normal }

/// Pending -> Approved / Rejected, or parked as "Needs Info" when the
/// reviewer has asked a follow-up question. All of these transitions are
/// driven by the reviewer (manager/finance/etc) — the employee only ever
/// creates or withdraws a request; they never set this value themselves.
enum ApprovalDecision { pending, approved, needsInfo, rejected }

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.itemName,
    required this.type,
    required this.amount,
    required this.approverName,
    required this.submittedAt,
    this.urgency = ApprovalUrgency.normal,
    this.decision = ApprovalDecision.pending,
    this.note,
  });

  final String id;

  /// The thing being requested, e.g. "Annual Salesforce renewal".
  final String itemName;
  final ApprovalRequestType type;

  /// Amount in rupees.
  final double amount;

  /// Who this request is/was awaiting sign-off from, e.g. "Priya Shah (CFO)".
  final String approverName;
  final DateTime submittedAt;
  final ApprovalUrgency urgency;
  final ApprovalDecision decision;

  /// Contextual note shown under the card:
  /// - for [ApprovalDecision.pending]: an AI recommendation to the reviewer
  /// - for [ApprovalDecision.needsInfo]: what the reviewer asked for
  final String? note;

  ApprovalRequest copyWith({
    ApprovalDecision? decision,
    String? note,
  }) {
    return ApprovalRequest(
      id: id,
      itemName: itemName,
      type: type,
      amount: amount,
      approverName: approverName,
      submittedAt: submittedAt,
      urgency: urgency,
      decision: decision ?? this.decision,
      note: note ?? this.note,
    );
  }
}

enum EmployeeApprovalsStatus { initial, loading, loaded, error }

@immutable
class EmployeeApprovalsState {
  const EmployeeApprovalsState({
    this.status = EmployeeApprovalsStatus.initial,
    this.requests = const [],
    this.processingIds = const {},
    this.errorMessage,
  });

  final EmployeeApprovalsStatus status;
  final List<ApprovalRequest> requests;

  /// Ids currently mid-withdraw, so their row can show a spinner.
  final Set<String> processingIds;
  final String? errorMessage;

  bool get isLoading => status == EmployeeApprovalsStatus.loading;
  bool get hasError => status == EmployeeApprovalsStatus.error;

  List<ApprovalRequest> get pending =>
      requests.where((r) => r.decision == ApprovalDecision.pending).toList();

  List<ApprovalRequest> get history =>
      requests.where((r) => r.decision != ApprovalDecision.pending).toList();

  int get urgentPendingCount => pending
      .where((r) => r.urgency == ApprovalUrgency.urgent)
      .length;

  double get pendingValue => pending.fold(0.0, (sum, r) => sum + r.amount);

  int get approvedThisMonthCount {
    final now = DateTime.now();
    return requests
        .where((r) =>
            r.decision == ApprovalDecision.approved &&
            r.submittedAt.year == now.year &&
            r.submittedAt.month == now.month)
        .length;
  }

  EmployeeApprovalsState copyWith({
    EmployeeApprovalsStatus? status,
    List<ApprovalRequest>? requests,
    Set<String>? processingIds,
    String? errorMessage,
  }) {
    return EmployeeApprovalsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      processingIds: processingIds ?? this.processingIds,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Employee · Approvals.
///
/// This is the *requester's* view: the employee submits requests, sees
/// their status (including an AI-generated recommendation note that's
/// meant for whoever reviews it), and can withdraw a request while it's
/// still pending. Approving, rejecting, or asking for more info is done
/// by the reviewer elsewhere in the app — not here.
///
/// Backed by mock data (artificial delay) until the real approvals API is
/// wired up. Swap [_fetchRequests] / [_withdrawRequest] / [_submitRequest]
/// for actual repository/service calls when the backend is ready.
class EmployeeApprovalsCubit extends Cubit<EmployeeApprovalsState> {
  EmployeeApprovalsCubit() : super(const EmployeeApprovalsState()) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    emit(state.copyWith(status: EmployeeApprovalsStatus.loading));
    try {
      final requests = await _fetchRequests();
      emit(
        state.copyWith(
          status: EmployeeApprovalsStatus.loaded,
          requests: requests,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeApprovalsStatus.error,
          errorMessage: 'Could not load approvals. Pull to refresh.',
        ),
      );
    }
  }

  /// Withdraws a request the employee submitted, as long as it's still
  /// pending (once a reviewer has acted on it, it can no longer be pulled
  /// back from here).
  Future<void> withdraw(String id) async {
    if (state.processingIds.contains(id)) return;
    emit(state.copyWith(processingIds: {...state.processingIds, id}));

    try {
      await _withdrawRequest(id);
      final updated = state.requests.where((r) => r.id != id).toList();
      final processing = {...state.processingIds}..remove(id);
      emit(state.copyWith(requests: updated, processingIds: processing));
    } catch (_) {
      final processing = {...state.processingIds}..remove(id);
      emit(
        state.copyWith(
          processingIds: processing,
          errorMessage: 'Could not withdraw the request. Try again.',
        ),
      );
    }
  }

  /// Submits a brand-new request, landing as [ApprovalDecision.pending].
  Future<void> submitRequest({
    required String itemName,
    required ApprovalRequestType type,
    required double amount,
    required String approverName,
    required ApprovalUrgency urgency,
  }) async {
    final request = ApprovalRequest(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemName: itemName,
      type: type,
      amount: amount,
      approverName: approverName,
      submittedAt: DateTime.now(),
      urgency: urgency,
    );

    try {
      await _submitRequest(request);
      emit(state.copyWith(requests: [request, ...state.requests]));
    } catch (_) {
      emit(
        state.copyWith(
          errorMessage: 'Could not submit your request. Try again.',
        ),
      );
    }
  }

  Future<void> _withdrawRequest(String id) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _submitRequest(ApprovalRequest request) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<List<ApprovalRequest>> _fetchRequests() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    return [
      ApprovalRequest(
        id: 'r1',
        itemName: 'Annual Salesforce renewal',
        type: ApprovalRequestType.subscription,
        amount: 54000,
        approverName: 'Priya Shah (CFO)',
        submittedAt: now.subtract(const Duration(hours: 3)),
        urgency: ApprovalUrgency.urgent,
        decision: ApprovalDecision.pending,
        note:
            'AI Copilot recommends approval — renewal pricing is flat year-over-year and usage remains high across the sales team.',
      ),
      ApprovalRequest(
        id: 'r2',
        itemName: 'New AWS Reserved Instances',
        type: ApprovalRequestType.infrastructure,
        amount: 21500,
        approverName: 'Sam Rivera (Eng Mgr)',
        submittedAt: now.subtract(const Duration(hours: 20)),
        urgency: ApprovalUrgency.normal,
        decision: ApprovalDecision.pending,
      ),
      ApprovalRequest(
        id: 'r3',
        itemName: 'GitHub Copilot seats',
        type: ApprovalRequestType.subscription,
        amount: 1580,
        approverName: 'Divya Iyer (Eng Mgr)',
        submittedAt: now.subtract(const Duration(days: 1)),
        urgency: ApprovalUrgency.normal,
        decision: ApprovalDecision.pending,
        note:
            'AI Copilot recommends approval based on high engineering productivity metrics associated with this tool across similar teams.',
      ),
      ApprovalRequest(
        id: 'r4',
        itemName: 'Zoom Webinar License',
        type: ApprovalRequestType.other,
        amount: 12000,
        approverName: 'Priya Shah (CFO)',
        submittedAt: DateTime(now.year, now.month, 2),
        decision: ApprovalDecision.approved,
      ),
      ApprovalRequest(
        id: 'r5',
        itemName: 'Adobe Creative Cloud',
        type: ApprovalRequestType.creativeTool,
        amount: 37500,
        approverName: 'Sam Rivera (Eng Mgr)',
        submittedAt: now.subtract(const Duration(days: 10)),
        decision: ApprovalDecision.needsInfo,
        note: 'Manager requested justification for full suite vs single app license.',
      ),
      ApprovalRequest(
        id: 'r6',
        itemName: 'Offsite Flight Upgrade',
        type: ApprovalRequestType.travel,
        amount: 70500,
        approverName: 'Priya Shah (CFO)',
        submittedAt: now.subtract(const Duration(days: 16)),
        decision: ApprovalDecision.rejected,
      ),
    ];
  }
}