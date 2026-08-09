enum DepartmentHealth { onTrack, atRisk, critical }

class DepartmentMember {
  final String name;
  final String role;
  final double aiSpend;
  final int toolsUsed;

  const DepartmentMember({
    required this.name,
    required this.role,
    required this.aiSpend,
    required this.toolsUsed,
  });
}

class TeamModel {
  final String name;
  final double spend;
  final double trendPercent;
  final int memberCount;

  // Extended fields
  final String departmentHead;
  final double monthlyBudget;
  final double aiAdoption; // 0-100
  final double aiRoi; // multiplier
  final double productivityScore; // 0-100
  final int activeAiTools;
  final String topAiTool;
  final DepartmentHealth health;
  final List<DepartmentMember> members;
  final List<double> monthlyTrend;

  const TeamModel({
    required this.name,
    required this.spend,
    required this.trendPercent,
    required this.memberCount,
    this.departmentHead = 'Unassigned',
    this.monthlyBudget = 0,
    this.aiAdoption = 0,
    this.aiRoi = 0,
    this.productivityScore = 0,
    this.activeAiTools = 0,
    this.topAiTool = '—',
    this.health = DepartmentHealth.onTrack,
    this.members = const [],
    this.monthlyTrend = const [],
  });

  double get budgetUsedPercent =>
      monthlyBudget <= 0 ? 0 : (spend / monthlyBudget * 100).clamp(0, 999);
}
