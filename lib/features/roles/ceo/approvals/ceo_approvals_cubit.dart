import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import '../../../../shared/models/approval_model.dart';
import '../../../../features/notifications/notifications_cubit.dart';
import '../../../../shared/models/notification_model.dart';
import 'ceo_approvals_state.dart';

class CeoApprovalsCubit extends Cubit<CeoApprovalsState> {
  final CeoMockRepository _repo;
  final NotificationsCubit? _notificationsCubit;

  CeoApprovalsCubit(this._repo, [this._notificationsCubit]) : super(const CeoApprovalsState()) {
    load();
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final approvals = await _repo.fetchApprovals();
    emit(state.copyWith(approvals: approvals, loading: false));
  }

  void approve(String id) {
    emit(state.copyWith(
      approvals: [
        for (final a in state.approvals)
          if (a.id == id) (a..status = ApprovalStatus.approved) else a
      ],
    ));
  }

  /// Declines the request and pushes [message] into the requester's
  /// Notification Center, per spec section 8.
  void reject(String id, String message) {
    ApprovalModel? target;
    emit(state.copyWith(
      approvals: [
        for (final a in state.approvals)
          if (a.id == id)
            (target = a
              ..status = ApprovalStatus.declined
              ..declineReason = message)
          else
            a
      ],
    ));
    if (target != null) {
      _notificationsCubit?.push(NotificationModel(
        id: 'reject-\${DateTime.now().microsecondsSinceEpoch}',
        title: 'Request declined: \${target!.title}',
        message: message,
        createdAt: DateTime.now(),
      ));
    }
  }
}
