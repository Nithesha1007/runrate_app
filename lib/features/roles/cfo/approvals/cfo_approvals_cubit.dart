import 'package:flutter_bloc/flutter_bloc.dart';
import 'cfo_approval_state.dart';

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

  void setTab(ApprovalTab tab) {
    final current = state;
    if (current is! CfoApprovalsLoaded) return;
    emit(current.copyWith(activeTab: tab));
  }

  void setFilter(ApprovalFilter filter) {
    final current = state;
    if (current is! CfoApprovalsLoaded) return;
    emit(current.copyWith(filter: filter));
  }

  Future<void> approve(String requestId) async {
    final current = state;
    if (current is! CfoApprovalsLoaded) return;

    emit(current.copyWith(actionInFlightId: requestId));
    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final updated = current.requests
          .map((r) => r.id == requestId
              ? r.copyWith(status: ApprovalStatus.approved, decidedDate: DateTime.now())
              : r)
          .toList();
      emit(current.copyWith(requests: updated, clearActionInFlightId: true));
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
              ? r.copyWith(
                  status: ApprovalStatus.rejected,
                  rejectionMessage: message,
                  decidedDate: DateTime.now(),
                )
              : r)
          .toList();
      emit(current.copyWith(requests: updated, clearActionInFlightId: true));
    } catch (_) {
      emit(current.copyWith(clearActionInFlightId: true));
    }
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<List<ApprovalRequest>> _fetchApprovals() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return [
      ApprovalRequest(
        id: 'appr_1',
        title: 'Annual Salesforce renewal',
        categoryLabel: 'Software',
        requesterName: 'Priya Shah',
        requesterRole: 'CFO',
        requestedDate: DateTime(2026, 8, 15),
        amount: 54000,
        priority: ApprovalPriority.urgent,
        businessJustification:
            'Annual renewal for the core CRM platform used by sales and support. '
            'Lapsing would interrupt pipeline tracking for the whole team.',
        department: 'Sales',
        currentUsage: 88000,
        budgetLimit: 120000,
        status: ApprovalStatus.pending,
      ),
      ApprovalRequest(
        id: 'appr_2',
        title: 'New AWS Reserved Instances',
        categoryLabel: 'Infrastructure',
        requesterName: 'Sam Rivera',
        requesterRole: 'Eng Mgr',
        requestedDate: DateTime(2026, 8, 14),
        amount: 21500,
        priority: ApprovalPriority.normal,
        businessJustification:
            'Locking in reserved pricing for baseline compute ahead of the Q4 traffic '
            'increase, cutting on-demand spend.',
        department: 'Engineering',
        currentUsage: 65000,
        budgetLimit: 100000,
        status: ApprovalStatus.pending,
      ),
      ApprovalRequest(
        id: 'appr_3',
        title: 'Design team Figma seats',
        categoryLabel: 'Software',
        requesterName: 'Alex M.',
        requesterRole: 'Design Lead',
        requestedDate: DateTime(2026, 8, 12),
        amount: 12500,
        priority: ApprovalPriority.normal,
        businessJustification: 'Two additional seats for new design hires.',
        department: 'Design',
        currentUsage: 32000,
        budgetLimit: 50000,
        status: ApprovalStatus.pending,
      ),
    ];
  }
}