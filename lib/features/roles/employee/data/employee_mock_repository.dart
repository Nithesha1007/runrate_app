import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/insight_model.dart';

/// Mock repository used by the employee AI Copilot flow.
/// This mirrors the other role repositories so the feature can be developed
/// without a backend while keeping the UI/state contracts identical.
class EmployeeMockRepository {
  Future<List<InsightModel>> fetchInsights() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      InsightModel(
        id: 'i1',
        title: 'AI tool adoption is up 18%',
        description: 'The team is using copilots and workflow automation more consistently across daily operations.',
        severity: InsightSeverity.positive,
      ),
      InsightModel(
        id: 'i2',
        title: 'Approval queue is trending lighter',
        description: 'The backlog of pending requests is down 12% week over week after workflow automation.',
        severity: InsightSeverity.info,
      ),
      InsightModel(
        id: 'i3',
        title: 'Two tools are nearing renewal',
        description: 'Usage is steady, but renewal timing is approaching for the document and reporting suites.',
        severity: InsightSeverity.warning,
      ),
    ];
  }

  Future<String> fetchDailyBriefing() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return 'AI adoption is improving across the team, with approval volume down and two tool renewals coming up next month.';
  }

  Future<List<ChatMessageModel>> fetchSessionMessages(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final base = DateTime.now();
    final messagesBySession = <String, List<ChatMessageModel>>{
      's1': [
        ChatMessageModel(
          id: 's1_user',
          text: 'Can you review the Q3 budget forecast?',
          fromUser: true,
          sentAt: base.subtract(const Duration(minutes: 2)),
        ),
        ChatMessageModel(
          id: 's1_ai',
          text: 'Q3 spend is tracking 6% under budget, with Engineering as the largest cost center and three renewals planned soon.',
          fromUser: false,
          sentAt: base.subtract(const Duration(minutes: 1)),
        ),
      ],
      's2': [
        ChatMessageModel(
          id: 's2_user',
          text: 'Compare Engineering spend with headcount.',
          fromUser: true,
          sentAt: base.subtract(const Duration(hours: 3)),
        ),
        ChatMessageModel(
          id: 's2_ai',
          text: 'Engineering remains the highest spend category at 182K per month across 38 team members.',
          fromUser: false,
          sentAt: base.subtract(const Duration(hours: 2, minutes: 50)),
        ),
      ],
      's3': [
        ChatMessageModel(
          id: 's3_user',
          text: 'Where can we consolidate vendors?',
          fromUser: true,
          sentAt: base.subtract(const Duration(days: 1, hours: 2)),
        ),
        ChatMessageModel(
          id: 's3_ai',
          text: 'Sales and Marketing have overlapping SaaS tools; consolidating them could save roughly 32K this quarter.',
          fromUser: false,
          sentAt: base.subtract(const Duration(days: 1, hours: 1)),
        ),
      ],
      's4': [
        ChatMessageModel(
          id: 's4_user',
          text: 'Which approvals need my attention?',
          fromUser: true,
          sentAt: base.subtract(const Duration(days: 3, hours: 1)),
        ),
        ChatMessageModel(
          id: 's4_ai',
          text: 'Three approvals are active, including the Salesforce renewal at 54K and AWS reserved instances at 21.5K.',
          fromUser: false,
          sentAt: base.subtract(const Duration(days: 3)),
        ),
      ],
    };

    return messagesBySession[sessionId] ?? const [];
  }

  Future<ChatMessageModel> sendChatMessage(String userText) async {
    await Future.delayed(const Duration(milliseconds: 1100));
    final lower = userText.toLowerCase();
    String reply;
    if (lower.contains('engineering') || lower.contains('eng')) {
      reply = 'Engineering is the largest cost center, and automation is helping reduce repetitive manual work.';
    } else if (lower.contains('save') || lower.contains('saving')) {
      reply = 'You are on pace to save about 32K this quarter by consolidating overlapping tools and simplifying approvals.';
    } else if (lower.contains('forecast') || lower.contains('budget')) {
      reply = 'At the current run rate, spend remains within target and team adoption is trending ahead of plan.';
    } else {
      reply = 'AI usage is healthy across the org, and operational efficiency is improving. Ask me about spend, approvals, or vendor opportunities.';
    }

    return ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: reply,
      fromUser: false,
      sentAt: DateTime.now(),
    );
  }
}
