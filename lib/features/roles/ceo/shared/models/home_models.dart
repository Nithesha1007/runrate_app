import 'package:runrate/features/roles/ceo/shared/models/team_model.dart'
    as local_team;

enum HealthStatFormat { currency, percent, months }

class CompanyHealthStat {
  final String label;
  final double value;
  final HealthStatFormat format;
  final double trendPercent;
  final bool trendIsGood;

  const CompanyHealthStat({
    required this.label,
    required this.value,
    required this.format,
    required this.trendPercent,
    required this.trendIsGood,
  });
}

class MeetingModel {
  final String id;
  final String title;
  final String time;
  final List<String> attendees;

  const MeetingModel({
    required this.id,
    required this.title,
    required this.time,
    required this.attendees,
  });
}

class QuickStats {
  final int teamSize;
  final int openTasks;
  final int activeDepartments;

  const QuickStats({
    required this.teamSize,
    required this.openTasks,
    required this.activeDepartments,
  });
}

class DepartmentSummary {
  final local_team.TeamModel team;
  final String leadName;
  final local_team.DepartmentHealth health;

  DepartmentSummary(
      {required this.team,
      required this.leadName,
      this.health = local_team.DepartmentHealth.onTrack});
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String department;
  final double aiSpend;
  final int toolsUsed;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.aiSpend,
    required this.toolsUsed,
  });
}
