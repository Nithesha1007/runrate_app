import 'package:equatable/equatable.dart';
import 'package:runrate/features/roles/ceo/shared/models/approval_model.dart';

class CeoApprovalsState extends Equatable {
  final List<ApprovalModel> approvals;
  final bool loading;
  final int viewIndex; // 0 = pending, 1 = history

  /// Decision timestamps keyed by approval id — tracked here (rather than
  /// on ApprovalModel, whose source we don't own) so the History log can
  /// show when each item was approved/declined.
  final Map<String, DateTime> decisionTimes;

  const CeoApprovalsState({
    this.approvals = const [],
    this.loading = true,
    this.viewIndex = 0,
    this.decisionTimes = const {},
  });

  List<ApprovalModel> get pending =>
      approvals.where((a) => a.status == ApprovalStatus.pending).toList();

  List<ApprovalModel> get history {
    final items =
        approvals.where((a) => a.status != ApprovalStatus.pending).toList();
    items.sort((a, b) {
      final da = decisionTimes[a.id] ?? a.requestedAt;
      final db = decisionTimes[b.id] ?? b.requestedAt;
      return db.compareTo(da);
    });
    return items;
  }

  /// Stake-size heuristic: large-dollar items are flagged urgent since
  /// ApprovalModel has no explicit priority field of its own.
  ApprovalPriority priorityOf(ApprovalModel approval) =>
      approval.amount >= 50000
          ? ApprovalPriority.high
          : ApprovalPriority.medium;

  CeoApprovalsState copyWith({
    List<ApprovalModel>? approvals,
    bool? loading,
    int? viewIndex,
    Map<String, DateTime>? decisionTimes,
  }) {
    return CeoApprovalsState(
      approvals: approvals ?? this.approvals,
      loading: loading ?? this.loading,
      viewIndex: viewIndex ?? this.viewIndex,
      decisionTimes: decisionTimes ?? this.decisionTimes,
    );
  }

  @override
  List<Object?> get props => [approvals, loading, viewIndex, decisionTimes];
}
