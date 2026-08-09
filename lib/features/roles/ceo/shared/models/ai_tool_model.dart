enum ToolStatus { active, renewalDue, underReview }

class AiToolModel {
  final String id;
  final String name;
  final int users;
  final int licenses;
  final double monthlyCost;
  final DateTime renewalDate;
  final ToolStatus status;
  final int licenseUsagePercent;

  AiToolModel({
    required this.id,
    required this.name,
    required this.users,
    required this.licenses,
    required this.monthlyCost,
    required this.renewalDate,
    required this.status,
    required this.licenseUsagePercent,
  });
}
