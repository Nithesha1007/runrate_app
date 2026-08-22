import 'package:runrate/shared/models/approval_model.dart' as shared;
export 'package:runrate/shared/models/approval_model.dart' show ApprovalStatus;

enum ApprovalPriority { low, medium, high, critical }

class ApprovalModel extends shared.ApprovalModel {
  final String department;
  final String businessJustification;
  final String expectedRoi;
  final String cfoRecommendation;
  final ApprovalPriority priority;
  String? moreInfoRequest;

  ApprovalModel({
    required super.id,
    required super.requesterName,
    this.department = 'Operations',
    required super.title,
    required super.amount,
    required super.category,
    required super.requestedAt,
    this.businessJustification =
        'Enables the team to maintain delivery velocity and supports current roadmap commitments.',
    this.expectedRoi = '3.1x within 12 months',
    this.cfoRecommendation = 'Approve — within quarterly discretionary budget.',
    this.priority = ApprovalPriority.medium,
    super.status,
    super.declineReason,
    this.moreInfoRequest,
  });
}
