enum ApprovalStatus { pending, approved, declined }

class ApprovalModel {
  final String id;
  final String requesterName;
  final String title;
  final double amount;
  final String category;
  final DateTime requestedAt;
  ApprovalStatus status;
  String? declineReason;

  ApprovalModel({
    required this.id,
    required this.requesterName,
    required this.title,
    required this.amount,
    required this.category,
    required this.requestedAt,
    this.status = ApprovalStatus.pending,
    this.declineReason,
  });
}
