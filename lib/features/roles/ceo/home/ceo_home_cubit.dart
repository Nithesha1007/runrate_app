// ceo_home_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runrate/features/roles/ceo/shared/models/alert_model.dart';

// ---------------------------------------------------------------------------
// Shared row-tile action item (same shape as the Engineering Manager cubit's
// QuickActionItem — kept local here so this file has no cross-role import).
// ---------------------------------------------------------------------------
class CeoQuickActionItem {
  const CeoQuickActionItem({
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

class CeoKpiCardData {
  const CeoKpiCardData({
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

class CeoBudgetHealthData {
  const CeoBudgetHealthData({
    required this.budget,
    required this.used,
    required this.remaining,
    required this.utilization,
    required this.forecast,
    required this.expectedMonthEndSpend,
  });

  final double budget;
  final double used;
  final double remaining;
  final double utilization;
  final double forecast;
  final double expectedMonthEndSpend;
}

enum DepartmentTrend { up, down, flat }

enum StrategicImpact { costSaving, risk, growth }

typedef ExecutiveAlert = AlertModel;

class CompanySnapshotItem {
  const CompanySnapshotItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;
}

enum DecisionType { approved, rejected, delegated }

class RecentDecisionEntry {
  const RecentDecisionEntry({
    required this.title,
    required this.time,
    required this.type,
  });

  final String title;
  final DateTime time;
  final DecisionType type;
}

class HealthCategoryScore {
  const HealthCategoryScore({
    required this.label,
    required this.score,
  });

  final String label;
  final double score;
}

class TodaysFocusData {
  const TodaysFocusData({
    required this.highestRiskDepartment,
    required this.largestOpportunity,
    required this.biggestSavings,
    required this.mostActiveTool,
    required this.mostExpensiveTool,
  });

  final String highestRiskDepartment;
  final String largestOpportunity;
  final String biggestSavings;
  final String mostActiveTool;
  final String mostExpensiveTool;
}

class DepartmentSummary {
  const DepartmentSummary({
    required this.name,
    required this.headName,
    required this.spend,
    required this.budget,
    required this.adoptionRate,
    required this.topTool,
    required this.headcount,
    required this.trend,
  });

  final String name;
  final String headName;
  final double spend;
  final double budget;
  final double adoptionRate;
  final String topTool;
  final int headcount;
  final DepartmentTrend trend;

  double get utilization => budget == 0 ? 0 : (spend / budget).clamp(0, 1.4);
}

class StrategicInsightData {
  const StrategicInsightData({
    required this.title,
    required this.description,
    required this.impact,
    required this.icon,
    this.priority = 'Medium',
    this.timestampLabel = 'Today',
  });

  final String title;
  final String description;
  final StrategicImpact impact;
  final IconData icon;
  final String priority;
  final String timestampLabel;
}

class EscalatedApprovalData {
  const EscalatedApprovalData({
    required this.id,
    required this.department,
    required this.requestedBy,
    required this.tool,
    required this.monthlyCost,
    required this.reason,
    required this.priority,
    this.vendor = '',
    this.purpose = '',
    this.annualCost = 0,
    this.riskLevel = 'Medium',
  });

  final String id;
  final String department;
  final String requestedBy;
  final String tool;
  final double monthlyCost;
  final String reason;
  final String priority; // High / Medium / Low
  final String vendor;
  final String purpose;
  final double annualCost;
  final String riskLevel;
}

class CeoHomeData {
  const CeoHomeData({
    required this.ceoName,
    required this.companyName,
    required this.greeting,
    required this.todayLabel,
    required this.hasUnreadNotifications,
    required this.isOnline,
    required this.alerts,
    required this.snapshot,
    required this.quickActions,
    required this.kpis,
    required this.budgetHealth,
    required this.departments,
    required this.insights,
    required this.escalatedApprovals,
    required this.recentDecisions,
    required this.overallHealthScore,
    required this.healthCategories,
    required this.todaysFocus,
    required this.productivityGainPct,
    required this.totalSpend,
    required this.totalBudget,
    required this.remainingBudget,
    required this.budgetUtilization,
    required this.roiScore,
    required this.totalActiveUsers,
    required this.aiExecutiveSummary,
  });

  final String ceoName;
  final String companyName;
  final String greeting;
  final String todayLabel;
  final bool hasUnreadNotifications;
  final bool? isOnline;

  final List<ExecutiveAlert> alerts;
  final List<CompanySnapshotItem> snapshot;
  final List<CeoQuickActionItem> quickActions;
  final List<CeoKpiCardData> kpis;
  final CeoBudgetHealthData budgetHealth;
  final List<DepartmentSummary> departments;
  final List<StrategicInsightData> insights;
  final List<EscalatedApprovalData> escalatedApprovals;
  final List<RecentDecisionEntry> recentDecisions;
  final int overallHealthScore;
  final List<HealthCategoryScore> healthCategories;
  final TodaysFocusData todaysFocus;
  final double productivityGainPct;
  final double totalSpend;
  final double totalBudget;
  final double remainingBudget;
  final double budgetUtilization;
  final double roiScore;
  final int totalActiveUsers;
  final String aiExecutiveSummary;

  CeoHomeData copyWith({
    List<CeoKpiCardData>? kpis,
    List<EscalatedApprovalData>? escalatedApprovals,
  }) {
    return CeoHomeData(
      ceoName: ceoName,
      companyName: companyName,
      greeting: greeting,
      todayLabel: todayLabel,
      hasUnreadNotifications: hasUnreadNotifications,
      isOnline: isOnline,
      alerts: alerts,
      snapshot: snapshot,
      quickActions: quickActions,
      kpis: kpis ?? this.kpis,
      budgetHealth: budgetHealth,
      departments: departments,
      insights: insights,
      escalatedApprovals: escalatedApprovals ?? this.escalatedApprovals,
      recentDecisions: recentDecisions,
      overallHealthScore: overallHealthScore,
      healthCategories: healthCategories,
      todaysFocus: todaysFocus,
      productivityGainPct: productivityGainPct,
      totalSpend: totalSpend,
      totalBudget: totalBudget,
      remainingBudget: remainingBudget,
      budgetUtilization: budgetUtilization,
      roiScore: roiScore,
      totalActiveUsers: totalActiveUsers,
      aiExecutiveSummary: aiExecutiveSummary,
    );
  }
}

sealed class CeoHomeState {
  const CeoHomeState();
}

class CeoHomeInitial extends CeoHomeState {
  const CeoHomeInitial();
}

class CeoHomeLoading extends CeoHomeState {
  const CeoHomeLoading();
}

class CeoHomeLoaded extends CeoHomeState {
  const CeoHomeLoaded(this.data);

  final CeoHomeData data;
}

class CeoHomeError extends CeoHomeState {
  const CeoHomeError(this.message);

  final String message;
}

String _compactAmount(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

class CeoHomeCubit extends Cubit<CeoHomeState> {
  CeoHomeCubit() : super(const CeoHomeInitial());

  Future<void> loadDashboard() async {
    emit(const CeoHomeLoading());
    try {
      final data = await _fetchMockDashboard();
      emit(CeoHomeLoaded(data));
    } catch (e) {
      emit(CeoHomeError(e.toString()));
    }
  }

  Future<void> refresh() => loadDashboard();

  /// Optimistically removes [id] from the escalated-approvals list and
  /// updates the "Escalated Approvals" KPI count. Swap for a real API
  /// call + rollback-on-error once the approvals endpoint is wired up.
  Future<void> approveEscalation(String id) => _resolveEscalation(id);

  /// [reason] and [note] come from the reject-reason bottom sheet. Swap
  /// this for a real API call (POST the reason/note) once the approvals
  /// endpoint is wired up — for now we just log it and remove the card.
  Future<void> rejectEscalation(String id, {String? reason, String? note}) {
    debugPrint('Escalation $id rejected — reason: $reason, note: $note');
    return _resolveEscalation(id);
  }

  Future<void> delegateEscalation(String id, {required String delegateTo}) {
    debugPrint('Escalation $id delegated to $delegateTo');
    return _resolveEscalation(id);
  }

  Future<void> _resolveEscalation(String id) async {
    final current = state;
    if (current is! CeoHomeLoaded) return;

    final data = current.data;
    final updated = data.escalatedApprovals.where((r) => r.id != id).toList();

    final updatedKpis = data.kpis.map((kpi) {
      if (kpi.label != 'Escalated Approvals') return kpi;
      final urgent = updated.where((r) => r.priority == 'High').length;
      return CeoKpiCardData(
        label: kpi.label,
        value: '${updated.length}',
        subtitle: updated.isEmpty ? 'All clear' : '$urgent need urgent review',
        trend: kpi.trend,
        trendValue: kpi.trendValue,
        icon: kpi.icon,
      );
    }).toList();

    emit(CeoHomeLoaded(data.copyWith(
      escalatedApprovals: updated,
      kpis: updatedKpis,
    )));
  }

  Future<CeoHomeData> _fetchMockDashboard() async {
    await Future.delayed(const Duration(milliseconds: 700));

    const departments = [
      DepartmentSummary(
        name: 'Engineering',
        headName: 'Priya Nair',
        spend: 312000,
        budget: 380000,
        adoptionRate: 0.88,
        topTool: 'GitHub Copilot',
        headcount: 64,
        trend: DepartmentTrend.up,
      ),
      DepartmentSummary(
        name: 'Sales',
        headName: 'Marcus Webb',
        spend: 198500,
        budget: 220000,
        adoptionRate: 0.74,
        topTool: 'ChatGPT Enterprise',
        headcount: 48,
        trend: DepartmentTrend.up,
      ),
      DepartmentSummary(
        name: 'Marketing',
        headName: 'Sofia Chen',
        spend: 142300,
        budget: 150000,
        adoptionRate: 0.69,
        topTool: 'Claude',
        headcount: 22,
        trend: DepartmentTrend.flat,
      ),
      DepartmentSummary(
        name: 'Operations',
        headName: 'Daniel Osei',
        spend: 96800,
        budget: 160000,
        adoptionRate: 0.58,
        topTool: 'Gemini',
        headcount: 31,
        trend: DepartmentTrend.down,
      ),
      DepartmentSummary(
        name: 'Customer Success',
        headName: 'Grace Kim',
        spend: 62800,
        budget: 140000,
        adoptionRate: 0.63,
        topTool: 'ChatGPT Enterprise',
        headcount: 26,
        trend: DepartmentTrend.up,
      ),
    ];

    const escalatedApprovals = [
      EscalatedApprovalData(
        id: 'esc_eng_claude_team',
        department: 'Engineering',
        requestedBy: 'Priya Nair',
        tool: 'Claude Team (25 seats)',
        monthlyCost: 8200,
        reason: 'Exceeds department monthly approval threshold of \$5,000.',
        priority: 'High',
      ),
      EscalatedApprovalData(
        id: 'esc_sales_chatgpt',
        department: 'Sales',
        requestedBy: 'Marcus Webb',
        tool: 'ChatGPT Enterprise (add-on seats)',
        monthlyCost: 4600,
        reason: 'New vendor commitment requires executive sign-off.',
        priority: 'Medium',
      ),
      EscalatedApprovalData(
        id: 'esc_ops_gemini',
        department: 'Operations',
        requestedBy: 'Daniel Osei',
        tool: 'Gemini Advanced (bulk license)',
        monthlyCost: 2100,
        reason: 'Annual contract exceeds discretionary spend limit.',
        priority: 'Low',
      ),
    ];

    // ---- Every KPI below is derived from `departments` / `escalatedApprovals`
    // so the numbers on the dashboard always add up to the breakdown lists
    // instead of drifting out of sync with separately hardcoded values.
    final totalSpend = departments.fold<double>(0, (sum, d) => sum + d.spend);
    final totalBudget = departments.fold<double>(0, (sum, d) => sum + d.budget);
    final remainingBudget = totalBudget - totalSpend;
    final utilization = totalBudget == 0 ? 0.0 : totalSpend / totalBudget;
    final totalHeadcount =
        departments.fold<int>(0, (sum, d) => sum + d.headcount);
    final weightedAdoption = totalHeadcount == 0
        ? 0.0
        : departments.fold<double>(
                0, (sum, d) => sum + d.adoptionRate * d.headcount) /
            totalHeadcount;
    final urgentApprovals =
        escalatedApprovals.where((r) => r.priority == 'High').length;

    final kpis = [
      CeoKpiCardData(
        label: 'Total AI Spend',
        value: '\$${_compactAmount(totalSpend)}',
        subtitle: '${(utilization * 100).toInt()}% of budget',
        trend: '▲ 12%',
        trendValue: 12,
        icon: Icons.account_balance_wallet_rounded,
      ),
      CeoKpiCardData(
        label: 'Org-wide Adoption',
        value: '${(weightedAdoption * 100).toInt()}%',
        subtitle: '$totalHeadcount team members',
        trend: '▲ 6%',
        trendValue: 6,
        icon: Icons.groups_rounded,
      ),
      CeoKpiCardData(
        label: 'Active Departments',
        value: '${departments.length}',
        subtitle: 'All reporting in',
        trend: '▲ 0',
        trendValue: 0,
        icon: Icons.apartment_rounded,
      ),
      CeoKpiCardData(
        label: 'Escalated Approvals',
        value: '${escalatedApprovals.length}',
        subtitle: escalatedApprovals.isEmpty
            ? 'All clear'
            : '$urgentApprovals need urgent review',
        trend: escalatedApprovals.isEmpty ? '—' : '▼ 1',
        trendValue: escalatedApprovals.isEmpty ? 0 : -1,
        icon: Icons.pending_actions_rounded,
      ),
    ];

    return CeoHomeData(
      ceoName: 'Ananya Reddy',
      companyName: 'Northwind Labs',
      greeting: 'Good morning',
      todayLabel: DateFormat('EEE, dd MMM').format(DateTime.now()),
      hasUnreadNotifications: true,
      isOnline: true,
      alerts: const [
        ExecutiveAlert(
          id: 'al1',
          title: 'Budget exceeded — Marketing',
          description: 'Marketing is 14% over its monthly AI budget.',
          severity: AlertSeverity.critical,
          icon: Icons.warning_amber_rounded,
          actionLabel: 'Review',
        ),
        ExecutiveAlert(
          id: 'al2',
          title: '24 unused licenses detected',
          description:
              'GitHub Copilot seats in Engineering unused for 30+ days.',
          severity: AlertSeverity.warning,
          icon: Icons.person_off_outlined,
          actionLabel: 'Reassign',
        ),
      ],
      snapshot: [
        CompanySnapshotItem(
          icon: Icons.group_rounded,
          value: '${departments.length}',
          label: 'Departments',
        ),
        CompanySnapshotItem(
          icon: Icons.people_alt_rounded,
          value: '${totalHeadcount}',
          label: 'Active users',
        ),
        CompanySnapshotItem(
          icon: Icons.trending_up_rounded,
          value: '${(utilization * 100).toInt()}%',
          label: 'Budget used',
        ),
      ],
      totalSpend: totalSpend,
      totalBudget: totalBudget,
      remainingBudget: remainingBudget,
      budgetUtilization: utilization,
      roiScore: 87,
      totalActiveUsers: totalHeadcount,
      quickActions: const [
        CeoQuickActionItem(
          title: 'Ask AI',
          subtitle: 'Strategic copilot',
          icon: Icons.auto_awesome_rounded,
          routeTag: 'ask_ai',
        ),
        CeoQuickActionItem(
          title: 'Company Report',
          subtitle: 'Full spend rollup',
          icon: Icons.summarize_rounded,
          routeTag: 'company_report',
        ),
        CeoQuickActionItem(
          title: 'Budget Forecast',
          subtitle: 'Next quarter outlook',
          icon: Icons.trending_up_rounded,
          routeTag: 'budget_forecast',
        ),
        CeoQuickActionItem(
          title: 'Compare Departments',
          subtitle: 'Spend vs adoption',
          icon: Icons.stacked_bar_chart_rounded,
          routeTag: 'compare_departments',
        ),
      ],
      kpis: kpis,
      budgetHealth: CeoBudgetHealthData(
        budget: totalBudget,
        used: totalSpend,
        remaining: remainingBudget,
        utilization: utilization,
        forecast: 0.86,
        expectedMonthEndSpend: 512000,
      ),
      departments: departments,
      insights: const [
        StrategicInsightData(
          title: 'Consolidation opportunity',
          description:
              'Three departments run overlapping AI writing tools. Standardizing on one could save roughly \$18K per month.',
          impact: StrategicImpact.costSaving,
          icon: Icons.savings_rounded,
        ),
        StrategicInsightData(
          title: 'Operations adoption lagging',
          description:
              'Operations adoption dropped to 58% this month, the lowest across the company. Licenses are going unused.',
          impact: StrategicImpact.risk,
          icon: Icons.warning_amber_rounded,
        ),
        StrategicInsightData(
          title: 'Sales productivity climbing',
          description:
              'Sales AI adoption rose 14 points this quarter alongside a measurable lift in deal velocity.',
          impact: StrategicImpact.growth,
          icon: Icons.rocket_launch_rounded,
        ),
      ],
      escalatedApprovals: escalatedApprovals,
      recentDecisions: [
        RecentDecisionEntry(
          title: 'Approved Claude Team expansion',
          time: DateTime.now().subtract(const Duration(hours: 2)),
          type: DecisionType.approved,
        ),
        RecentDecisionEntry(
          title: 'Rejected new Jasper contract',
          time: DateTime.now().subtract(const Duration(hours: 5)),
          type: DecisionType.rejected,
        ),
        RecentDecisionEntry(
          title: 'Delegated Datadog renewal review',
          time: DateTime.now().subtract(const Duration(hours: 18)),
          type: DecisionType.delegated,
        ),
      ],
      overallHealthScore: 86,
      healthCategories: const [
        HealthCategoryScore(label: 'Adoption', score: 0.82),
        HealthCategoryScore(label: 'Spend', score: 0.78),
        HealthCategoryScore(label: 'Compliance', score: 0.92),
      ],
      todaysFocus: const TodaysFocusData(
        highestRiskDepartment: 'Operations',
        largestOpportunity: 'Sales enablement AI',
        biggestSavings: 'Unused Copilot seats',
        mostActiveTool: 'ChatGPT Enterprise',
        mostExpensiveTool: 'Claude Enterprise',
      ),
      productivityGainPct: 0.14,
      aiExecutiveSummary:
          'Company-wide AI spend is on track at ${(utilization * 100).toInt()}% of budget with adoption up across most teams. Engineering and Sales are leading growth, while Operations needs attention after a drop in adoption. ${escalatedApprovals.length} requests are waiting on your sign-off, and consolidating overlapping tools could free up meaningful budget.',
    );
  }
}
