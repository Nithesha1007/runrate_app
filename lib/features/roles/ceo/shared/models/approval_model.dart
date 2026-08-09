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
    required String id,
    required String requesterName,
    this.department = 'Operations',
    required String title,
    required double amount,
    required String category,
    required DateTime requestedAt,
    this.businessJustification =
        'Enables the team to maintain delivery velocity and supports current roadmap commitments.',
    this.expectedRoi = '3.1x within 12 months',
    this.cfoRecommendation = 'Approve — within quarterly discretionary budget.',
    this.priority = ApprovalPriority.medium,
    shared.ApprovalStatus status = shared.ApprovalStatus.pending,
    String? declineReason,
    this.moreInfoRequest,
  }) : super(
          id: id,
          requesterName: requesterName,
          title: title,
          amount: amount,
          category: category,
          requestedAt: requestedAt,
          status: status,
          declineReason: declineReason,
        );
}
