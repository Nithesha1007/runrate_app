// engineering_manager_ai_screen.dart
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/shared/widgets/chat_bubble.dart';
import 'package:runrate/features/roles/engineering_manager/ai/engineering_manager_aistate.dart';
import 'engineering_manager_ai_cubit.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../../../shared/widgets/app_card.dart';

import '../../../../shared/widgets/typing_indicator.dart';

/// Engineering Manager · AI Copilot — same layout/animations as the CEO
/// AI screen (hamburger sidebar with New Chat + history, minimal header
/// with rotating glow avatar, daily briefing card, empty-state greeting
/// with category-grouped suggested questions, animated chat bubbles, and
/// a pinned input bar with a black "+" attach menu).
///
/// Two additions on top of the base layout:
///  - Suggested questions on the empty state now render as a fixed 2x2
///    grid with full, untruncated text instead of a free-flowing Wrap of
///    ellipsis-cut chips.
///  - A small "New Chat" bar is pinned directly above the message list
///    whenever a conversation is active, so starting fresh doesn't
///    require opening the hamburger sidebar.
class EngineeringManagerAiScreen extends StatelessWidget {
  const EngineeringManagerAiScreen({super.key, this.userName = 'Priya'});

 
  final String userName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerAiCubit(),
      child: _EmAiView(userName: userName),
    );
  }
}

class _EmAiView extends StatefulWidget {
  const _EmAiView({required this.userName});
  final String userName;

  @override
  State<_EmAiView> createState() => _EmAiViewState();
}

class _EmAiViewState extends State<_EmAiView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void _send(BuildContext context, String text) {
    final cubit = context.read<EngineeringManagerAiCubit>();
    final trimmed = text.trim();
    if (trimmed.isEmpty && cubit.state.pendingAttachmentName == null) return;
    cubit.sendMessage(trimmed);
    _textController.clear();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(BuildContext context) async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    context.read<EngineeringManagerAiCubit>().attachFile(result.files.single.name);
  }

  Future<void> _pickPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    context.read<EngineeringManagerAiCubit>().attachFile(result.files.single.name);
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'csv',
        'xlsx'
      ],
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    context.read<EngineeringManagerAiCubit>().attachFile(result.files.single.name);
  }

  void _showAttachMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AttachMenuSheet(
        onImage: () {
          Navigator.pop(sheetContext);
          _pickImage(context);
        },
        onPdf: () {
          Navigator.pop(sheetContext);
          _pickPdf(context);
        },
        onFile: () {
          Navigator.pop(sheetContext);
          _pickFile(context);
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          child: BlocBuilder<EngineeringManagerAiCubit, EngineeringManagerAiState>(
            builder: (context, state) {
              final showEmptyState = state.messages.isEmpty;
              return Stack(
                children: [
                  Column(
                    children: [
                      _AiHeaderBar(
                        onMenuTap: () =>
                            context.read<EngineeringManagerAiCubit>().openSidebar(),
                        onNewChat: () =>
                            context.read<EngineeringManagerAiCubit>().startNewChat(),
                      ),
                      if (state.briefing != null &&
                          !state.briefingLoading &&
                          !showEmptyState)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                          child: _BriefingCard(
                              briefing: state.briefing, loading: false),
                        ),
                      // NEW — quick "New Chat" bar pinned above the message
                      // list whenever a conversation is active.
                      if (!showEmptyState)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
                          child: _NewChatBar(
                            onTap: () => context
                                .read<EngineeringManagerAiCubit>()
                                .startNewChat(),
                          ),
                        ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: showEmptyState
                              ? _EmptyStateChat(
                                  key: const ValueKey('empty'),
                                  userName: widget.userName,
                                  onPrompt: (text) => _send(context, text),
                                )
                              : _MessageList(
                                  key: const ValueKey('chat'),
                                  state: state,
                                  scrollController: _scrollController,
                                ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                        child: _AiInputBar(
                          textController: _textController,
                          attachedFileName: state.pendingAttachmentName,
                          onSend: (text) => _send(context, text),
                          onAttachTap: () => _showAttachMenu(context),
                          onRemoveAttachment: () => context
                              .read<EngineeringManagerAiCubit>()
                              .removeAttachment(),
                          onMicTap: () =>
                              _showComingSoon(context, 'Voice input'),
                        ),
                      ),
                    ],
                  ),
                  if (state.sidebarOpen)
                    GestureDetector(
                      onTap: () =>
                          context.read<EngineeringManagerAiCubit>().closeSidebar(),
                      child: AnimatedOpacity(
                        opacity: state.sidebarOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                            color: Colors.black.withValues(alpha: 0.35)),
                      ),
                    ),
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    top: 0,
                    bottom: 0,
                    left: state.sidebarOpen ? 0 : -300,
                    width: 280,
                    child: _HistorySidebar(state: state),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER — identical pattern to CEO: hamburger + glow avatar/title on the
// left, quick "+" new-chat icon on the right.
// ---------------------------------------------------------------------------
class _AiHeaderBar extends StatelessWidget {
  const _AiHeaderBar({required this.onMenuTap, required this.onNewChat});

  final VoidCallback onMenuTap;
  final VoidCallback onNewChat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: const Icon(Icons.menu_rounded),
          ),
          const _GlowAvatar(),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Copilot',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text('AI Assistant',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onNewChat,
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'New chat',
          ),
        ],
      ),
    );
  }
}

class _GlowAvatar extends StatefulWidget {
  const _GlowAvatar();

  @override
  State<_GlowAvatar> createState() => _GlowAvatarState();
}

class _GlowAvatarState extends State<_GlowAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) => Transform.rotate(
              angle: _controller.value * 2 * math.pi,
              child: child,
            ),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(colors: [
                  AppColors.primary.withValues(alpha: 0.05),
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.05),
                ]),
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appColors.primaryLight,
            ),
            child: const Icon(Icons.auto_awesome,
                color: AppColors.primary, size: 15),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NEW CHAT BAR — pinned above the message list once a conversation is
// active, so the user has a fast way to start fresh without opening the
// hamburger sidebar.
// ---------------------------------------------------------------------------
class _NewChatBar extends StatelessWidget {
  const _NewChatBar({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.appColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_comment_outlined,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text('New Chat',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SIDEBAR — identical mechanics to CEO's history sidebar.
// ---------------------------------------------------------------------------
class _HistorySidebar extends StatelessWidget {
  const _HistorySidebar({required this.state});
  final EngineeringManagerAiState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      child: Container(
        color: theme.colorScheme.surface,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                child: _ScaleOnTap(
                  onTap: () =>
                      context.read<EngineeringManagerAiCubit>().startNewChat(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('New Chat',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                child: Text('RECENT',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.6)),
              ),
              Expanded(
                child: state.sessions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text('No conversations yet',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        itemCount: state.sessions.length,
                        itemBuilder: (context, i) {
                          final s = state.sessions[i];
                          final selected = s.id == state.activeSessionId;
                          return _ScaleOnTap(
                            onTap: () => context
                                .read<EngineeringManagerAiCubit>()
                                .selectSession(s.id),
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.sm),
                              decoration: BoxDecoration(
                                color: selected
                                    ? context.appColors.primaryLight
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                      color: selected
                                          ? AppColors.primary
                                          : theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: selected
                                                  ? AppColors.primary
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: selected
                                                  ? FontWeight.w600
                                                  : FontWeight.w400),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY STATE — greeting + category-grouped suggested questions.
// ---------------------------------------------------------------------------
class _Question {
  const _Question(this.text);
  final String text;
}

class _QuestionCategory {
  const _QuestionCategory(this.label, this.icon, this.questions);
  final String label;
  final IconData icon;
  final List<_Question> questions;
}

const _questionCategories = [
  _QuestionCategory(
    'AI Usage',
    Icons.apps_rounded,
    [
      _Question('Which AI tools are most used by my team?'),
      _Question('Who are the highest and lowest AI adopters in my team?'),
      _Question('How has AI adoption changed this month?'),
      _Question('Which AI tools are underutilized?'),
      _Question('Are we paying for AI licenses that nobody is using?'),
      _Question('Which tool gives us the best value for money?'),
    ],
  ),
  _QuestionCategory(
    'Spend & Budget',
    Icons.attach_money_rounded,
    [
      _Question('How much did my team spend on AI this month?'),
      _Question('Are we on track with our AI budget?'),
      _Question('Which AI tool is costing us the most?'),
      _Question('Why did our AI spending increase this month?'),
      _Question('How much can we save by removing unused licenses?'),
      _Question('What will our AI spend look like next month?'),
    ],
  ),
  _QuestionCategory(
    'Team Performance',
    Icons.groups_rounded,
    [
      _Question('How is my team\'s AI adoption compared with last month?'),
      _Question('Which team members are not using their assigned AI tools?'),
      _Question('Which teams are getting the most value from AI?'),
      _Question('Is AI adoption improving team productivity?'),
      _Question('Which engineers may need help adopting AI tools?'),
    ],
  ),
  _QuestionCategory(
    'Tool Comparison',
    Icons.compare_arrows_rounded,
    [
      _Question('Compare GitHub Copilot vs Claude for my team.'),
      _Question('Compare ChatGPT and Claude usage this month.'),
      _Question('Which AI tool should we renew?'),
      _Question('Which AI subscriptions should we cancel?'),
      _Question('Are we using multiple tools for the same purpose?'),
    ],
  ),
  _QuestionCategory(
    'Risk & Anomalies',
    Icons.warning_amber_rounded,
    [
      _Question('Did any unusual AI spending happen this month?'),
      _Question('Which AI subscription has unexpectedly high usage?'),
      _Question('Are there duplicate AI subscriptions across my team?'),
      _Question('Which department or team is overspending?'),
      _Question('What are the biggest AI spending risks right now?'),
    ],
  ),
  _QuestionCategory(
    'Productivity/ROI',
    Icons.trending_up_rounded,
    [
      _Question('Is our AI spending actually improving productivity?'),
      _Question('What is our AI ROI this month?'),
      _Question('Which AI tool has the highest ROI?'),
      _Question('Show me the relationship between AI adoption and productivity.'),
      _Question('Did productivity increase after we introduced Claude?'),
      _Question('Where are we spending money without seeing enough value?'),
    ],
  ),
];

class _EmptyStateChat extends StatelessWidget {
  const _EmptyStateChat(
      {super.key, required this.userName, required this.onPrompt});

  final String userName;
  final ValueChanged<String> onPrompt;

  /// Just 4 suggested chips — one pulled from 4 different categories so
  /// it stays varied without crowding the screen. The full question bank
  /// still lives in the cubit, so anything the user types (even questions
  /// not shown here) still gets a real, data-grounded answer.
  static final _visibleQuestions = [
    _questionCategories[0].questions[0], // AI Usage
    _questionCategories[1].questions[0], // Spend & Budget
    _questionCategories[4].questions[3], // Risk & Anomalies
    _questionCategories[5].questions[1], // Productivity/ROI
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          _FadeSlideIn(
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                    children: [
                      TextSpan(text: 'Hello, $userName '),
                      const TextSpan(text: '👋'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text('How can I help you today?',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          // 2 rows x 2 columns — full question text, no truncation.
          LayoutBuilder(
            builder: (context, constraints) {
              final columnWidth =
                  (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: List.generate(_visibleQuestions.length, (i) {
                  final q = _visibleQuestions[i];
                  return _FadeSlideIn(
                    delay: Duration(milliseconds: 100 + i * 60),
                    child: SizedBox(
                      width: columnWidth,
                      child: _SuggestedChip(
                        label: q.text,
                        onTap: () => onPrompt(q.text),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SuggestedChip extends StatelessWidget {
  const _SuggestedChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: context.appColors.primaryLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          // No maxLines / ellipsis — full question text always shown,
          // the chip grows taller to fit instead of truncating.
          style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.primary, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MESSAGE LIST
// ---------------------------------------------------------------------------
class _MessageList extends StatelessWidget {
  const _MessageList(
      {super.key, required this.state, required this.scrollController});

  final EngineeringManagerAiState state;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      itemCount: state.messages.length + (state.isTyping ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == state.messages.length) {
          return const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: TypingIndicator()));
        }
        final message = state.messages[i];
        return _MessageEntrance(
          key: ValueKey(message.id),
          child: ChatBubble(message: message),
        );
      },
    );
  }
}

class _MessageEntrance extends StatelessWidget {
  const _MessageEntrance({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.translate(
            offset: Offset(0, (1 - clamped) * 10),
            child: Transform.scale(
              scale: 0.94 + (0.06 * value.clamp(0.0, 1.0)),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED INPUT BAR
// ---------------------------------------------------------------------------
class _AiInputBar extends StatelessWidget {
  const _AiInputBar({
    required this.textController,
    required this.attachedFileName,
    required this.onSend,
    required this.onAttachTap,
    required this.onRemoveAttachment,
    required this.onMicTap,
  });

  final TextEditingController textController;
  final String? attachedFileName;
  final ValueChanged<String> onSend;
  final VoidCallback onAttachTap;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onMicTap;

  @override
  Widget build(BuildContext context) {
    return _AiInputBarBody(
      textController: textController,
      attachedFileName: attachedFileName,
      onSend: onSend,
      onAttachTap: onAttachTap,
      onRemoveAttachment: onRemoveAttachment,
      onMicTap: onMicTap,
    );
  }
}

class _AiInputBarBody extends StatefulWidget {
  const _AiInputBarBody({
    required this.textController,
    required this.attachedFileName,
    required this.onSend,
    required this.onAttachTap,
    required this.onRemoveAttachment,
    required this.onMicTap,
  });

  final TextEditingController textController;
  final String? attachedFileName;
  final ValueChanged<String> onSend;
  final VoidCallback onAttachTap;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onMicTap;

  @override
  State<_AiInputBarBody> createState() => _AiInputBarBodyState();
}

class _AiInputBarBodyState extends State<_AiInputBarBody> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_onChanged);
  }

  void _onChanged() {
    final hasText = widget.textController.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSend = _hasText || widget.attachedFileName != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: widget.attachedFileName == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) => Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.scale(
                            scale: 0.9 + 0.1 * value.clamp(0.0, 1.0),
                            child: child),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 6),
                          decoration: BoxDecoration(
                            color: context.appColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.attach_file_rounded,
                                  size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 160),
                                child: Text(
                                  widget.attachedFileName!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: widget.onRemoveAttachment,
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.close_rounded,
                                      size: 14, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          TextField(
            controller: widget.textController,
            maxLines: 3,
            minLines: 1,
            decoration: const InputDecoration(
              hintText: 'Ask about sprint, bugs, spend, or AI adoption...',
              border: InputBorder.none,
              isDense: true,
            ),
            onSubmitted: widget.onSend,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _AttachMenuButton(onTap: widget.onAttachTap),
              const Spacer(),
              IconButton(
                onPressed: widget.onMicTap,
                icon: Icon(Icons.mic_none_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
              ),
              _SendButton(
                active: canSend,
                onTap: () => widget.onSend(widget.textController.text),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AttachMenuButton extends StatelessWidget {
  const _AttachMenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
            color: Colors.black, shape: BoxShape.circle),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
    );
  }
}

class _AttachMenuSheet extends StatelessWidget {
  const _AttachMenuSheet({
    required this.onImage,
    required this.onPdf,
    required this.onFile,
  });

  final VoidCallback onImage;
  final VoidCallback onPdf;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            _AttachOptionTile(
                icon: Icons.image_rounded, label: 'Photo', onTap: onImage),
            _AttachOptionTile(
                icon: Icons.picture_as_pdf_rounded,
                label: 'PDF',
                onTap: onPdf),
            _AttachOptionTile(
                icon: Icons.folder_open_rounded,
                label: 'Browse files',
                onTap: onFile),
            const SizedBox(height: AppSpacing.xs),
          ],
        ),
      ),
    );
  }
}

class _AttachOptionTile extends StatelessWidget {
  const _AttachOptionTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: context.appColors.primaryLight,
                  shape: BoxShape.circle),
              child: Icon(icon, size: 17, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final glow = widget.active ? 0.18 + _pulse.value * 0.12 : 0.0;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: glow == 0
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: glow),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
          ),
          child: child,
        );
      },
      child: _ScaleOnTap(
        onTap: widget.active ? widget.onTap : () {},
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.active
                  ? [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.75)
                    ]
                  : [Colors.grey.shade300, Colors.grey.shade300],
            ),
          ),
          child: const Icon(Icons.arrow_upward_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.92),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});
  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final start = delay.inMilliseconds / (420 + delay.inMilliseconds);
        final adjusted =
            ((value - start) / (1 - start)).clamp(0.0, 1.0).toDouble();
        return Opacity(
          opacity: adjusted,
          child: Transform.translate(
            offset: Offset(0, (1 - adjusted) * 14),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Daily AI briefing banner shown at the top of an active conversation.
class _BriefingCard extends StatelessWidget {
  final String? briefing;
  final bool loading;
  const _BriefingCard({required this.briefing, required this.loading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.appColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.wb_sunny_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Briefing",
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(briefing ?? '', style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}