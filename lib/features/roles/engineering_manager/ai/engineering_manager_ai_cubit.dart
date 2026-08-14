import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/engineering_manager/ai/engineering_manager_aistate.dart';
import '../../../../shared/models/chat_message_model.dart';


/// Cubit for Engineering Manager · AI Copilot.
///
/// Mirrors `CeoAiCubit`'s structure exactly (sidebar sessions, in-memory
/// session cache, attachment handling) so the screen can reuse the same
/// UI/animations as the CEO AI screen. The only real difference is the
/// mock team dataset and the question-bank-driven answer matching below —
/// swap `_teamData` and `_mockFetchReply` for real repository calls once
/// an Engineering Manager API is available.
class EngineeringManagerAiCubit extends Cubit<EngineeringManagerAiState> {
  final Map<String, List<ChatMessageModel>> _sessionCache = {};

  EngineeringManagerAiCubit() : super(const EngineeringManagerAiState()) {
    _loadBriefing();
    _loadSessions();
  }

  // ---------------------------------------------------------------------
  // Mock "my team" dataset — scoped to Engineering, reused across every
  // category-matched answer below so numbers stay internally consistent.
  // ---------------------------------------------------------------------
  static const _teamName = 'Engineering';
  static const _totalSpend = 42800.0;
  static const _budget = 50000.0;
  static const _lastMonthSpend = 38650.0;
  static const _roiScore = 82;
  static const _productivityGainPct = 0.14;

  static const _tools = [
    (name: 'GitHub Copilot', users: 34, adoption: 0.88, spend: 18400.0, trend: 'up'),
    (name: 'Claude', users: 21, adoption: 0.62, spend: 12100.0, trend: 'up'),
    (name: 'ChatGPT Enterprise', users: 9, adoption: 0.31, spend: 8200.0, trend: 'flat'),
    (name: 'Gemini', users: 3, adoption: 0.09, spend: 4100.0, trend: 'down'),
  ];

  static const _engineers = [
    (name: 'Rohan Mehta', adoption: 0.95, tool: 'GitHub Copilot'),
    (name: 'Sara Kim', adoption: 0.81, tool: 'Claude'),
    (name: 'Ivan Petrov', adoption: 0.74, tool: 'GitHub Copilot'),
    (name: 'Aisha Bello', adoption: 0.22, tool: 'ChatGPT Enterprise'),
    (name: 'Tom Reyes', adoption: 0.11, tool: 'Gemini'),
  ];

  Future<void> _loadBriefing() async {
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(
      briefing:
          'Sprint 14 is at 68% with 4 days left. Copilot adoption is strong at 88%, but Gemini usage has dropped — worth a quick license review.',
      briefingLoading: false,
    ));
  }

  /// TODO: replace with a real "list conversations" endpoint. Mocked here
  /// so the sidebar has something to render on first load.
  void _loadSessions() {
    final now = DateTime.now();
    emit(state.copyWith(sessions: [
      EmChatSessionSummary(
          id: 'em_s1',
          title: 'Sprint AI tooling review',
          updatedAt: now.subtract(const Duration(hours: 3))),
      EmChatSessionSummary(
          id: 'em_s2',
          title: 'Copilot vs Claude for backend team',
          updatedAt: now.subtract(const Duration(days: 1))),
      EmChatSessionSummary(
          id: 'em_s3',
          title: 'August license audit',
          updatedAt: now.subtract(const Duration(days: 4))),
      EmChatSessionSummary(
          id: 'em_s4',
          title: 'PR backlog and stale reviews',
          updatedAt: now.subtract(const Duration(days: 7))),
    ]));
  }

  void openSidebar() => emit(state.copyWith(sidebarOpen: true));

  void closeSidebar() => emit(state.copyWith(sidebarOpen: false));

  void _cacheCurrentSession() {
    final id = state.activeSessionId;
    if (id != null && state.messages.isNotEmpty) {
      _sessionCache[id] = state.messages;
    }
  }

  void startNewChat() {
    _cacheCurrentSession();
    emit(state.copyWith(
      messages: [],
      isTyping: false,
      sidebarOpen: false,
      clearActiveSessionId: true,
      clearAttachment: true,
    ));
  }

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
        isTyping: false,
      ));
      return;
    }

    // No real backend yet — start that session empty rather than fake-fetch.
    emit(state.copyWith(
      messages: [],
      activeSessionId: sessionId,
      sidebarOpen: false,
      isTyping: false,
    ));
  }

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
      sessionId = 'em_local_${DateTime.now().microsecondsSinceEpoch}';
      final title =
          displayText.length > 40 ? '${displayText.substring(0, 40)}…' : displayText;
      sessions = [
        EmChatSessionSummary(id: sessionId, title: title, updatedAt: DateTime.now()),
        ...sessions,
      ];
    } else {
      sessions = [
        for (final s in sessions)
          if (s.id == sessionId)
            EmChatSessionSummary(id: s.id, title: s.title, updatedAt: DateTime.now())
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

    final replyText = await _mockFetchReply(
        trimmed.isEmpty ? 'User shared a file: $attachment' : trimmed);

    final reply = ChatMessageModel(
      id: '${DateTime.now().microsecondsSinceEpoch}_reply',
      text: replyText,
      fromUser: false,
      sentAt: DateTime.now(),
    );

    final finalMessages = [...state.messages, reply];
    _sessionCache[sessionId] = finalMessages;
    emit(state.copyWith(messages: finalMessages, isTyping: false));
  }

  // ---------------------------------------------------------------------
  // ANSWER GENERATION — matches the typed/tapped question against the
  // 6-category question bank (exact match first, then keyword fallback),
  // and builds the reply from `_teamData` above so numbers stay consistent
  // with whatever the Engineering Manager Home/Team screens show.
  // ---------------------------------------------------------------------
  Future<String> _mockFetchReply(String prompt) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final q = prompt.toLowerCase().trim();

    String compact(double v) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
      return v.toStringAsFixed(0);
    }

    // --- AI Tool Usage ---------------------------------------------------
    if (q.contains('most used') || q.contains('most-used')) {
      final top = [..._tools]..sort((a, b) => b.users.compareTo(a.users));
      return '${top.first.name} is your most-used tool with ${top.first.users} active users (${(top.first.adoption * 100).toInt()}% adoption).';
    }
    if (q.contains('highest and lowest') || (q.contains('adopter') && q.contains('lowest'))) {
      final sorted = [..._engineers]..sort((a, b) => b.adoption.compareTo(a.adoption));
      final top = sorted.first;
      final low = sorted.last;
      return 'Highest adopter: ${top.name} at ${(top.adoption * 100).toInt()}% (mainly ${top.tool}). Lowest: ${low.name} at ${(low.adoption * 100).toInt()}% — worth checking in with them.';
    }
    if (q.contains('adoption') && q.contains('changed')) {
      return 'Team AI adoption is up this month, led by Copilot (+6pts) and Claude (+4pts). Gemini usage dipped slightly.';
    }
    if (q.contains('underutilized') || q.contains('under-utilized') || q.contains('under utilized')) {
      final low = [..._tools]..sort((a, b) => a.adoption.compareTo(b.adoption));
      return '${low.first.name} is underutilized — only ${low.first.users} users at ${(low.first.adoption * 100).toInt()}% adoption despite \$${compact(low.first.spend)} in spend.';
    }
    if (q.contains('paying for') || (q.contains('nobody') && q.contains('using'))) {
      final unused = _tools.where((t) => t.adoption < 0.15).toList();
      if (unused.isEmpty) {
        return 'No tool is going fully unused right now — everything has at least some active users.';
      }
      final t = unused.first;
      return 'Yes — ${t.name} has just ${t.users} active users out of your team, at \$${compact(t.spend)}/mo. Worth reviewing those seats.';
    }
    if (q.contains('best value') || (q.contains('value') && q.contains('money'))) {
      return 'GitHub Copilot gives the best value — highest adoption (88%) relative to its spend of \$${compact(18400)}.';
    }

    // --- AI Spend & Budget -------------------------------------------------
    if (q.contains('how much') && q.contains('spend')) {
      return '$_teamName spent \$${compact(_totalSpend)} on AI tools this month, ${((_totalSpend / _budget) * 100).toInt()}% of your \$${compact(_budget)} budget.';
    }
    if (q.contains('on track') && q.contains('budget')) {
      final pct = _totalSpend / _budget;
      final status = pct >= 0.95 ? 'Critical' : (pct >= 0.8 ? 'Warning' : 'Healthy');
      return 'Budget status: $status. You\'ve used ${(pct * 100).toInt()}% of your \$${compact(_budget)} monthly budget.';
    }
    if (q.contains('costing us the most') || (q.contains('tool') && q.contains('costing'))) {
      final top = [..._tools]..sort((a, b) => b.spend.compareTo(a.spend));
      return '${top.first.name} is your biggest AI cost at \$${compact(top.first.spend)}/mo.';
    }
    if (q.contains('why') && q.contains('increase')) {
      final delta = _totalSpend - _lastMonthSpend;
      return 'Spend rose \$${compact(delta)} versus last month, mostly from added Claude seats as adoption grew.';
    }
    if (q.contains('save') && q.contains('unused')) {
      final unused = _tools.where((t) => t.adoption < 0.15);
      final savings = unused.fold<double>(0, (s, t) => s + t.spend * 0.6);
      return 'Reclaiming inactive seats on underused tools could save roughly \$${compact(savings)}/mo.';
    }
    if (q.contains('next month') || (q.contains('spend') && q.contains('look'))) {
      final forecast = _totalSpend * 1.05;
      return 'At current growth, forecasted spend next month is around \$${compact(forecast)} — about 5% above this month.';
    }

    // --- Team Performance ---------------------------------------------------
    if (q.contains('compared with last month') || (q.contains('adoption') && q.contains('last month'))) {
      return 'Team-wide adoption is up about 6 points versus last month, driven mainly by Copilot and Claude.';
    }
    if (q.contains('not using') && q.contains('assigned')) {
      final inactive = _engineers.where((e) => e.adoption < 0.3).toList();
      if (inactive.isEmpty) return 'Everyone is actively using their assigned AI tool right now.';
      return '${inactive.map((e) => e.name).join(', ')} are underusing their assigned tools — worth a quick nudge.';
    }
    if (q.contains('most value') && q.contains('team')) {
      return 'Based on adoption vs spend, the group using Copilot is getting the most value from their AI tooling.';
    }
    if (q.contains('improving team productivity') || (q.contains('productivity') && q.contains('team'))) {
      return 'Yes — teams with higher AI adoption are shipping PRs faster; productivity is up ${(_productivityGainPct * 100).toInt()}% since rollout.';
    }
    if (q.contains('may need help') || (q.contains('engineers') && q.contains('help'))) {
      final sorted = [..._engineers]..sort((a, b) => a.adoption.compareTo(b.adoption));
      final bottom = sorted.take(2).map((e) => e.name).join(' and ');
      return '$bottom have the lowest adoption on the team and could use a short onboarding session.';
    }

    // --- Tool Comparison ---------------------------------------------------
    if (q.contains('copilot') && q.contains('claude')) {
      return 'GitHub Copilot: 34 users, 88% adoption, \$18.4K/mo. Claude: 21 users, 62% adoption, \$12.1K/mo. Copilot has broader reach; Claude usage is growing faster month over month.';
    }
    if (q.contains('chatgpt') && q.contains('claude')) {
      return 'ChatGPT Enterprise: 9 users, 31% adoption. Claude: 21 users, 62% adoption. Claude has more than double the active usage this month.';
    }
    if (q.contains('should we renew')) {
      return 'Copilot and Claude are the clearest renewals — both have strong, growing adoption. Gemini is the one to review before renewing.';
    }
    if (q.contains('cancel')) {
      return 'Gemini is the best candidate to scale back — only 9% adoption and trending down.';
    }
    if (q.contains('multiple tools') && q.contains('same purpose')) {
      return 'Yes — Copilot, Claude, and ChatGPT all overlap on code assistance. Consolidating to one primary tool could reduce redundant spend.';
    }

    // --- Risk & Anomalies ---------------------------------------------------
    if (q.contains('unusual') && q.contains('spending')) {
      return 'Nothing flagged as unusual this month — spend growth tracked closely with new seat additions.';
    }
    if (q.contains('unexpectedly high usage')) {
      return 'Claude usage jumped faster than expected this month (+9 users) — worth confirming those seats were approved.';
    }
    if (q.contains('duplicate') && q.contains('subscription')) {
      return 'No duplicate subscriptions detected across your team right now.';
    }
    if (q.contains('overspending')) {
      final pct = _totalSpend / _budget;
      return pct > 0.9
          ? '$_teamName is close to its budget ceiling at ${(pct * 100).toInt()}% used — worth a check before month end.'
          : '$_teamName isn\'t overspending — currently at ${(pct * 100).toInt()}% of budget.';
    }
    if (q.contains('biggest') && q.contains('risk')) {
      return 'The biggest risk right now is underused Gemini licenses (9% adoption) still costing \$${compact(4100)}/mo.';
    }

    // --- Productivity / ROI ---------------------------------------------------
    if (q.contains('improving productivity') || (q.contains('spending') && q.contains('productivity'))) {
      return 'Yes — productivity is up ${(_productivityGainPct * 100).toInt()}% alongside AI adoption growth this quarter.';
    }
    if (q.contains('roi') && q.contains('this month')) {
      return 'Team AI ROI score is $_roiScore/100 this month, driven mainly by Copilot usage.';
    }
    if (q.contains('highest roi')) {
      return 'GitHub Copilot has the highest ROI — strong adoption relative to its cost.';
    }
    if (q.contains('relationship between') && q.contains('productivity')) {
      return 'Sprints with higher Copilot/Claude adoption have shown faster PR turnaround — adoption and productivity are positively correlated so far.';
    }
    if (q.contains('after we introduced claude') || (q.contains('productivity') && q.contains('claude'))) {
      return 'Productivity ticked up modestly after Claude rollout, though Copilot remains the bigger driver.';
    }
    if (q.contains('without seeing enough value') || (q.contains('spending money') && q.contains('value'))) {
      return 'Gemini is the clearest example — \$${compact(4100)}/mo for only 9% adoption.';
    }

    // --- Original sprint/bug/PR fallbacks (kept from the existing mock) ---
    if (q.contains('bug')) {
      return 'You have 3 critical and 17 open bugs. Critical ones are all in api-service.';
    }
    if (q.contains('sprint') || q.contains('velocity')) {
      return 'Sprint 14 is at 68% (27 of 40 points) with 4 days left. Velocity is down 12% versus recent sprints.';
    }
    if (q.contains('pr') || q.contains('review')) {
      return 'There are 3 pending PR reviews. The oldest, from Sara, has been open for over a day.';
    }

    return 'I can help with AI tool usage, spend & budget, team performance, tool comparisons, risks, or ROI for your team — what would you like to check?';
  }
}