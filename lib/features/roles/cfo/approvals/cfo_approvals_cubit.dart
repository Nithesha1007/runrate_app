import 'package:flutter_bloc/flutter_bloc.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

enum ApprovalStatus { pending, approved, rejected }

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.requesterName,
    required this.category,
    required this.amount,
    required this.submittedDaysAgo,
    this.status = ApprovalStatus.pending,
    this.rejectionMessage,
  });

  final String id;
  final String requesterName;
  final String category;
  final double amount;
  final int submittedDaysAgo;
  final ApprovalStatus status;
  final String? rejectionMessage;

  ApprovalRequest copyWith({
    ApprovalStatus? status,
    String? rejectionMessage,
  }) {
    return ApprovalRequest(
      id: id,
      requesterName: requesterName,
      category: category,
      amount: amount,
      submittedDaysAgo: submittedDaysAgo,
      status: status ?? this.status,
      rejectionMessage: rejectionMessage ?? this.rejectionMessage,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoApprovalsState {
  const CfoApprovalsState();
}

class CfoApprovalsInitial extends CfoApprovalsState {
  const CfoApprovalsInitial();
}

class CfoApprovalsLoading extends CfoApprovalsState {
  const CfoApprovalsLoading();
}

class CfoApprovalsLoaded extends CfoApprovalsState {
  const CfoApprovalsLoaded(this.requests, {this.actionInFlightId});

  final List<ApprovalRequest> requests;
  final String? actionInFlightId;

  List<ApprovalRequest> get pending =>
      requests.where((r) => r.status == ApprovalStatus.pending).toList();

  CfoApprovalsLoaded copyWith({
    List<ApprovalRequest>? requests,
    String? actionInFlightId,
    bool clearActionInFlightId = false,
  }) {
    return CfoApprovalsLoaded(
      requests ?? this.requests,
      actionInFlightId: clearActionInFlightId ? null : (actionInFlightId ?? this.actionInFlightId),
    );
  }
}

class CfoApprovalsError extends CfoApprovalsState {
  const CfoApprovalsError(this.message);

  final String message;
}

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoApprovalsCubit extends Cubit<CfoApprovalsState> {
  CfoApprovalsCubit() : super(const CfoApprovalsInitial()) {
    load();
  }

  Future<void> load() async {
    emit(const CfoApprovalsLoading());
    try {
      final requests = await _fetchApprovals();
      emit(CfoApprovalsLoaded(requests));
    } catch (_) {
      emit(const CfoApprovalsError('Could not load approvals. Pull down to retry.'));
    }
  }

  Future<void> refresh() => load();

  Future<void> approve(String requestId) async {
    final current = state;
    if (current is! CfoApprovalsLoaded) return;

    emit(current.copyWith(actionInFlightId: requestId));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final updated = current.requests
          .map((r) => r.id == requestId ? r.copyWith(status: ApprovalStatus.approved) : r)
          .toList();
      emit(CfoApprovalsLoaded(updated));
    } catch (_) {
      emit(current.copyWith(clearActionInFlightId: true));
    }
  }

  Future<void> reject(String requestId, String message) async {
    final current = state;
    if (current is! CfoApprovalsLoaded) return;

    emit(current.copyWith(actionInFlightId: requestId));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final updated = current.requests
          .map((r) => r.id == requestId
              ? r.copyWith(status: ApprovalStatus.rejected, rejectionMessage: message)
              : r)
          .toList();
      emit(CfoApprovalsLoaded(updated));
    } catch (_) {
      emit(current.copyWith(clearActionInFlightId: true));
    }
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<List<ApprovalRequest>> _fetchApprovals() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      ApprovalRequest(
        id: 'appr_1',
        requesterName: 'Priya Menon',
        category: 'Travel reimbursement',
        amount: 24500,
        submittedDaysAgo: 1,
      ),
      ApprovalRequest(
        id: 'appr_2',
        requesterName: 'Arjun Verma',
        category: 'New SaaS subscription',
        amount: 68000,
        submittedDaysAgo: 2,
      ),
      ApprovalRequest(
        id: 'appr_3',
        requesterName: 'Sneha Iyer',
        category: 'Team offsite budget',
        amount: 150000,
        submittedDaysAgo: 3,
      ),
      ApprovalRequest(
        id: 'appr_4',
        requesterName: 'Karthik Rao',
        category: 'Equipment purchase',
        amount: 42000,
        submittedDaysAgo: 4,
      ),
    ];
  }
}