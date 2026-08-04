import 'package:equatable/equatable.dart';
import '../../../../shared/models/approval_model.dart';

class CeoApprovalsState extends Equatable {
  final List<ApprovalModel> approvals;
  final bool loading;

  const CeoApprovalsState({this.approvals = const [], this.loading = true});

  List<ApprovalModel> get pending => approvals.where((a) => a.status == ApprovalStatus.pending).toList();

  CeoApprovalsState copyWith({List<ApprovalModel>? approvals, bool? loading}) {
    return CeoApprovalsState(approvals: approvals ?? this.approvals, loading: loading ?? this.loading);
  }

  @override
  List<Object?> get props => [approvals, loading];
}
