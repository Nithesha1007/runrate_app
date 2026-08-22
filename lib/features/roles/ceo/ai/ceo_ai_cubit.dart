// ceo_ai_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import '../../../../shared/models/chat_message_model.dart';
import 'ceo_ai_state.dart';

class CeoAiCubit extends Cubit<CeoAiState> {
  final CeoMockRepository _repo;

  /// In-memory cache of every session's messages, keyed by session id.
  /// This is what lets switching chats (including a brand-new one you just
  /// started typing in) preserve exactly what was there, instead of
  /// re-fetching mock data and losing it. Swap for a real persistence layer
  /// (local db / backend) when available.
  final Map<String, List<ChatMessageModel>> _sessionCache = {};

  // NOTE: no hardcoded welcome bubble — the greeting lives in the
  // empty-state header UI, so `messages` starts empty until the user sends
  // their first message or opens a session from the sidebar.
  CeoAiCubit(this._repo) : super(const CeoAiState()) {
    _loadInsights();
    _loadBriefing();
    _loadSessions();
  }

  Future<void> _loadInsights() async {
    final insights = await _repo.fetchInsights();
    emit(state.copyWith(insights: insights, insightsLoading: false));
  }

  Future<void> _loadBriefing() async {
    final briefing = await _repo.fetchDailyBriefing();
    emit(state.copyWith(briefing: briefing, briefingLoading: false));
  }

  
  /// so the sidebar has something to render on first load. Live sessions
  /// created via sendMessage() get prepended on top of these at runtime.
  void _loadSessions() {
    final now = DateTime.now();
    emit(state.copyWith(sessions: [
      ChatSessionSummary(
          id: 's1',
          title: 'Q3 budget forecast review',
          updatedAt: now.subtract(const Duration(hours: 2))),
      ChatSessionSummary(
          id: 's2',
          title: 'Engineering spend vs headcount',
          updatedAt: now.subtract(const Duration(days: 1))),
      ChatSessionSummary(
          id: 's3',
          title: 'Vendor consolidation ideas',
          updatedAt: now.subtract(const Duration(days: 3))),
      ChatSessionSummary(
          id: 's4',
          title: 'Escalated approvals — August',
          updatedAt: now.subtract(const Duration(days: 6))),
    ]));
  }

  void setView(int index) => emit(state.copyWith(viewIndex: index));

  void openSidebar() => emit(state.copyWith(sidebarOpen: true));

  void closeSidebar() => emit(state.copyWith(sidebarOpen: false));

  /// Saves whatever is currently on screen into the session cache before we
  /// navigate away from it (new chat, or switching to another session).
  void _cacheCurrentSession() {
    final id = state.activeSessionId;
    if (id != null && state.messages.isNotEmpty) {
      _sessionCache[id] = state.messages;
    }
  }

  /// Clears the current conversation and returns to the empty-state landing
  /// screen — wired to "New Chat" (header quick action + sidebar button).
  void startNewChat() {
    _cacheCurrentSession();
    emit(state.copyWith(
      messages: [],
      isTyping: false,
      viewIndex: 0,
      sidebarOpen: false,
      clearActiveSessionId: true,
      clearAttachment: true,
    ));
  }

  /// Loads a session from the sidebar. Checks the in-memory cache first —
  /// this is what makes a chat you just had (including a brand-new one)
  /// show up correctly when you come back to it, instead of being replaced
  /// by re-fetched mock/placeholder data.
  Future<void> selectSession(String sessionId) async {
    if (sessionId == state.activeSessionId) {
      emit(state.copyWith(sidebarOpen: false));
      return;
    }

    _cacheCurrentSession();

    final cached = _sessionCache[sessionId];
    if (cached != null) {
      emit(state.copyWith(
        messages: cached,
        activeSessionId: sessionId,
        sidebarOpen: false,
        viewIndex: 0,
        isTyping: false,
      ));
      return;
    }

    final session = state.sessions.firstWhere((s) => s.id == sessionId);
    emit(state.copyWith(isTyping: true, sidebarOpen: false));
    final messages = await _repo.fetchSessionMessages(sessionId);
    _sessionCache[sessionId] = messages;
    emit(state.copyWith(
      messages: messages,
      isTyping: false,
      activeSessionId: session.id,
      viewIndex: 0,
    ));
  }

  /// Called when the user picks a file via the "+" attach menu
  /// (Photo / PDF / Browse files).
  void attachFile(String fileName) {
    emit(state.copyWith(pendingAttachmentName: fileName));
  }

  void removeAttachment() {
    emit(state.copyWith(clearAttachment: true));
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    final attachment = state.pendingAttachmentName;
    if (trimmed.isEmpty && attachment == null) return;

    final displayText = attachment == null
        ? trimmed
        : (trimmed.isEmpty ? '📎 $attachment' : '$trimmed\n📎 $attachment');

    final userMessage = ChatMessageModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: displayText,
      fromUser: true,
      sentAt: DateTime.now(),
    );

    var sessionId = state.activeSessionId;
    var sessions = state.sessions;

    if (sessionId == null) {
      // First message of a brand-new chat: create a session for it right
      // now and put it at the top of "Recent" so it's visible immediately,
      // not only after leaving and reopening the sidebar.
      sessionId = 'local_${DateTime.now().microsecondsSinceEpoch}';
      final title =
          displayText.length > 40 ? '${displayText.substring(0, 40)}…' : displayText;
      sessions = [
        ChatSessionSummary(id: sessionId, title: title, updatedAt: DateTime.now()),
        ...sessions,
      ];
    } else {
      // Existing chat: bump it to the top of Recent on every new message,
      // like Claude does.
      sessions = [
        for (final s in sessions)
          if (s.id == sessionId)
            ChatSessionSummary(id: s.id, title: s.title, updatedAt: DateTime.now())
          else
            s,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }

    final withUserMsg = [...state.messages, userMessage];
    _sessionCache[sessionId] = withUserMsg;

    emit(state.copyWith(
      messages: withUserMsg,
      isTyping: true,
      clearAttachment: true,
      activeSessionId: sessionId,
      sessions: sessions,
    ));

    final reply = await _repo.sendChatMessage(
        trimmed.isEmpty ? 'User shared a file: $attachment' : text);

    final finalMessages = [...state.messages, reply];
    _sessionCache[sessionId] = finalMessages;
    emit(state.copyWith(messages: finalMessages, isTyping: false));
  }
}