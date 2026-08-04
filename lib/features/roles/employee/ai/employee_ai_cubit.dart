import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ChatSender { user, assistant }

class AiChatMessage {
  const AiChatMessage({
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

enum AiSegment { chat, insights }

enum EmployeeAiStatus { initial, loading, loaded, error }

@immutable
class EmployeeAiState {
  const EmployeeAiState({
    this.status = EmployeeAiStatus.initial,
    this.segment = AiSegment.chat,
    this.messages = const [],
    this.insights = const [],
    this.isSending = false,
    this.errorMessage,
  });

  final EmployeeAiStatus status;
  final AiSegment segment;
  final List<AiChatMessage> messages;
  final List<AiInsight> insights;
  final bool isSending;
  final String? errorMessage;

  bool get isLoading => status == EmployeeAiStatus.loading;

  EmployeeAiState copyWith({
    EmployeeAiStatus? status,
    AiSegment? segment,
    List<AiChatMessage>? messages,
    List<AiInsight>? insights,
    bool? isSending,
    String? errorMessage,
  }) {
    return EmployeeAiState(
      status: status ?? this.status,
      segment: segment ?? this.segment,
      messages: messages ?? this.messages,
      insights: insights ?? this.insights,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class EmployeeAiCubit extends Cubit<EmployeeAiState> {
  EmployeeAiCubit() : super(const EmployeeAiState()) {
    load();
  }

  int _messageCounter = 0;

  Future<void> load() async {
    emit(state.copyWith(status: EmployeeAiStatus.loading));
    try {
      final insights = await _fetchInsights();
      emit(state.copyWith(
        status: EmployeeAiStatus.loaded,
        messages: _initialMessages(),
        insights: insights,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: EmployeeAiStatus.error,
        errorMessage: 'Could not load the AI copilot. Please try again.',
      ));
    }
  }

  void selectSegment(AiSegment segment) {
    emit(state.copyWith(segment: segment));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final current = state;
    if (current.status != EmployeeAiStatus.loaded || current.isSending) return;

    final userMessage = AiChatMessage(
      id: 'msg_${_messageCounter++}',
      sender: ChatSender.user,
      text: trimmed,
      sentAt: DateTime.now(),
    );

    emit(current.copyWith(
      messages: [...current.messages, userMessage],
      isSending: true,
      errorMessage: null,
    ));

    try {
      final reply = await _fetchAssistantReply(trimmed);
      final latest = state;
      if (latest.status != EmployeeAiStatus.loaded) return;

      final assistantMessage = AiChatMessage(
        id: 'msg_${_messageCounter++}',
        sender: ChatSender.assistant,
        text: reply,
        sentAt: DateTime.now(),
      );

      emit(latest.copyWith(
        messages: [...latest.messages, assistantMessage],
        isSending: false,
      ));
    } catch (_) {
      final latest = state;
      if (latest.status != EmployeeAiStatus.loaded) return;
      emit(latest.copyWith(
        isSending: false,
        errorMessage: 'Failed to get a response. Please try again.',
      ));
    }
  }

  List<AiChatMessage> _initialMessages() {
    return [
      AiChatMessage(
        id: 'msg_seed',
        sender: ChatSender.assistant,
        text: 'Hi there! I can help you summarize your work, team progress, and action items.',
        sentAt: DateTime.now(),
      ),
    ];
  }

  Future<List<AiInsight>> _fetchInsights() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return const [
      AiInsight(
        id: 'insight_1',
        title: 'Task completion lagging',
        description: 'Your team has 3 tasks overdue this week. Follow up with assignees to avoid delays.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        id: 'insight_2',
        title: 'Excellent productivity',
        description: 'You completed 90% of your assigned goals this quarter, ahead of target.',
        severity: InsightSeverity.positive,
      ),
      AiInsight(
        id: 'insight_3',
        title: 'Meeting cadence suggestion',
        description: 'Consider reducing weekly syncs to biweekly to free up focus time for execution.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  Future<String> _fetchAssistantReply(String userText) async {
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    return 'I hear you asking about "$userText". This is a placeholder response while the AI backend is being connected.';
  }
}
