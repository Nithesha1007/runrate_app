import 'package:flutter_bloc/flutter_bloc.dart';

enum OrgAdminApprovalsStatus { initial, loading, loaded, error }

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.title,
    required this.requester,
    required this.detail,
    required this.submittedAgo,
  });

  final String id;
  final String title;
  final String requester;
  final String detail;
  final String submittedAgo;
}

class OrgAdminApprovalsState {
  const OrgAdminApprovalsState({
    this.status = OrgAdminApprovalsStatus.initial,
    this.requests = const [],
    this.processingId,
    this.errorMessage,
  });

  final OrgAdminApprovalsStatus status;
  final List<ApprovalRequest> requests;
  final String? processingId;
  final String? errorMessage;

  OrgAdminApprovalsState copyWith({
    OrgAdminApprovalsStatus? status,
    List<ApprovalRequest>? requests,
    String? processingId,
    bool clearProcessingId = false,
    String? errorMessage,
  }) {
    return OrgAdminApprovalsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      processingId: clearProcessingId ? null : (processingId ?? this.processingId),
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Org Admin · Approvals.
/// Loads pending requests and processes approve/reject actions via mock
/// repository calls (Future with an artificial delay, per spec section 12).
class OrgAdminApprovalsCubit extends Cubit<OrgAdminApprovalsState> {
  OrgAdminApprovalsCubit() : super(const OrgAdminApprovalsState());

  Future<void> loadRequests() async {
    emit(state.copyWith(status: OrgAdminApprovalsStatus.loading));
    try {
      final requests = await _fetchMockRequests();
      emit(state.copyWith(status: OrgAdminApprovalsStatus.loaded, requests: requests));
    } catch (e) {
      emit(state.copyWith(
        status: OrgAdminApprovalsStatus.error,
        errorMessage: 'Could not load approvals. Pull down to try again.',
      ));
    }
  }

  Future<void> approve(String id) async {
    emit(state.copyWith(processingId: id));
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = state.requests.where((r) => r.id != id).toList();
    emit(state.copyWith(requests: updated, clearProcessingId: true));
  }

  /// [message] is the reason shared with the requester. TODO: send it to
  /// the notifications/repository layer once the backend is available.
  Future<void> reject(String id, String message) async {
    emit(state.copyWith(processingId: id));
    await Future.delayed(const Duration(milliseconds: 600));
    final updated = state.requests.where((r) => r.id != id).toList();
    emit(state.copyWith(requests: updated, clearProcessingId: true));
  }

  Future<List<ApprovalRequest>> _fetchMockRequests() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      ApprovalRequest(
        id: '1',
        title: 'Marketing budget increase',
        requester: 'Priya Sharma',
        detail: '₹45,000 additional spend for Q3 campaigns',
        submittedAgo: '2h ago',
      ),
      ApprovalRequest(
        id: '2',
        title: 'New team creation: Growth',
        requester: 'Arjun Mehta',
        detail: '5 members to be added to the new team',
        submittedAgo: '5h ago',
      ),
      ApprovalRequest(
        id: '3',
        title: 'Role change request',
        requester: 'Rohit Verma',
        detail: 'Promote to Manager role',
        submittedAgo: '1d ago',
      ),
    ];
  }
}