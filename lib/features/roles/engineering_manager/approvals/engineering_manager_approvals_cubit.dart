import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'pending_requests_repository.dart';

/// Team budget context for the hero card.
/// ASSUMPTION FLAG: I don't have your budget data source, so this is a
/// static mock. If EM Home already tracks a team budget somewhere, wire
/// `_budget` below to that instead so Home and Approvals agree on the
/// remaining-budget number.
class TeamBudgetInfo {
  const TeamBudgetInfo({
    required this.totalMonthlyBudget,
    required this.remainingBudget,
  });
  final double totalMonthlyBudget;
  final double remainingBudget;
}

class EngineeringManagerApprovalsData {
  const EngineeringManagerApprovalsData({
    required this.requests,
    required this.budget,
  });

  final List<PendingRequestData> requests;
  final TeamBudgetInfo budget;

  List<PendingRequestData> get pending {
    final list =
        requests.where((r) => r.decision == RequestDecision.pending).toList();
    list.sort((a, b) => a.priority.sortWeight.compareTo(b.priority.sortWeight));
    return list;
  }

  List<PendingRequestData> get history {
    final list =
        requests.where((r) => r.decision != RequestDecision.pending).toList();
    list.sort((a, b) =>
        (b.decidedAt ?? b.requestDate).compareTo(a.decidedAt ?? a.requestDate));
    return list;
  }

  int get pendingCount => pending.length;
  int get urgentCount =>
      pending.where((r) => r.priority == RequestPriority.high).length;
  double get totalMonthlyPending =>
      pending.fold(0.0, (sum, r) => sum + r.monthlyCost);

  /// Count for a priority filter chip. Pass null for "All".
  int countFor(RequestPriority? p) => p == null
      ? pending.length
      : pending.where((r) => r.priority == p).length;
}

sealed class EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsState();
}

class EngineeringManagerApprovalsLoading
    extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsLoading();
}

class EngineeringManagerApprovalsLoaded
    extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsLoaded(this.data, {this.processingId});

  final EngineeringManagerApprovalsData data;

  /// id of the request currently being actioned, if any.
  final String? processingId;

  bool get isProcessing => processingId != null;
}

class EngineeringManagerApprovalsError
    extends EngineeringManagerApprovalsState {
  const EngineeringManagerApprovalsError(this.message);
  final String message;
}

/// Reads and writes through [PendingRequestsRepository.instance] — see
/// that file's doc comment for how to point your existing
/// `EngineeringManagerHomeCubit` at the same source so pending counts
/// never drift between Home and this screen.
class EngineeringManagerApprovalsCubit
    extends Cubit<EngineeringManagerApprovalsState> {
  EngineeringManagerApprovalsCubit()
      : super(const EngineeringManagerApprovalsLoading()) {
    _sub = PendingRequestsRepository.instance.changes.listen(_onRepoChange);
    loadApprovals();
  }

  late final StreamSubscription<List<PendingRequestData>> _sub;

  // Mock — see class doc comment above.
  static const _budget =
      TeamBudgetInfo(totalMonthlyBudget: 60000, remainingBudget: 22400);

  Future<void> loadApprovals() async {
    emit(const EngineeringManagerApprovalsLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(EngineeringManagerApprovalsLoaded(
        EngineeringManagerApprovalsData(
          requests: PendingRequestsRepository.instance.all,
          budget: _budget,
        ),
      ));
    } catch (e) {
      emit(EngineeringManagerApprovalsError(e.toString()));
    }
  }

  Future<void> refresh() => loadApprovals();

  void _onRepoChange(List<PendingRequestData> requests) {
    final current = state;
    if (current is EngineeringManagerApprovalsLoaded) {
      emit(EngineeringManagerApprovalsLoaded(
        EngineeringManagerApprovalsData(
            requests: requests, budget: current.data.budget),
      ));
    }
  }

  Future<void> approve(String requestId) async {
    final current = state;
    if (current is! EngineeringManagerApprovalsLoaded) return;

    emit(EngineeringManagerApprovalsLoaded(current.data,
        processingId: requestId));
    await Future.delayed(const Duration(milliseconds: 450));
    PendingRequestsRepository.instance.approve(requestId);

    final latest = state;
    if (latest is EngineeringManagerApprovalsLoaded) {
      emit(EngineeringManagerApprovalsLoaded(latest.data));
    }
  }

  Future<void> reject(String requestId, String reason) async {
    if (reason.trim().isEmpty) return;
    final current = state;
    if (current is! EngineeringManagerApprovalsLoaded) return;

    emit(EngineeringManagerApprovalsLoaded(current.data,
        processingId: requestId));
    await Future.delayed(const Duration(milliseconds: 450));
    PendingRequestsRepository.instance.reject(requestId, reason.trim());

    final latest = state;
    if (latest is EngineeringManagerApprovalsLoaded) {
      emit(EngineeringManagerApprovalsLoaded(latest.data));
    }
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}