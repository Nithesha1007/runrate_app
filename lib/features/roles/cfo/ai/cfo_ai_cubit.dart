import 'package:flutter_bloc/flutter_bloc.dart';

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

enum ChatSender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.sentAt,
  });

  final String id;
  final ChatSender sender;
  final String text;
  final DateTime sentAt;
}

enum InsightSeverity { info, warning, positive }

class AiInsight {
  const AiInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
  });

  final String id;
  final String title;
  final String description;
  final InsightSeverity severity;
}

enum CfoAiTab { chat, insights }

class CfoAiData {
  const CfoAiData({
    required this.activeTab,
    required this.messages,
    required this.insights,
    this.isAssistantTyping = false,
  });

  final CfoAiTab activeTab;
  final List<ChatMessage> messages;
  final List<AiInsight> insights;
  final bool isAssistantTyping;

  CfoAiData copyWith({
    CfoAiTab? activeTab,
    List<ChatMessage>? messages,
    List<AiInsight>? insights,
    bool? isAssistantTyping,
  }) {
    return CfoAiData(
      activeTab: activeTab ?? this.activeTab,
      messages: messages ?? this.messages,
      insights: insights ?? this.insights,
      isAssistantTyping: isAssistantTyping ?? this.isAssistantTyping,
    );
  }
}

/// ---------------------------------------------------------------------
/// State
/// ---------------------------------------------------------------------

abstract class CfoAiState {
  const CfoAiState();
}

class CfoAiInitial extends CfoAiState {
  const CfoAiInitial();
}

class CfoAiLoading extends CfoAiState {
  const CfoAiLoading();
}

class CfoAiLoaded extends CfoAiState {
  const CfoAiLoaded(this.data);

  final CfoAiData data;
}

class CfoAiError extends CfoAiState {
  const CfoAiError(this.message);

  final String message;
}

/// ---------------------------------------------------------------------
/// Cubit
/// ---------------------------------------------------------------------

class CfoAiCubit extends Cubit<CfoAiState> {
  CfoAiCubit() : super(const CfoAiInitial()) {
    load();
  }

  int _messageCounter = 0;

  Future<void> load() async {
    emit(const CfoAiLoading());
    try {
      final insights = await _fetchInsights();
      emit(CfoAiLoaded(CfoAiData(
        activeTab: CfoAiTab.chat,
        messages: _initialMessages(),
        insights: insights,
      )));
    } catch (_) {
      emit(const CfoAiError('Could not load the AI copilot. Pull down to retry.'));
    }
  }

  void switchTab(CfoAiTab tab) {
    final current = state;
    if (current is! CfoAiLoaded) return;
    emit(CfoAiLoaded(current.data.copyWith(activeTab: tab)));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state;
    if (current is! CfoAiLoaded) return;

    final userMessage = ChatMessage(
      id: 'msg_${_messageCounter++}',
      sender: ChatSender.user,
      text: trimmed,
      sentAt: DateTime.now(),
    );

    emit(CfoAiLoaded(current.data.copyWith(
      messages: [...current.data.messages, userMessage],
      isAssistantTyping: true,
    )));

    try {
      final reply = await _fetchAssistantReply(trimmed);
      final latest = state;
      if (latest is! CfoAiLoaded) return;

      final assistantMessage = ChatMessage(
        id: 'msg_${_messageCounter++}',
        sender: ChatSender.assistant,
        text: reply,
        sentAt: DateTime.now(),
      );

      emit(CfoAiLoaded(latest.data.copyWith(
        messages: [...latest.data.messages, assistantMessage],
        isAssistantTyping: false,
      )));
    } catch (_) {
      final latest = state;
      if (latest is! CfoAiLoaded) return;
      emit(CfoAiLoaded(latest.data.copyWith(isAssistantTyping: false)));
    }
  }

  List<ChatMessage> _initialMessages() {
    return [
      ChatMessage(
        id: 'msg_seed',
        sender: ChatSender.assistant,
        text:
            'Hi, I\'m your AI copilot. Ask me about cash flow, spend trends, or anything on the dashboard.',
        sentAt: DateTime.now(),
      ),
    ];
  }

  /// Mock repository call. Replace with a real API/repository call —
  /// keep the artificial delay pattern for now per spec section 12.
  Future<List<AiInsight>> _fetchInsights() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      AiInsight(
        id: 'insight_1',
        title: 'Runway tightening',
        description: 'At the current burn rate, runway drops below 10 months by next quarter.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        id: 'insight_2',
        title: 'Sales & marketing over budget',
        description: 'This department is 20% over its quarterly budget, mainly from ad spend.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        id: 'insight_3',
        title: 'MRR growth accelerating',
        description: 'MRR grew 8% month-over-month, the fastest pace in the last two quarters.',
        severity: InsightSeverity.positive,
      ),
      AiInsight(
        id: 'insight_4',
        title: 'Vendor consolidation opportunity',
        description: 'Three SaaS tools have overlapping features and could be consolidated.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  /// Mock repository call for a chat reply.
  Future<String> _fetchAssistantReply(String userText) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return 'Here\'s a placeholder answer about "$userText" — wire this up to the real assistant API.';
  }
}