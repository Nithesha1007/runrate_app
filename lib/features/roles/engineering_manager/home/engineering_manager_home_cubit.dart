import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class QuickActionItem {
  const QuickActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeTag,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String routeTag;
}

class KpiCardData {
  const KpiCardData({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.trend,
    required this.trendValue,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final String trend;
  final double trendValue;
  final IconData icon;
}

class BudgetHealthData {
  const BudgetHealthData({
    required this.budget,
    required this.used,
    required this.remaining,
    required this.utilization,
    required this.forecast,
  });

  final double budget;
  final double used;
  final double remaining;
  final double utilization;
  final double forecast;
}

class TeamMemberData {
  const TeamMemberData({
    required this.name,
    required this.role,
    required this.initials,
    required this.toolUsedMost,
    required this.monthlySpend,
    required this.productivityScore,
    required this.adoptionRate,
    required this.activeLicenses,
    required this.status,
  });

  final String name;
  final String role;
  final String initials;
  final String toolUsedMost;
  final double monthlySpend;
  final int productivityScore;
  final int adoptionRate;
  final int activeLicenses;
  final TeamMemberStatus status;
}

enum TeamMemberStatus { excellent, good, needsAttention, inactive }

class ToolUsageData {
  const ToolUsageData({
    required this.name,
    required this.activeUsers,
    required this.monthlyCost,
    required this.licenseUsage,
    required this.renewalDate,
    required this.utilization,
  });

  final String name;
  final int activeUsers;
  final double monthlyCost;
  final int licenseUsage;
  final String renewalDate;
  final double utilization;
}

class InsightData {
  const InsightData({
    required this.title,
    required this.description,
    required this.priority,
    required this.icon,
  });

  final String title;
  final String description;
  final String priority;
  final IconData icon;
}

class PendingRequestData {
  const PendingRequestData({
    required this.id,
    required this.employeeName,
    required this.requestedTool,
    required this.justification,
    required this.monthlyCost,
    required this.priority,
    required this.requestDate,
  });

  final String id;
  final String employeeName;
  final String requestedTool;
  final String justification;
  final double monthlyCost;
  final String priority;
  final String requestDate;
}

class ActivityItem {
  const ActivityItem({
    required this.time,
    required this.user,
    required this.activity,
    required this.status,
  });

  final String time;
  final String user;
  final String activity;
  final String status;
}

class SummaryCardData {
  const SummaryCardData({
    required this.label,
    required this.value,
    required this.caption,
  });

  final String label;
  final String value;
  final String caption;
}

class EngineeringManagerHomeData {
  const EngineeringManagerHomeData({
    required this.managerName,
    required this.teamName,
    required this.greeting,
    required this.todayLabel,
    required this.hasUnreadNotifications,
    required this.pendingApprovals,
    required this.budgetUtilization,
    required this.currentSpend,
    required this.budget,
    required this.remainingBudget,
    required this.productivityScore,
    required this.adoptionRate,
    required this.activeUsers,
    required this.activeLicenses,
    required this.quickActions,
    required this.kpis,
    required this.budgetHealth,
    required this.teamMembers,
    required this.toolUsage,
    required this.insights,
    required this.pendingRequests,
    required this.recentActivity,
    required this.productivitySummary,
    required this.aiManagerSummary,
  });

  final String managerName;
  final String teamName;
  final String greeting;
  final String todayLabel;
  final bool hasUnreadNotifications;
  final int pendingApprovals;

  final double budgetUtilization;
  final double currentSpend;
  final double budget;
  final double remainingBudget;
  final double productivityScore;
  final double adoptionRate;
  final int activeUsers;
  final int activeLicenses;

  final List<QuickActionItem> quickActions;
  final List<KpiCardData> kpis;
  final BudgetHealthData budgetHealth;
  final List<TeamMemberData> teamMembers;
  final List<ToolUsageData> toolUsage;
  final List<InsightData> insights;
  final List<PendingRequestData> pendingRequests;
  final List<ActivityItem> recentActivity;
  final List<SummaryCardData> productivitySummary;
  final String aiManagerSummary;

  EngineeringManagerHomeData copyWith({
    int? pendingApprovals,
    List<KpiCardData>? kpis,
    List<PendingRequestData>? pendingRequests,
  }) {
    return EngineeringManagerHomeData(
      managerName: managerName,
      teamName: teamName,
      greeting: greeting,
      todayLabel: todayLabel,
      hasUnreadNotifications: hasUnreadNotifications,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      budgetUtilization: budgetUtilization,
      currentSpend: currentSpend,
      budget: budget,
      remainingBudget: remainingBudget,
      productivityScore: productivityScore,
      adoptionRate: adoptionRate,
      activeUsers: activeUsers,
      activeLicenses: activeLicenses,
      quickActions: quickActions,
      kpis: kpis ?? this.kpis,
      budgetHealth: budgetHealth,
      teamMembers: teamMembers,
      toolUsage: toolUsage,
      insights: insights,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      recentActivity: recentActivity,
      productivitySummary: productivitySummary,
      aiManagerSummary: aiManagerSummary,
    );
  }
}

sealed class EngineeringManagerHomeState {
  const EngineeringManagerHomeState();
}

class EngineeringManagerHomeInitial extends EngineeringManagerHomeState {
  const EngineeringManagerHomeInitial();
}

class EngineeringManagerHomeLoading extends EngineeringManagerHomeState {
  const EngineeringManagerHomeLoading();
}

class EngineeringManagerHomeLoaded extends EngineeringManagerHomeState {
  const EngineeringManagerHomeLoaded(this.data);

  final EngineeringManagerHomeData data;
}

class EngineeringManagerHomeError extends EngineeringManagerHomeState {
  const EngineeringManagerHomeError(this.message);

  final String message;
}

class EngineeringManagerHomeCubit extends Cubit<EngineeringManagerHomeState> {
  EngineeringManagerHomeCubit() : super(const EngineeringManagerHomeInitial());

  Future<void> loadDashboard() async {
    emit(const EngineeringManagerHomeLoading());
    try {
      final data = await _fetchMockDashboard();
      emit(EngineeringManagerHomeLoaded(data));
    } catch (e) {
      emit(EngineeringManagerHomeError(e.toString()));
    }
  }

  Future<void> refresh() => loadDashboard();

  /// Optimistically removes [requestId] from the pending list and
  /// decrements the pending-approvals count. Swap the body for a real
  /// API call + error rollback once the approvals endpoint is wired up.
  Future<void> approveRequest(String requestId) => _resolveRequest(requestId);

  Future<void> rejectRequest(String requestId) => _resolveRequest(requestId);

  Future<void> _resolveRequest(String requestId) async {
    final current = state;
    if (current is! EngineeringManagerHomeLoaded) return;

    final data = current.data;
    final updatedRequests =
        data.pendingRequests.where((r) => r.id != requestId).toList();

    final updatedKpis = data.kpis.map((kpi) {
      if (kpi.label != 'Pending Approvals') return kpi;
      final remaining = updatedRequests.length;
      return KpiCardData(
        label: kpi.label,
        value: '$remaining',
        subtitle: kpi.subtitle,
        trend: kpi.trend,
        trendValue: kpi.trendValue,
        icon: kpi.icon,
      );
    }).toList();

    emit(EngineeringManagerHomeLoaded(data.copyWith(
      pendingRequests: updatedRequests,
      pendingApprovals: updatedRequests.length,
      kpis: updatedKpis,
    )));
  }

  Future<EngineeringManagerHomeData> _fetchMockDashboard() async {
    await Future.delayed(const Duration(milliseconds: 700));

    return EngineeringManagerHomeData(
      managerName: 'Priya Nair',
      teamName: 'Platform Runtime',
      greeting: 'Good morning',
      todayLabel: DateFormat('EEE, dd MMM').format(DateTime.now()),
      hasUnreadNotifications: true,
      pendingApprovals: 3,
      budgetUtilization: 0.73,
      currentSpend: 183250,
      budget: 250000,
      remainingBudget: 66800,
      productivityScore: 92,
      adoptionRate: 0.88,
      activeUsers: 24,
      activeLicenses: 28,
      quickActions: const [
        QuickActionItem(
          title: 'Ask AI',
          subtitle: 'Talk to your copilot',
          icon: Icons.auto_awesome_rounded,
          routeTag: 'recommendations',
        ),
        QuickActionItem(
          title: 'Team Report',
          subtitle: 'Delivery & adoption',
          icon: Icons.bar_chart_rounded,
          routeTag: 'analytics',
        ),
        QuickActionItem(
          title: 'Budget Details',
          subtitle: 'Spend and forecast',
          icon: Icons.account_balance_wallet_rounded,
          routeTag: 'budget',
        ),
        QuickActionItem(
          title: 'Compare AI Usage',
          subtitle: 'Benchmark the team',
          icon: Icons.groups_rounded,
          routeTag: 'members',
        ),
      ],
      // Home screen shows only these four KPIs per the compact spec.
      // Adoption %, cost, productivity, and issues live in the Hero card
      // or other tabs — kept out of this list to avoid duplication.
      kpis: const [
        KpiCardData(
          label: 'Team Members',
          value: '18',
          subtitle: '2 new this month',
          trend: '▲ 11%',
          trendValue: 11,
          icon: Icons.people_alt_rounded,
        ),
        KpiCardData(
          label: 'Active AI Users',
          value: '24',
          subtitle: '84% of engineers',
          trend: '▲ 8%',
          trendValue: 8,
          icon: Icons.smart_toy_rounded,
        ),
        KpiCardData(
          label: 'Active AI Tools',
          value: '5',
          subtitle: 'Balanced mix',
          trend: '▲ 2',
          trendValue: 2,
          icon: Icons.widgets_rounded,
        ),
        KpiCardData(
          label: 'Pending Approvals',
          value: '3',
          subtitle: '1 urgent review',
          trend: '▼ 2%',
          trendValue: -2,
          icon: Icons.pending_actions_rounded,
        ),
      ],
      budgetHealth: const BudgetHealthData(
        budget: 250000,
        used: 183250,
        remaining: 66800,
        utilization: 0.73,
        forecast: 0.81,
      ),
      // Not rendered on Home anymore — Teams tab owns the full roster.
      // Left populated here in case the cubit is reused elsewhere.
      teamMembers: const [
        TeamMemberData(
          name: 'Arjun K.',
          role: 'Staff Engineer',
          initials: 'AK',
          toolUsedMost: 'GitHub Copilot',
          monthlySpend: 880,
          productivityScore: 96,
          adoptionRate: 95,
          activeLicenses: 2,
          status: TeamMemberStatus.excellent,
        ),
        TeamMemberData(
          name: 'Sara M.',
          role: 'Platform Lead',
          initials: 'SM',
          toolUsedMost: 'Claude',
          monthlySpend: 720,
          productivityScore: 88,
          adoptionRate: 79,
          activeLicenses: 1,
          status: TeamMemberStatus.good,
        ),
        TeamMemberData(
          name: 'Rohan V.',
          role: 'Frontend Engineer',
          initials: 'RV',
          toolUsedMost: 'Cursor',
          monthlySpend: 610,
          productivityScore: 76,
          adoptionRate: 63,
          activeLicenses: 1,
          status: TeamMemberStatus.needsAttention,
        ),
        TeamMemberData(
          name: 'Neha P.',
          role: 'DevOps Engineer',
          initials: 'NP',
          toolUsedMost: 'ChatGPT',
          monthlySpend: 430,
          productivityScore: 82,
          adoptionRate: 71,
          activeLicenses: 2,
          status: TeamMemberStatus.inactive,
        ),
      ],
      toolUsage: const [
        ToolUsageData(
          name: 'ChatGPT Enterprise',
          activeUsers: 17,
          monthlyCost: 6200,
          licenseUsage: 68,
          renewalDate: '12 Sep',
          utilization: 0.68,
        ),
        ToolUsageData(
          name: 'Claude',
          activeUsers: 10,
          monthlyCost: 4800,
          licenseUsage: 55,
          renewalDate: '06 Sep',
          utilization: 0.55,
        ),
        ToolUsageData(
          name: 'GitHub Copilot',
          activeUsers: 16,
          monthlyCost: 5400,
          licenseUsage: 88,
          renewalDate: '18 Sep',
          utilization: 0.88,
        ),
        ToolUsageData(
          name: 'Cursor',
          activeUsers: 7,
          monthlyCost: 2900,
          licenseUsage: 41,
          renewalDate: '22 Sep',
          utilization: 0.41,
        ),
        ToolUsageData(
          name: 'Gemini',
          activeUsers: 9,
          monthlyCost: 2400,
          licenseUsage: 63,
          renewalDate: '30 Sep',
          utilization: 0.63,
        ),
      ],
      // Not rendered on Home anymore — lives in the AI tab's insights feed.
      insights: const [
        InsightData(
          title: 'Productivity lift',
          description: 'Engineering AI productivity increased by 15% this month.',
          priority: 'High',
          icon: Icons.trending_up_rounded,
        ),
        InsightData(
          title: 'License gap',
          description: 'Three developers are not using assigned AI licenses.',
          priority: 'Medium',
          icon: Icons.warning_amber_rounded,
        ),
        InsightData(
          title: 'Adoption pulse',
          description: 'GitHub Copilot usage increased this week across the team.',
          priority: 'Low',
          icon: Icons.auto_awesome_rounded,
        ),
      ],
      pendingRequests: const [
        PendingRequestData(
          id: 'req_lina_d',
          employeeName: 'Lina D.',
          requestedTool: 'Claude Pro',
          justification: 'Need deeper code review support for architecture sprints.',
          monthlyCost: 1200,
          priority: 'High',
          requestDate: '02 Aug',
        ),
        PendingRequestData(
          id: 'req_jamil_s',
          employeeName: 'Jamil S.',
          requestedTool: 'Cursor Pro',
          justification: 'Pair-programming workflow for rapid prototype iteration.',
          monthlyCost: 950,
          priority: 'Medium',
          requestDate: '01 Aug',
        ),
        PendingRequestData(
          id: 'req_maya_r',
          employeeName: 'Maya R.',
          requestedTool: 'Gemini Advanced',
          justification: 'Need multilingual support and research automation.',
          monthlyCost: 760,
          priority: 'Low',
          requestDate: '31 Jul',
        ),
      ],
      // Not rendered on Home anymore — lives in an activity/reports tab.
      recentActivity: const [
        ActivityItem(
          time: '09:12',
          user: 'Lina D.',
          activity: 'Requested GitHub Copilot',
          status: 'Pending',
        ),
        ActivityItem(
          time: '08:41',
          user: 'Ops Team',
          activity: 'Claude subscription approved',
          status: 'Approved',
        ),
        ActivityItem(
          time: '07:20',
          user: 'Nikhil',
          activity: 'New engineer joined the team',
          status: 'Updated',
        ),
      ],
      // Not rendered on Home anymore — lives in Team Report / Teams tab.
      productivitySummary: const [
        SummaryCardData(
          label: 'Tasks accelerated using AI',
          value: '142',
          caption: 'Across 8 squads',
        ),
        SummaryCardData(
          label: 'Hours saved',
          value: '320h',
          caption: 'This quarter',
        ),
        SummaryCardData(
          label: 'AI productivity improvement',
          value: '+18%',
          caption: 'Versus last month',
        ),
        SummaryCardData(
          label: 'Top performing developer',
          value: 'Arjun K.',
          caption: '96 productivity score',
        ),
      ],
      aiManagerSummary:
          'Engineering team is operating within budget. GitHub Copilot has the highest adoption rate, while three Claude licenses remain unused. Team productivity improved by 18% this month, and two AI tool requests require your approval.',
    );
  }
}