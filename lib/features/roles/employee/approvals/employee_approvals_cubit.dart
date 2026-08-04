import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ApprovalRequestType { leave, expense, purchase }

enum ApprovalDecision { pending, approved, rejected }

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.requesterName,
    required this.type,
    required this.summary,
    required this.submittedAt,
    this.decision = ApprovalDecision.pending,
    this.decisionMessage,
  });

  final String id;
  final String requesterName;
  final ApprovalRequestType type;
  final String summary;
  final DateTime submittedAt;
  final ApprovalDecision decision;
  final String? decisionMessage;

  ApprovalRequest copyWith({
    ApprovalDecision? decision,
    String? decisionMessage,
  }) {
    return ApprovalRequest(
      id: id,
      requesterName: requesterName,
      type: type,
      summary: summary,
      submittedAt: submittedAt,
      decision: decision ?? this.decision,
      decisionMessage: decisionMessage ?? this.decisionMessage,
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

  /// Ids currently mid-approve/reject, so their row can show a spinner.
  final Set<String> processingIds;
  final String? errorMessage;

  bool get isLoading => status == EmployeeApprovalsStatus.loading;
  bool get hasError => status == EmployeeApprovalsStatus.error;

  List<ApprovalRequest> get pending =>
      requests.where((r) => r.decision == ApprovalDecision.pending).toList();

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
/// Backed by a mock repository call (artificial delay) until the real
/// approvals API is wired up. Swap [_fetchRequests] / [_postDecision] for
/// actual repository/service calls when the backend is ready.
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

  Future<void> approve(String id) => _decide(id, ApprovalDecision.approved);

  Future<void> reject(String id, String message) =>
      _decide(id, ApprovalDecision.rejected, message: message);

  Future<void> _decide(
    String id,
    ApprovalDecision decision, {
    String? message,
  }) async {
    if (state.processingIds.contains(id)) return;
    emit(state.copyWith(processingIds: {...state.processingIds, id}));

    try {
      await _postDecision(id, decision, message);
      final updated = [
        for (final r in state.requests)
          if (r.id == id)
            r.copyWith(decision: decision, decisionMessage: message)
          else
            r,
      ];
      final processing = {...state.processingIds}..remove(id);
      emit(state.copyWith(requests: updated, processingIds: processing));
    } catch (_) {
      final processing = {...state.processingIds}..remove(id);
      emit(
        state.copyWith(
          processingIds: processing,
          errorMessage: 'Could not submit your decision. Try again.',
        ),
      );
    }
  }

  Future<void> _postDecision(
    String id,
    ApprovalDecision decision,
    String? message,
  ) async {
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<List<ApprovalRequest>> _fetchRequests() async {
    await Future.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    return [
      ApprovalRequest(
        id: 'r1',
        requesterName: 'Priya Sharma',
        type: ApprovalRequestType.leave,
        summary: 'Sick leave · 2 days (12-13 Aug)',
        submittedAt: now.subtract(const Duration(hours: 5)),
      ),
      ApprovalRequest(
        id: 'r2',
        requesterName: 'Arjun Nair',
        type: ApprovalRequestType.expense,
        summary: 'Client dinner expense · ₹4,250',
        submittedAt: now.subtract(const Duration(hours: 20)),
      ),
      ApprovalRequest(
        id: 'r3',
        requesterName: 'Divya Iyer',
        type: ApprovalRequestType.purchase,
        summary: 'New laptop charger · ₹1,800',
        submittedAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}