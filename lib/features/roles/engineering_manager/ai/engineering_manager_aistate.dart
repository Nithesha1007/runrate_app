import 'package:equatable/equatable.dart';
import '../../../../shared/models/chat_message_model.dart';

/// Lightweight summary for the sidebar history list — mirrors
/// `ChatSessionSummary` on the CEO AI screen. Swap the mock list in the
/// cubit for a real "list conversations" API call once available.
class EmChatSessionSummary extends Equatable {
  const EmChatSessionSummary({
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

class EngineeringManagerAiState extends Equatable {
  final List<ChatMessageModel> messages;
  final bool isTyping;
  final String? briefing;
  final bool briefingLoading;

  /// Sidebar state — identical mechanics to the CEO AI screen.
  final bool sidebarOpen;
  final List<EmChatSessionSummary> sessions;
  final String? activeSessionId;

  /// Pending file attached via the "+" attach menu, cleared once sent.
  final String? pendingAttachmentName;

  const EngineeringManagerAiState({
    this.messages = const [],
    this.isTyping = false,
    this.briefing,
    this.briefingLoading = true,
    this.sidebarOpen = false,
    this.sessions = const [],
    this.activeSessionId,
    this.pendingAttachmentName,
  });

  EngineeringManagerAiState copyWith({
    List<ChatMessageModel>? messages,
    bool? isTyping,
    String? briefing,
    bool? briefingLoading,
    bool? sidebarOpen,
    List<EmChatSessionSummary>? sessions,
    String? activeSessionId,
    bool clearActiveSessionId = false,
    String? pendingAttachmentName,
    bool clearAttachment = false,
  }) {
    return EngineeringManagerAiState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      briefing: briefing ?? this.briefing,
      briefingLoading: briefingLoading ?? this.briefingLoading,
      sidebarOpen: sidebarOpen ?? this.sidebarOpen,
      sessions: sessions ?? this.sessions,
      activeSessionId:
          clearActiveSessionId ? null : (activeSessionId ?? this.activeSessionId),
      pendingAttachmentName: clearAttachment
          ? null
          : (pendingAttachmentName ?? this.pendingAttachmentName),
    );
  }

  @override
  List<Object?> get props => [
        messages,
        isTyping,
        briefing,
        briefingLoading,
        sidebarOpen,
        sessions,
        activeSessionId,
        pendingAttachmentName,
      ];
}