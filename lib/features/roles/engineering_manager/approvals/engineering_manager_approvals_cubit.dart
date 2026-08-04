import 'package:flutter_bloc/flutter_bloc.dart';

enum ApprovalType { timeOff, expense, toolAccess, resourceRequest }

extension ApprovalTypeLabel on ApprovalType {
  String get label {
    switch (this) {
      case ApprovalType.timeOff:
        return 'Time off';
      case ApprovalType.expense:
        return 'Expense';
      case ApprovalType.toolAccess:
        return 'Tool access';
      case ApprovalType.resourceRequest:
        return 'Resource request';
    }
  }
}

class ApprovalRequest {
  const ApprovalRequest({
    required this.id,
    required this.requesterName,
    required this.requesterInitials,
    required this.type,
    required this.detail,
    required this.submittedAgo,
  });

  final String id;
  final String requesterName;
  final String requesterInitials;
  final ApprovalType type;
  final String detail;
  final String submittedAgo;
}

class EngineeringManagerApprovalsData {
  const EngineeringManagerApprovalsData({required this.pending});

  final List<ApprovalRequest> pending;
}

sealed class EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsState();
}

class EngineeringManagerApprovalsInitial extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsInitial();
}

class EngineeringManagerApprovalsLoading extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsLoading();
}

class EngineeringManagerApprovalsLoaded extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsLoaded(this.data, {this.isProcessing = false});

  final EngineeringManagerApprovalsData data;
  final bool isProcessing;
}

class EngineeringManagerApprovalsError extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsError(this.message);

  final String message;
}

/// Cubit for Engineering Manager · Approvals.
///
/// `loadApprovals()`, `approve()`, and `reject()` call mock repository
/// methods with an artificial delay per spec section 12. Swap the `_mock*`
/// methods for real repository calls once the API is available.
class EngineeringManagerApprovalsCubit extends Cubit<EngineeringManagerApprovalsState> {
  EngineeringManagerApprovalsCubit() : super(const EngineeringManagerApprovalsInitial());

  Future<void> loadApprovals() async {
    emit(const EngineeringManagerApprovalsLoading());
    try {
      final pending = await _mockFetchApprovals();
      emit(EngineeringManagerApprovalsLoaded(EngineeringManagerApprovalsData(pending: pending)));
    } catch (e) {
      emit(EngineeringManagerApprovalsError(e.toString()));
    }
  }

  Future<void> refresh() => loadApprovals();

  Future<void> approve(String requestId) async {
    final current = state;
    if (current is! EngineeringManagerApprovalsLoaded) return;

    emit(EngineeringManagerApprovalsLoaded(current.data, isProcessing: true));
    await _mockSubmitDecision(requestId, approved: true, message: null);

    final remaining = current.data.pending.where((r) => r.id != requestId).toList();
    emit(EngineeringManagerApprovalsLoaded(EngineeringManagerApprovalsData(pending: remaining)));
  }

  Future<void> reject(String requestId, String message) async {
    final current = state;
    if (current is! EngineeringManagerApprovalsLoaded) return;

    emit(EngineeringManagerApprovalsLoaded(current.data, isProcessing: true));
    await _mockSubmitDecision(requestId, approved: false, message: message);

    final remaining = current.data.pending.where((r) => r.id != requestId).toList();
    emit(EngineeringManagerApprovalsLoaded(EngineeringManagerApprovalsData(pending: remaining)));
  }

  Future<List<ApprovalRequest>> _mockFetchApprovals() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      ApprovalRequest(
        id: 'req-1',
        requesterName: 'Sara Menon',
        requesterInitials: 'SM',
        type: ApprovalType.timeOff,
        detail: 'Aug 18 – Aug 22 (5 days)',
        submittedAgo: '3h ago',
      ),
      ApprovalRequest(
        id: 'req-2',
        requesterName: 'Rohan Verma',
        requesterInitials: 'RV',
        type: ApprovalType.toolAccess,
        detail: 'Production database read access',
        submittedAgo: '6h ago',
      ),
      ApprovalRequest(
        id: 'req-3',
        requesterName: 'Neha Patil',
        requesterInitials: 'NP',
        type: ApprovalType.expense,
        detail: 'Conference ticket, \u20B912,500',
        submittedAgo: '1d ago',
      ),
      ApprovalRequest(
        id: 'req-4',
        requesterName: 'Arjun Kapoor',
        requesterInitials: 'AK',
        type: ApprovalType.resourceRequest,
        detail: 'Additional staging environment',
        submittedAgo: '2d ago',
      ),
    ];
  }

  Future<void> _mockSubmitDecision(
    String requestId, {
    required bool approved,
    required String? message,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}