import '../../../../shared/models/team_model.dart';
import '../../../../shared/models/approval_model.dart';
import '../../../../shared/models/insight_model.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/report_model.dart';
import '../../../../shared/widgets/simple_bar_chart.dart';

/// All mock data + simulated network delay for the CEO role lives here,
/// separate from the Cubits, so it can later be swapped for a real API
/// client without touching any UI or state-management code.
class CeoMockRepository {
  Future<Map<String, double>> fetchKpis() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      'Total Spend': 482300,
      'Monthly Burn': 68900,
      'Budget Remaining': 217700,
      'Active Vendors': 46,
    };
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

  Future<List<InsightModel>> fetchInsights() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      InsightModel(
        id: 'i1',
        title: 'Engineering spend up 14% MoM',
        description: 'Driven mostly by new cloud infrastructure vendors added in the last 3 weeks.',
        severity: InsightSeverity.warning,
      ),
      InsightModel(
        id: 'i2',
        title: 'On pace to save \$32K this quarter',
        description: 'Consolidating overlapping SaaS tools across Sales and Marketing is ahead of schedule.',
        severity: InsightSeverity.positive,
      ),
      InsightModel(
        id: 'i3',
        title: '3 vendor contracts renew next month',
        description: 'Zoom, Notion, and Datadog renewals total \$18,400/mo — worth a renegotiation pass.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  Future<List<TeamModel>> fetchDepartments() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const [
      TeamModel(name: 'Engineering', spend: 182000, trendPercent: 14, memberCount: 38),
      TeamModel(name: 'Sales', spend: 96000, trendPercent: -4, memberCount: 22),
      TeamModel(name: 'Marketing', spend: 74000, trendPercent: 6, memberCount: 14),
      TeamModel(name: 'Support', spend: 41000, trendPercent: -2, memberCount: 19),
      TeamModel(name: 'HR', spend: 28000, trendPercent: 1, memberCount: 8),
      TeamModel(name: 'Operations', spend: 61300, trendPercent: 3, memberCount: 12),
    ];
  }

  Future<List<ApprovalModel>> fetchApprovals() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      ApprovalModel(
        id: 'a1',
        requesterName: 'Priya Shah (CFO)',
        title: 'Annual Salesforce renewal',
        amount: 54000,
        category: 'Software',
        requestedAt: now.subtract(const Duration(hours: 3)),
      ),
      ApprovalModel(
        id: 'a2',
        requesterName: 'Sam Rivera (Eng Mgr)',
        title: 'New AWS Reserved Instances',
        amount: 21500,
        category: 'Infrastructure',
        requestedAt: now.subtract(const Duration(hours: 9)),
      ),
      ApprovalModel(
        id: 'a3',
        requesterName: 'Dana Cole (Marketing)',
        title: 'Q3 conference sponsorship',
        amount: 12000,
        category: 'Marketing',
        requestedAt: now.subtract(const Duration(days: 1)),
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
        summary: 'Company-wide spend tracked 6% under the board-approved budget for the quarter.',
        chartValues: [142000, 158000, 149000],
        chartLabels: ['Apr', 'May', 'Jun'],
      ),
      ReportModel(
        id: 'r2',
        title: 'Vendor Concentration Report',
        period: 'Trailing 12 months',
        summary: 'Top 5 vendors now account for 61% of total software spend, up from 54% last year.',
        chartValues: [61, 54, 49],
        chartLabels: ['2026', '2025', '2024'],
      ),
      ReportModel(
        id: 'r3',
        title: 'AI Spend Policy Compliance',
        period: 'July 2026',
        summary: '92% of new tool requests this month followed the AI-assisted approval workflow.',
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
      reply = "Engineering is your largest cost center at \$182K/mo, up 14% from last month — mostly new "
          "cloud infra vendors. Want me to break down which tools drove the increase?";
    } else if (lower.contains('save') || lower.contains('saving')) {
      reply = "You're on pace to save about \$32K this quarter by consolidating overlapping SaaS tools "
          "in Sales and Marketing. I can draft a renegotiation plan for the next 3 renewals if that helps.";
    } else if (lower.contains('forecast') || lower.contains('budget')) {
      reply = "At the current burn rate of \$68.9K/mo, you have roughly 3.2 months of runway left in this "
          "quarter's budget before Engineering needs a top-up.";
    } else {
      reply = "Company-wide spend is at \$482.3K this quarter, tracking 6% under the board-approved budget. "
          "Ask me about any department, vendor, or upcoming renewal for more detail.";
    }
    return ChatMessageModel(id: DateTime.now().microsecondsSinceEpoch.toString(), text: reply, fromUser: false, sentAt: DateTime.now());
  }
}
