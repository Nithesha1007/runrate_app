import 'package:flutter/material.dart';
import 'package:runrate/features/roles/ceo/shared/models/activity_model.dart';
import 'package:runrate/features/roles/ceo/shared/models/ai_tool_model.dart';
import 'package:runrate/features/roles/ceo/shared/models/approval_model.dart';
import 'package:runrate/features/roles/ceo/shared/models/alert_model.dart';
import 'package:runrate/features/roles/ceo/shared/models/team_model.dart';
import 'package:runrate/features/roles/ceo/shared/models/home_models.dart';
// removed shared team model import; using CEO-local models instead

// local home models used by the CEO mock repository
import '../../../../shared/models/insight_model.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/report_model.dart';

import '../../../../shared/widgets/simple_bar_chart.dart';

/// All mock data + simulated network delay for the CEO role lives here,
/// separate from the Cubits, so it can later be swapped for a real API
/// client without touching any UI or state-management code.
class CeoMockRepository {
  // ---------------------------------------------------------------------
  // Existing (kept, some fields now also feed the hero card).
  // ---------------------------------------------------------------------
  Future<Map<String, double>> fetchKpis() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'AI Adoption Rate': 78,
      'Active AI Users': 214,
      'Active AI Licenses': 260,
      'AI Tools Connected': 12,
      'Departments': 6,
      'Pending Approvals': 3,
      'Monthly AI Cost': 68900,
      'Cost Saved': 32000,
    };
  }

  /// Top-level figures for the hero card.
  Future<Map<String, double>> fetchHeroSummary() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'totalSpend': 482300,
      'monthlyBudget': 650000,
      'remainingBudget': 167700,
      'aiRoi': 3.4,
      'costSavings': 32000,
      'forecastSpend': 512000,
      'trendPercent': 9.0,
    };
  }

  /// Executive "company health" stat cards for Home: Revenue, Growth %,
  /// Burn Rate, Runway — each with a trend so the UI can draw an arrow.
  Future<List<CompanyHealthStat>> fetchCompanyHealth() async {
    await Future.delayed(const Duration(milliseconds: 450));
    return [
      CompanyHealthStat(
        label: 'Revenue',
        value: 1284000,
        format: HealthStatFormat.currency,
        trendPercent: 8.4,
        trendIsGood: true,
      ),
      CompanyHealthStat(
        label: 'Growth',
        value: 12.6,
        format: HealthStatFormat.percent,
        trendPercent: 2.1,
        trendIsGood: true,
      ),
      CompanyHealthStat(
        label: 'Burn Rate',
        value: 68900,
        format: HealthStatFormat.currency,
        trendPercent: 5.3,
        trendIsGood: false,
      ),
      CompanyHealthStat(
        label: 'Runway',
        value: 14,
        format: HealthStatFormat.months,
        trendPercent: -1.2,
        trendIsGood: false,
      ),
    ];
  }

  /// Revenue trend over the last 6 months, for the Home trend chart.
  Future<List<BarChartPoint>> fetchRevenueTrend() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      BarChartPoint(label: 'Mar', value: 968000),
      BarChartPoint(label: 'Apr', value: 1021000),
      BarChartPoint(label: 'May', value: 1105000),
      BarChartPoint(label: 'Jun', value: 1149000),
      BarChartPoint(label: 'Jul', value: 1198000),
      BarChartPoint(label: 'Aug', value: 1284000),
    ];
  }

  /// Today's key meetings for the Home screen.
  Future<List<MeetingModel>> fetchTodayMeetings() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return [
      MeetingModel(
        id: 'm1',
        title: 'Board Sync — Q3 Outlook',
        time: '10:00 AM',
        attendees: ['Priya Shah', 'Dana Cole', 'Sam Rivera'],
      ),
      MeetingModel(
        id: 'm2',
        title: '1:1 with CFO',
        time: '1:30 PM',
        attendees: ['Priya Shah'],
      ),
      MeetingModel(
        id: 'm3',
        title: 'Vendor Renewal Review',
        time: '4:00 PM',
        attendees: ['Sam Rivera', 'Legal'],
      ),
    ];
  }

  /// Team size / open tasks / active departments for the Home quick-stats row.
  Future<QuickStats> fetchQuickStats() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const QuickStats(teamSize: 113, openTasks: 27, activeDepartments: 6);
  }

  Future<List<DepartmentSummary>> fetchDepartmentSummaries() async {
    final departments = await fetchDepartments();
    const leads = {
      'Engineering': 'Sam Rivera',
      'Sales': 'Priya Shah',
      'Marketing': 'Dana Cole',
      'Support': 'Marcus Wei',
      'HR': 'Elena Torres',
      'Operations': 'Jonah Blake',
    };
    return departments
        .map((t) => DepartmentSummary(
            team: t, leadName: leads[t.name] ?? 'Unassigned', health: t.health))
        .toList();
  }

  Future<List<BarChartPoint>> fetchDeptSpendChart() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      BarChartPoint(label: 'Eng', value: 182000),
      BarChartPoint(label: 'Sales', value: 96000),
      BarChartPoint(label: 'Mktg', value: 74000),
      BarChartPoint(label: 'Supp', value: 41000),
      BarChartPoint(label: 'HR', value: 28000),
      BarChartPoint(label: 'Ops', value: 61300),
    ];
  }

  /// Roster for a given department name, for the department drill-down.
  Future<List<TeamMember>> fetchDepartmentMembers(String departmentName) async {
    await Future.delayed(const Duration(milliseconds: 450));
    final rosters = <String, List<List<String>>>{
      'Engineering': [
        ['Sam Rivera', 'Engineering Manager'],
        ['Alex Chen', 'Staff Engineer'],
        ['Priya Nair', 'Backend Engineer'],
        ['Jordan Wells', 'Frontend Engineer'],
        ['Casey Kim', 'DevOps Engineer'],
      ],
      'Sales': [
        ['Priya Shah', 'VP Sales'],
        ['Marco Diaz', 'Account Executive'],
        ['Nina Osei', 'Sales Development Rep'],
      ],
      'Marketing': [
        ['Dana Cole', 'Marketing Lead'],
        ['Liam Foster', 'Content Strategist'],
        ['Ravi Kapoor', 'Growth Marketer'],
      ],
      'Support': [
        ['Marcus Wei', 'Support Lead'],
        ['Grace Lin', 'Support Engineer'],
        ['Omar Haddad', 'Support Engineer'],
      ],
      'HR': [
        ['Elena Torres', 'HR Director'],
        ['Fatima Malik', 'People Ops'],
      ],
      'Operations': [
        ['Jonah Blake', 'Ops Manager'],
        ['Tessa Brooks', 'Operations Analyst'],
      ],
    };
    final roster = rosters[departmentName] ?? const [];
    return [
      for (var i = 0; i < roster.length; i++)
        TeamMember(
          id: '$departmentName-$i',
          name: roster[i][0],
          role: roster[i][1],
          department: departmentName,
        ),
    ];
  }

  Future<List<InsightModel>> fetchInsights() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      InsightModel(
        id: 'i1',
        title: 'Engineering spend up 14% MoM',
        description:
            'Driven mostly by new cloud infrastructure vendors added in the last 3 weeks.',
        severity: InsightSeverity.warning,
      ),
      InsightModel(
        id: 'i2',
        title: 'On pace to save \$32K this quarter',
        description:
            'Consolidating overlapping SaaS tools across Sales and Marketing is ahead of schedule.',
        severity: InsightSeverity.positive,
      ),
      InsightModel(
        id: 'i3',
        title: '3 vendor contracts renew next month',
        description:
            'Zoom, Notion, and Datadog renewals total \$18,400/mo — worth a renegotiation pass.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  /// Single-line daily AI briefing shown at the top of the AI Copilot tab.
  Future<String> fetchDailyBriefing() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return 'Burn rate is up 12% this month, driven by Engineering infra spend — '
        'runway dropped from 15.2 to 14 months.';
  }

  /// Loads a past AI conversation from the sidebar.
  Future<List<ChatMessageModel>> fetchSessionMessages(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 700));
    return [
      ChatMessageModel(
        id: '${sessionId}_1',
        text:
            'Here is the background for "$sessionId" — I pulled together a quick summary of the key points.',
        fromUser: false,
        sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
      ),
      ChatMessageModel(
        id: '${sessionId}_2',
        text:
            'Can you help me analyze the associated spend, risks, and savings opportunities?',
        fromUser: true,
        sentAt: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  /// AI Recommendations feed (Home + AI tab quick insights).
  Future<List<InsightModel>> fetchRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      InsightModel(
        id: 'r1',
        title: '24 unused Copilot licenses in Engineering',
        description: 'Reassign or downgrade to save an estimated \$1,440/mo.',
        severity: InsightSeverity.warning,
      ),
      InsightModel(
        id: 'r2',
        title: 'Marketing exceeded AI budget by 14%',
        description: 'Mostly driven by an unplanned Jasper AI seat expansion.',
        severity: InsightSeverity.warning,
      ),
      InsightModel(
        id: 'r3',
        title: 'Claude Enterprise renewal due in 5 days',
        description: 'Renews at \$14,200/mo unless cancelled or renegotiated.',
        severity: InsightSeverity.info,
      ),
      InsightModel(
        id: 'r4',
        title: 'Finance could reduce AI spend by 18%',
        description:
            'Overlapping analytics copilots detected across two vendors.',
        severity: InsightSeverity.positive,
      ),
    ];
  }

  Future<List<AlertModel>> fetchAlerts() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      AlertModel(
        id: 'al1',
        title: 'Budget exceeded — Marketing',
        description: 'Marketing is 14% over its monthly AI budget.',
        severity: AlertSeverity.critical,
        icon: Icons.warning_amber_rounded,
        actionLabel: 'Review',
      ),
      AlertModel(
        id: 'al2',
        title: '24 unused licenses detected',
        description: 'GitHub Copilot seats in Engineering unused for 30+ days.',
        severity: AlertSeverity.warning,
        icon: Icons.person_off_outlined,
        actionLabel: 'Reassign',
      ),
      AlertModel(
        id: 'al3',
        title: 'Subscription expiring — Claude Enterprise',
        description: 'Renews in 5 days at \$14,200/mo.',
        severity: AlertSeverity.warning,
        icon: Icons.event_busy_outlined,
        actionLabel: 'Review',
      ),
      AlertModel(
        id: 'al4',
        title: 'Critical approval waiting',
        description: 'Annual Salesforce renewal has been pending 3+ hours.',
        severity: AlertSeverity.critical,
        icon: Icons.pending_actions_outlined,
        actionLabel: 'Approve',
      ),
    ];
  }

  Future<List<ActivityModel>> fetchActivity() async {
    await Future.delayed(const Duration(milliseconds: 350));
    final now = DateTime.now();
    return [
      ActivityModel(
        id: 'act1',
        text: 'Sam Rivera requested ChatGPT Enterprise access',
        occurredAt: now.subtract(const Duration(hours: 1)),
        kind: ActivityKind.request,
        icon: Icons.person_add_alt_1,
      ),
      ActivityModel(
        id: 'act2',
        text: 'Priya Shah (CFO) approved Claude renewal',
        occurredAt: now.subtract(const Duration(hours: 4)),
        kind: ActivityKind.approval,
        icon: Icons.check_circle_outline,
      ),
      ActivityModel(
        id: 'act3',
        text: 'Engineering exceeded its monthly AI budget',
        occurredAt: now.subtract(const Duration(hours: 7)),
        kind: ActivityKind.alert,
        icon: Icons.warning_amber_rounded,
      ),
      ActivityModel(
        id: 'act4',
        text: 'Admin invited 3 new users to the workspace',
        occurredAt: now.subtract(const Duration(days: 1)),
        kind: ActivityKind.admin,
        icon: Icons.group_add_outlined,
      ),
    ];
  }

  Future<String> fetchExecutiveSummary() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'This month AI spending is tracking 6% under the board-approved budget. '
        'Engineering has the highest ROI at 4.1x while Marketing exceeded its budget by 14%. '
        'Three subscriptions — Claude, Zoom, and Datadog — require renewal decisions this week.';
  }

  Future<List<AiToolModel>> fetchTopTools() async {
    await Future.delayed(const Duration(milliseconds: 450));
    final now = DateTime.now();
    return [
      AiToolModel(
        id: 't1',
        name: 'ChatGPT Enterprise',
        users: 142,
        licenses: 160,
        monthlyCost: 21400,
        renewalDate: now.add(const Duration(days: 42)),
        status: ToolStatus.active,
        licenseUsagePercent: 89,
      ),
      AiToolModel(
        id: 't2',
        name: 'Claude',
        users: 68,
        licenses: 80,
        monthlyCost: 14200,
        renewalDate: now.add(const Duration(days: 5)),
        status: ToolStatus.renewalDue,
        licenseUsagePercent: 85,
      ),
      AiToolModel(
        id: 't3',
        name: 'Gemini',
        users: 34,
        licenses: 50,
        monthlyCost: 6800,
        renewalDate: now.add(const Duration(days: 61)),
        status: ToolStatus.active,
        licenseUsagePercent: 68,
      ),
      AiToolModel(
        id: 't4',
        name: 'GitHub Copilot',
        users: 96,
        licenses: 120,
        monthlyCost: 9600,
        renewalDate: now.add(const Duration(days: 88)),
        status: ToolStatus.underReview,
        licenseUsagePercent: 80,
      ),
      AiToolModel(
        id: 't5',
        name: 'Cursor',
        users: 41,
        licenses: 45,
        monthlyCost: 4500,
        renewalDate: now.add(const Duration(days: 30)),
        status: ToolStatus.active,
        licenseUsagePercent: 91,
      ),
    ];
  }

  Future<List<TeamModel>> fetchDepartments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      TeamModel(
        name: 'Engineering',
        spend: 182000,
        trendPercent: 14,
        memberCount: 38,
        departmentHead: 'Sam Rivera',
        monthlyBudget: 200000,
        aiAdoption: 91,
        aiRoi: 4.1,
        productivityScore: 88,
        activeAiTools: 6,
        topAiTool: 'GitHub Copilot',
        health: DepartmentHealth.atRisk,
        monthlyTrend: const [140000, 151000, 160000, 168000, 175000, 182000],
        members: const [
          DepartmentMember(
              name: 'Sam Rivera',
              role: 'Eng Manager',
              aiSpend: 4200,
              toolsUsed: 5),
          DepartmentMember(
              name: 'Alex Chen',
              role: 'Senior Engineer',
              aiSpend: 3100,
              toolsUsed: 4),
          DepartmentMember(
              name: 'Priya Nair',
              role: 'Engineer',
              aiSpend: 2600,
              toolsUsed: 3),
        ],
      ),
      TeamModel(
        name: 'Sales',
        spend: 96000,
        trendPercent: -4,
        memberCount: 22,
        departmentHead: 'Marcus Webb',
        monthlyBudget: 110000,
        aiAdoption: 74,
        aiRoi: 2.6,
        productivityScore: 79,
        activeAiTools: 4,
        topAiTool: 'ChatGPT Enterprise',
        health: DepartmentHealth.onTrack,
        monthlyTrend: const [102000, 99000, 98500, 97000, 96500, 96000],
        members: const [
          DepartmentMember(
              name: 'Marcus Webb',
              role: 'Sales Director',
              aiSpend: 2800,
              toolsUsed: 3),
          DepartmentMember(
              name: 'Lena Ortiz', role: 'AE', aiSpend: 1900, toolsUsed: 2),
        ],
      ),
      TeamModel(
        name: 'Marketing',
        spend: 74000,
        trendPercent: 6,
        memberCount: 14,
        departmentHead: 'Dana Cole',
        monthlyBudget: 65000,
        aiAdoption: 82,
        aiRoi: 2.1,
        productivityScore: 71,
        activeAiTools: 5,
        topAiTool: 'Jasper AI',
        health: DepartmentHealth.critical,
        monthlyTrend: const [58000, 61000, 65000, 69000, 71000, 74000],
        members: const [
          DepartmentMember(
              name: 'Dana Cole',
              role: 'Marketing Lead',
              aiSpend: 3400,
              toolsUsed: 4),
          DepartmentMember(
              name: 'Rhea Patel',
              role: 'Content Strategist',
              aiSpend: 2100,
              toolsUsed: 3),
        ],
      ),
      TeamModel(
        name: 'Support',
        spend: 41000,
        trendPercent: -2,
        memberCount: 19,
        departmentHead: 'Jon Ibarra',
        monthlyBudget: 50000,
        aiAdoption: 68,
        aiRoi: 3.0,
        productivityScore: 84,
        activeAiTools: 3,
        topAiTool: 'Intercom Fin',
        health: DepartmentHealth.onTrack,
        monthlyTrend: const [43000, 42500, 42000, 41800, 41300, 41000],
        members: const [
          DepartmentMember(
              name: 'Jon Ibarra',
              role: 'Support Lead',
              aiSpend: 1500,
              toolsUsed: 3),
        ],
      ),
      TeamModel(
        name: 'HR',
        spend: 28000,
        trendPercent: 1,
        memberCount: 8,
        departmentHead: 'Grace Kim',
        monthlyBudget: 32000,
        aiAdoption: 55,
        aiRoi: 1.8,
        productivityScore: 66,
        activeAiTools: 2,
        topAiTool: 'ChatGPT Enterprise',
        health: DepartmentHealth.onTrack,
        monthlyTrend: const [26500, 27000, 27200, 27600, 27800, 28000],
        members: const [
          DepartmentMember(
              name: 'Grace Kim',
              role: 'HR Director',
              aiSpend: 900,
              toolsUsed: 2),
        ],
      ),
      TeamModel(
        name: 'Operations',
        spend: 61300,
        trendPercent: 3,
        memberCount: 12,
        departmentHead: 'Ravi Desai',
        monthlyBudget: 70000,
        aiAdoption: 70,
        aiRoi: 2.4,
        productivityScore: 75,
        activeAiTools: 3,
        topAiTool: 'Gemini',
        health: DepartmentHealth.onTrack,
        monthlyTrend: const [56000, 57500, 58800, 59900, 60600, 61300],
        members: const [
          DepartmentMember(
              name: 'Ravi Desai',
              role: 'Ops Director',
              aiSpend: 1700,
              toolsUsed: 3),
        ],
      ),
    ];
  }

  Future<List<ApprovalModel>> fetchApprovals() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      ApprovalModel(
        id: 'a1',
        requesterName: 'Priya Shah (CFO)',
        department: 'Finance',
        title: 'Annual Salesforce renewal',
        amount: 54000,
        category: 'Software',
        requestedAt: now.subtract(const Duration(hours: 3)),
        businessJustification:
            'Core CRM for the sales org; renewal keeps pricing locked at current tier ahead of a Q3 increase.',
        expectedRoi: '4.2x — protects \$2.1M in tracked pipeline',
        cfoRecommendation: 'Approve — flat renewal, no rate increase.',
        priority: ApprovalPriority.high,
      ),
      ApprovalModel(
        id: 'a2',
        requesterName: 'Sam Rivera (Eng Mgr)',
        department: 'Engineering',
        title: 'New AWS Reserved Instances',
        amount: 21500,
        category: 'Infrastructure',
        requestedAt: now.subtract(const Duration(hours: 9)),
        businessJustification:
            'Reserved capacity reduces on-demand compute costs for the new inference cluster by ~30%.',
        expectedRoi: '2.8x over 12 months via reduced compute spend',
        cfoRecommendation: 'Approve with review at 6 months.',
        priority: ApprovalPriority.medium,
      ),
      ApprovalModel(
        id: 'a3',
        requesterName: 'Dana Cole (Marketing)',
        department: 'Marketing',
        title: 'Q3 conference sponsorship',
        amount: 12000,
        category: 'Marketing',
        requestedAt: now.subtract(const Duration(days: 1)),
        businessJustification:
            'Category-defining event; expected 40+ qualified leads.',
        expectedRoi: '1.6x based on prior-year sponsorship conversion',
        cfoRecommendation:
            'Needs more detail on lead attribution before approval.',
        priority: ApprovalPriority.low,
      ),
    ];
  }

  Future<List<ReportModel>> fetchReports() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      ReportModel(
        id: 'r1',
        title: 'Q2 Board Spend Summary',
        period: 'Apr – Jun 2026',
        summary:
            'Company-wide spend tracked 6% under the board-approved budget for the quarter.',
        chartValues: [142000, 158000, 149000],
        chartLabels: ['Apr', 'May', 'Jun'],
      ),
      ReportModel(
        id: 'r2',
        title: 'Vendor Concentration Report',
        period: 'Trailing 12 months',
        summary:
            'Top 5 vendors now account for 61% of total software spend, up from 54% last year.',
        chartValues: [61, 54, 49],
        chartLabels: ['2026', '2025', '2024'],
      ),
      ReportModel(
        id: 'r3',
        title: 'AI Spend Policy Compliance',
        period: 'July 2026',
        summary:
            '92% of new tool requests this month followed the AI-assisted approval workflow.',
        chartValues: [92, 88, 81],
        chartLabels: ['Jul', 'Jun', 'May'],
      ),
    ];
  }

  Future<ChatMessageModel> sendChatMessage(String userText) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    final lower = userText.toLowerCase();
    String reply;
    if (lower.contains('engineering') || lower.contains('eng')) {
      reply =
          "Engineering is your largest cost center at \$182K/mo, up 14% from last month — mostly new "
          "cloud infra vendors. Want me to break down which tools drove the increase?";
    } else if (lower.contains('save') || lower.contains('saving')) {
      reply =
          "You're on pace to save about \$32K this quarter by consolidating overlapping SaaS tools "
          "in Sales and Marketing. I can draft a renegotiation plan for the next 3 renewals if that helps.";
    } else if (lower.contains('forecast') || lower.contains('budget')) {
      reply =
          "At the current burn rate of \$68.9K/mo, you have roughly 3.2 months of runway left in this "
          "quarter's budget before Engineering needs a top-up.";
    } else if (lower.contains('compare') || lower.contains('department')) {
      reply =
          "Engineering leads on ROI at 4.1x, followed by Support at 3.0x. Marketing trails at 2.1x and "
          "is currently 14% over its monthly budget — that's the one I'd flag first.";
    } else if (lower.contains('unused') || lower.contains('license')) {
      reply =
          "I'm seeing 24 unused GitHub Copilot licenses in Engineering (30+ days idle) and 6 unused "
          "Gemini seats in Operations. Reassigning or downgrading those could save about \$1,900/mo.";
    } else if (lower.contains('board')) {
      reply =
          "Here's a board-ready summary: total AI spend is \$482.3K this quarter (6% under budget), "
          "Engineering leads on ROI, and three renewals — Claude, Zoom, Datadog — need decisions this week. "
          "Want me to export this as a PDF?";
    } else {
      reply =
          "Company-wide spend is at \$482.3K this quarter, tracking 6% under the board-approved budget. "
          "Ask me about any department, vendor, or upcoming renewal for more detail.";
    }
    return ChatMessageModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: reply,
        fromUser: false,
        sentAt: DateTime.now());
  }
}
