import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AiSegment { chat, insights }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
  });

  final String id;
  final String text;
  final bool isFromUser;
}

enum InsightSeverity { info, warning, critical }

extension InsightSeverityColors on InsightSeverity {
  Color get background {
    switch (this) {
      case InsightSeverity.info:
        return const Color(0xFFE6F1FB);
      case InsightSeverity.warning:
        return const Color(0xFFFAEEDA);
      case InsightSeverity.critical:
        return const Color(0xFFFCEBEB);
    }
  }

  Color get foreground {
    switch (this) {
      case InsightSeverity.info:
        return const Color(0xFF0C447C);
      case InsightSeverity.warning:
        return const Color(0xFF633806);
      case InsightSeverity.critical:
        return const Color(0xFF791F1F);
    }
  }

  IconData get icon {
    switch (this) {
      case InsightSeverity.info:
        return Icons.insights_outlined;
      case InsightSeverity.warning:
        return Icons.trending_down;
      case InsightSeverity.critical:
        return Icons.priority_high;
    }
  }
}

class AiInsight {
  const AiInsight({
    required this.title,
    required this.description,
    required this.severity,
  });

  final String title;
  final String description;
  final InsightSeverity severity;
}

class EngineeringManagerAiData {
  const EngineeringManagerAiData({
    required this.selectedSegment,
    required this.messages,
    required this.isAiTyping,
    required this.insights,
  });

  final AiSegment selectedSegment;
  final List<ChatMessage> messages;
  final bool isAiTyping;
  final List<AiInsight> insights;

  EngineeringManagerAiData copyWith({
    AiSegment? selectedSegment,
    List<ChatMessage>? messages,
    bool? isAiTyping,
    List<AiInsight>? insights,
  }) {
    return EngineeringManagerAiData(
      selectedSegment: selectedSegment ?? this.selectedSegment,
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      insights: insights ?? this.insights,
    );
  }
}

sealed class EngineeringManagerAiState {
  const EngineeringManagerAiState();
}

class EngineeringManagerAiInitial extends EngineeringManagerAiState {
  const EngineeringManagerAiInitial();
}

class EngineeringManagerAiLoading extends EngineeringManagerAiState {
  const EngineeringManagerAiLoading();
}

class EngineeringManagerAiLoaded extends EngineeringManagerAiState {
  const EngineeringManagerAiLoaded(this.data);

  final EngineeringManagerAiData data;
}

class EngineeringManagerAiError extends EngineeringManagerAiState {
  const EngineeringManagerAiError(this.message);

  final String message;
}

/// Cubit for Engineering Manager · AI Copilot.
///
/// `loadInsights()` and `sendMessage()` call mock methods with an artificial
/// delay per spec section 12. Swap the `_mock*` methods for real repository
/// calls once the API is available.
class EngineeringManagerAiCubit extends Cubit<EngineeringManagerAiState> {
  EngineeringManagerAiCubit() : super(const EngineeringManagerAiInitial());

  int _messageCounter = 0;

  Future<void> loadInsights() async {
    emit(const EngineeringManagerAiLoading());
    try {
      final insights = await _mockFetchInsights();
      emit(
        EngineeringManagerAiLoaded(
          EngineeringManagerAiData(
            selectedSegment: AiSegment.chat,
            messages: const [
              ChatMessage(
                id: 'greeting',
                text: 'Hi Priya — ask me about your team\'s sprint, bugs, or PR backlog.',
                isFromUser: false,
              ),
            ],
            isAiTyping: false,
            insights: insights,
          ),
        ),
      );
    } catch (e) {
      emit(EngineeringManagerAiError(e.toString()));
    }
  }

  void switchSegment(AiSegment segment) {
    final current = state;
    if (current is EngineeringManagerAiLoaded) {
      emit(EngineeringManagerAiLoaded(current.data.copyWith(selectedSegment: segment)));
    }
  }

  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! EngineeringManagerAiLoaded || text.trim().isEmpty) return;

    _messageCounter++;
    final userMessage = ChatMessage(
      id: 'user-$_messageCounter',
      text: text.trim(),
      isFromUser: true,
    );

    emit(
      EngineeringManagerAiLoaded(
        current.data.copyWith(
          messages: [...current.data.messages, userMessage],
          isAiTyping: true,
        ),
      ),
    );

    final reply = await _mockFetchReply(text);

    final latest = state;
    if (latest is! EngineeringManagerAiLoaded) return;

    _messageCounter++;
    final replyMessage = ChatMessage(
      id: 'ai-$_messageCounter',
      text: reply,
      isFromUser: false,
    );

    emit(
      EngineeringManagerAiLoaded(
        latest.data.copyWith(
          messages: [...latest.data.messages, replyMessage],
          isAiTyping: false,
        ),
      ),
    );
  }

  Future<List<AiInsight>> _mockFetchInsights() async {
    await Future.delayed(const Duration(milliseconds: 700));
    return const [
      AiInsight(
        title: 'Sprint velocity trending down',
        description: 'Down 12% versus the last 3 sprints. Consider reviewing scope.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        title: '3 pull requests stale over 48h',
        description: 'Fix payment retry logic has had no reviewer activity since Monday.',
        severity: InsightSeverity.critical,
      ),
      AiInsight(
        title: 'Rohan is over capacity this sprint',
        description: 'Assigned 14 points against a typical load of 8.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        title: 'Bug intake steady',
        description: 'Open bug count is flat week over week at 17.',
        severity: InsightSeverity.info,
      ),
    ];
  }

  Future<String> _mockFetchReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final lower = prompt.toLowerCase();
    if (lower.contains('bug')) {
      return 'You have 3 critical and 17 open bugs. Critical ones are all in api-service.';
    }
    if (lower.contains('sprint') || lower.contains('velocity')) {
      return 'Sprint 14 is at 68% (27 of 40 points) with 4 days left. Velocity is down 12% versus recent sprints.';
    }
    if (lower.contains('pr') || lower.contains('review')) {
      return 'There are 3 pending PR reviews. The oldest, from Sara, has been open for over a day.';
    }
    return 'I can help with sprint status, bug counts, or PR review load — what would you like to check?';
  }
}