import 'dart:async';

/// EM-tier priority. NOTE: your CEO screen used
/// RequestPriority { urgent, high, normal } — this is a *different* enum
/// scoped to what you asked for here (All / High / Medium / Low). If your
/// real `engineering_manager_home_cubit.dart` already defines a priority
/// enum, delete this one and import that instead — everything below only
/// depends on `.label` and `.sortWeight`.
enum RequestPriority { high, medium, low }

extension RequestPriorityX on RequestPriority {
  String get label => switch (this) {
        RequestPriority.high => 'High',
        RequestPriority.medium => 'Medium',
        RequestPriority.low => 'Low',
      };

  int get sortWeight => switch (this) {
        RequestPriority.high => 0,
        RequestPriority.medium => 1,
        RequestPriority.low => 2,
      };
}

enum RequestDecision { pending, approved, rejected }

/// ASSUMPTION FLAG:
/// This mirrors the exact field list you gave me for the existing
/// `PendingRequestData` in engineering_manager_home_cubit.dart:
/// (id, employeeName, requestedTool, justification, monthlyCost, priority,
/// requestDate). I don't have that file, so if the real types differ
/// (e.g. priority is a String, monthlyCost is an int, requestDate is a
/// formatted String instead of DateTime), you'll need to either adjust
/// this class to match exactly, or map between the two at the boundary.
///
/// I added a few fields beyond the original six (employeeRole, decision,
/// rejectionReason, decidedAt, duplicateTeammateCount) because the card
/// spec needs them — they're optional/defaulted so this stays a strict
/// superset of the original shape and won't break existing Home code that
/// only reads the original six.
class PendingRequestData {
  const PendingRequestData({
    required this.id,
    required this.employeeName,
    required this.requestedTool,
    required this.justification,
    required this.monthlyCost,
    required this.priority,
    required this.requestDate,
    this.employeeRole = '',
    this.decision = RequestDecision.pending,
    this.rejectionReason,
    this.decidedAt,
    this.duplicateTeammateCount = 0,
  });

  final String id;
  final String employeeName;
  final String requestedTool;
  final String justification;
  final double monthlyCost;
  final RequestPriority priority;
  final DateTime requestDate;

  final String employeeRole;
  final RequestDecision decision;
  final String? rejectionReason;
  final DateTime? decidedAt;
  final int duplicateTeammateCount;

  PendingRequestData copyWith({
    RequestDecision? decision,
    String? rejectionReason,
    DateTime? decidedAt,
  }) {
    return PendingRequestData(
      id: id,
      employeeName: employeeName,
      requestedTool: requestedTool,
      justification: justification,
      monthlyCost: monthlyCost,
      priority: priority,
      requestDate: requestDate,
      employeeRole: employeeRole,
      decision: decision ?? this.decision,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      decidedAt: decidedAt ?? this.decidedAt,
      duplicateTeammateCount: duplicateTeammateCount,
    );
  }
}

/// Single in-memory source of truth for pending AI-tool requests.
///
/// WHY THIS EXISTS: you asked for the pending count to stay in sync
/// between EM Home and EM Approvals. Without seeing
/// `EngineeringManagerHomeCubit`, the only safe way to guarantee that is a
/// shared source both cubits read from — a singleton repository with a
/// broadcast stream — rather than having the two cubits reach into each
/// other directly (which would couple them and break if either is
/// disposed independently, e.g. Home staying alive under a bottom nav
/// while Approvals is pushed/popped).
///
/// TO WIRE THIS UP ON YOUR SIDE:
/// Point `EngineeringManagerHomeCubit` at `PendingRequestsRepository.instance`
/// (instead of whatever mock list it currently owns) and have it listen to
/// `.changes` to rebuild its pending-count state. That's the one piece I
/// can't do without that file — everything here is written so it's a
/// drop-in shared source once Home is pointed at it.
///
/// If you'd rather NOT introduce a singleton (e.g. you use dependency
/// injection / get_it / provider for repositories already), swap
/// `PendingRequestsRepository.instance` for an injected instance — the
/// class itself doesn't assume singleton usage anywhere except its own
/// static accessor.
class PendingRequestsRepository {
  PendingRequestsRepository._internal() {
    _requests = _seedMockData();
  }

  static final PendingRequestsRepository instance =
      PendingRequestsRepository._internal();

  late List<PendingRequestData> _requests;
  final _controller = StreamController<List<PendingRequestData>>.broadcast();

  Stream<List<PendingRequestData>> get changes => _controller.stream;
  List<PendingRequestData> get all => List.unmodifiable(_requests);

  void _emit() => _controller.add(all);

  void approve(String id) {
    _requests = _requests
        .map((r) => r.id == id
            ? r.copyWith(
                decision: RequestDecision.approved, decidedAt: DateTime.now())
            : r)
        .toList();
    _emit();
  }

  void reject(String id, String reason) {
    _requests = _requests
        .map((r) => r.id == id
            ? r.copyWith(
                decision: RequestDecision.rejected,
                rejectionReason: reason,
                decidedAt: DateTime.now())
            : r)
        .toList();
    _emit();
  }

  /// Mock data — same numbers should be reflected on EM Home once Home
  /// reads from this repository too, so nothing drifts between screens.
  List<PendingRequestData> _seedMockData() {
    final now = DateTime.now();
    return [
      PendingRequestData(
        id: 'req-1',
        employeeName: 'Arun Kumar',
        employeeRole: 'Senior Engineer · Backend',
        requestedTool: 'Claude Enterprise',
        justification:
            'Need additional seats to support code review turnaround during the payments migration. Current team is blocked on PR reviews most afternoons.',
        monthlyCost: 24000,
        priority: RequestPriority.high,
        requestDate: now.subtract(const Duration(hours: 2)),
        duplicateTeammateCount: 4,
      ),
      PendingRequestData(
        id: 'req-2',
        employeeName: 'Neha Patil',
        employeeRole: 'Engineer · Mobile',
        requestedTool: 'GitHub Copilot',
        justification:
            'Rolling out to the remaining mobile team members after a successful pilot with 3 engineers last quarter.',
        monthlyCost: 1800,
        priority: RequestPriority.medium,
        requestDate: now.subtract(const Duration(hours: 8)),
        duplicateTeammateCount: 3,
      ),
      PendingRequestData(
        id: 'req-3',
        employeeName: 'Rohan Verma',
        employeeRole: 'SRE · Platform',
        requestedTool: 'Cursor',
        justification: 'Evaluating for infra scripting and IaC review speed.',
        monthlyCost: 2000,
        priority: RequestPriority.low,
        requestDate: now.subtract(const Duration(days: 1)),
      ),
      PendingRequestData(
        id: 'req-4',
        employeeName: 'Sara Menon',
        employeeRole: 'Engineering Lead · Frontend',
        requestedTool: 'Claude Enterprise',
        justification:
            'Frontend lead needs a seat to review AI-assisted PRs from the rest of the team.',
        monthlyCost: 4800,
        priority: RequestPriority.medium,
        requestDate: now.subtract(const Duration(days: 2)),
        duplicateTeammateCount: 4,
      ),
      PendingRequestData(
        id: 'req-5',
        employeeName: 'Priya Nair',
        employeeRole: 'Platform Lead',
        requestedTool: 'GitHub Copilot',
        justification: 'Renewal — existing seat, no change in scope.',
        monthlyCost: 1800,
        priority: RequestPriority.low,
        requestDate: now.subtract(const Duration(days: 4)),
        decision: RequestDecision.approved,
        decidedAt: now.subtract(const Duration(days: 3)),
      ),
      PendingRequestData(
        id: 'req-6',
        employeeName: 'Arjun Kapoor',
        employeeRole: 'DevOps Engineer',
        requestedTool: 'Tabnine',
        justification: 'Wanted to try an alternative to Copilot.',
        monthlyCost: 1500,
        priority: RequestPriority.low,
        requestDate: now.subtract(const Duration(days: 5)),
        decision: RequestDecision.rejected,
        rejectionReason: 'Overlaps with existing Copilot seats.',
        decidedAt: now.subtract(const Duration(days: 4)),
      ),
    ];
  }
}
