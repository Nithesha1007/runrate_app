import 'package:flutter_bloc/flutter_bloc.dart';

enum OrgAdminAiStatus { initial, loading, loaded, error }

enum AiSegment { chat, insights }

enum ChatSender { admin, assistant }

enum InsightSeverity { info, warning, critical }

class ChatMessage {
  const ChatMessage({required this.sender, required this.text});

  final ChatSender sender;
  final String text;
}

class AiInsight {
  const AiInsight({
    required this.title,
    required this.summary,
    required this.severity,
  });

  final String title;
  final String summary;
  final InsightSeverity severity;
}

class OrgAdminAiState {
  const OrgAdminAiState({
    this.status = OrgAdminAiStatus.initial,
    this.segment = AiSegment.chat,
    this.messages = const [],
    this.insights = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final OrgAdminAiStatus status;
  final AiSegment segment;
  final List<ChatMessage> messages;
  final List<AiInsight> insights;
  final bool isSending;
  final String? errorMessage;

  OrgAdminAiState copyWith({
    OrgAdminAiStatus? status,
    AiSegment? segment,
    List<ChatMessage>? messages,
    List<AiInsight>? insights,
    bool? isSending,
    String? errorMessage,
  }) {
    return OrgAdminAiState(
      status: status ?? this.status,
      segment: segment ?? this.segment,
      messages: messages ?? this.messages,
      insights: insights ?? this.insights,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
    );
  }
}

/// State/cubit for Org Admin · AI Copilot.
/// Loads AI insights from a mock repository call and simulates a chat
/// assistant reply (Future with an artificial delay, per spec section 12).
class OrgAdminAiCubit extends Cubit<OrgAdminAiState> {
  OrgAdminAiCubit() : super(const OrgAdminAiState());

  Future<void> loadInsights() async {
    emit(state.copyWith(status: OrgAdminAiStatus.loading));
    try {
      final insights = await _fetchMockInsights();
      emit(state.copyWith(status: OrgAdminAiStatus.loaded, insights: insights));
    } catch (e) {
      emit(state.copyWith(
        status: OrgAdminAiStatus.error,
        errorMessage: 'Could not load insights. Pull down to try again.',
      ));
    }
  }

  void switchSegment(AiSegment segment) {
    emit(state.copyWith(segment: segment));
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final updated = [
      ...state.messages,
      ChatMessage(sender: ChatSender.admin, text: text.trim()),
    ];
    emit(state.copyWith(messages: updated, isSending: true));
    final reply = await _fetchMockReply(text.trim());
    emit(state.copyWith(
      messages: [...updated, ChatMessage(sender: ChatSender.assistant, text: reply)],
      isSending: false,
    ));
  }

  Future<List<AiInsight>> _fetchMockInsights() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      AiInsight(
        title: 'Spend spike in Marketing',
        summary: 'Marketing team spend is up 34% week over week.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        title: '12 approvals pending over 48h',
        summary: 'Several approvals have been waiting more than two days.',
        severity: InsightSeverity.critical,
      ),
      AiInsight(
        title: 'New signups trending up',
        summary: 'Signups grew 18% this week compared to last week.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  Future<String> _fetchMockReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 900));
    return "Here's a summary based on your organization's current data. "
        'This is a mock response — connect a real assistant backend to replace it.';
  }
}