import 'package:equatable/equatable.dart';
import '../../../../shared/models/chat_message_model.dart';
import '../../../../shared/models/insight_model.dart';

/// Lightweight summary for the sidebar history list. Swap the mock list in
/// the cubit for a real "list conversations" API call once available —
/// `messages` here stays empty until `selectSession` loads it.
class ChatSessionSummary extends Equatable {
  const ChatSessionSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [id, title, updatedAt];
}

class EmployeeAiState extends Equatable {
  final int viewIndex; // 0 = chat, 1 = insights/history
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final List<InsightModel> insights;
  final bool insightsLoading;
  final String? briefing;
  final bool briefingLoading;

  /// Sidebar state
  final bool sidebarOpen;
  final List<ChatSessionSummary> sessions;
  final String? activeSessionId;

  /// Pending file attached via the "File" button, cleared once sent.
  final String? pendingAttachmentName;

  const EmployeeAiState({
    this.viewIndex = 0,
    this.messages = const [],
    this.isTyping = false,
    this.insights = const [],
    this.insightsLoading = true,
    this.briefing,
    this.briefingLoading = true,
    this.sidebarOpen = false,
    this.sessions = const [],
    this.activeSessionId,
    this.pendingAttachmentName,
  });

  EmployeeAiState copyWith({
    int? viewIndex,
    List<ChatMessageModel>? messages,
    bool? isTyping,
    List<InsightModel>? insights,
    bool? insightsLoading,
    String? briefing,
    bool? briefingLoading,
    bool? sidebarOpen,
    List<ChatSessionSummary>? sessions,
    String? activeSessionId,
    bool clearActiveSessionId = false,
    String? pendingAttachmentName,
    bool clearAttachment = false,
  }) {
    return EmployeeAiState(
      viewIndex: viewIndex ?? this.viewIndex,
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      insights: insights ?? this.insights,
      insightsLoading: insightsLoading ?? this.insightsLoading,
      briefing: briefing ?? this.briefing,
      briefingLoading: briefingLoading ?? this.briefingLoading,
      sidebarOpen: sidebarOpen ?? this.sidebarOpen,
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActiveSessionId
          ? null
          : (activeSessionId ?? this.activeSessionId),
      pendingAttachmentName: clearAttachment
          ? null
          : (pendingAttachmentName ?? this.pendingAttachmentName),
    );
  }

  @override
  List<Object?> get props => [
        viewIndex,
        messages,
        isTyping,
        insights,
        insightsLoading,
        briefing,
        briefingLoading,
        sidebarOpen,
        sessions,
        activeSessionId,
        pendingAttachmentName,
      ];
}