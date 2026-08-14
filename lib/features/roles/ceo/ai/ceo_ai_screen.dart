// ceo_ai_screen.dart
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/shared/widgets/chat_bubble.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_ai_cubit.dart';
import 'ceo_ai_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/typing_indicator.dart';


/// CEO · AI Copilot — Claude-style layout: hamburger opens a left sidebar
/// with "New Chat" + past conversation history, header stays minimal, and
/// the chat itself supports attaching an image/PDF/file before sending via
/// a single black "+" button that opens a bottom-sheet menu.
class CeoAiScreen extends StatelessWidget {
 const CeoAiScreen({super.key, this.userName = 'Alex'});

  /// TODO: wire to the logged-in CEO's real first name once available.
  final String userName;
  
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoAiCubit(CeoMockRepository()),
      child: _CeoAiView(userName: userName),
    );
  }
}

class _CeoAiView extends StatefulWidget {
  const _CeoAiView({required this.userName});
  final String userName;

  @override
  State<_CeoAiView> createState() => _CeoAiViewState();
}

class _CeoAiViewState extends State<_CeoAiView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  void _send(BuildContext context, String text) {
    final cubit = context.read<CeoAiCubit>();
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
    context.read<CeoAiCubit>().attachFile(result.files.single.name);
  }

  Future<void> _pickPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;
    if (!context.mounted) return;
    context.read<CeoAiCubit>().attachFile(result.files.single.name);
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
    context.read<CeoAiCubit>().attachFile(result.files.single.name);
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
          child: BlocBuilder<CeoAiCubit, CeoAiState>(
            builder: (context, state) {
              final showEmptyState = state.messages.isEmpty;
              return Stack(
                children: [
                  Column(
                    children: [
                      _AiHeaderBar(
                        onMenuTap: () =>
                            context.read<CeoAiCubit>().openSidebar(),
                        onNewChat: () =>
                            context.read<CeoAiCubit>().startNewChat(),
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
                          onRemoveAttachment: () =>
                              context.read<CeoAiCubit>().removeAttachment(),
                          onMicTap: () =>
                              _showComingSoon(context, 'Voice input'),
                        ),
                      ),
                    ],
                  ),

                  // Dimmed barrier — tap outside the sidebar to close it.
                  if (state.sidebarOpen)
                    GestureDetector(
                      onTap: () => context.read<CeoAiCubit>().closeSidebar(),
                      child: AnimatedOpacity(
                        opacity: state.sidebarOpen ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Container(
                            color: Colors.black.withValues(alpha: 0.35)),
                      ),
                    ),

                  // Sliding sidebar itself.
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
// HEADER — hamburger (opens sidebar) + glow avatar/title on the left, a
// quick "+" new-chat icon on the right, matching Claude's dual entry points.
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
                Text('CEO AI Copilot',
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
// SIDEBAR — "New Chat" up top, past sessions below (including sessions
// created live during this app run — see CeoAiCubit), active one highlighted.
// ---------------------------------------------------------------------------
class _HistorySidebar extends StatelessWidget {
  const _HistorySidebar({required this.state});
  final CeoAiState state;

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
                  onTap: () => context.read<CeoAiCubit>().startNewChat(),
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
                            onTap: () =>
                                context.read<CeoAiCubit>().selectSession(s.id),
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
// EMPTY STATE — greeting + suggested-question chips (no input bar here
// anymore — the input bar is now pinned once at the screen bottom, shared
// by empty state and active chat, so it never duplicates or jumps).
// ---------------------------------------------------------------------------
class _SuggestedQuestion {
  const _SuggestedQuestion(this.icon, this.label, this.prompt);
  final IconData icon;
  final String label;
  final String prompt;
}

const _suggestedQuestions = [
  _SuggestedQuestion(Icons.apartment_rounded, 'Company Summary',
      'Give me a summary of company-wide AI spend and adoption'),
  _SuggestedQuestion(Icons.attach_money_rounded, 'AI Budget',
      'How is our AI budget tracking this quarter?'),
  _SuggestedQuestion(
      Icons.trending_up_rounded, 'AI ROI', 'What is our current AI ROI?'),
  _SuggestedQuestion(Icons.groups_rounded, 'Compare Departments',
      'Compare AI spend and adoption across departments'),
  _SuggestedQuestion(Icons.task_alt_rounded, 'Pending Approvals',
      'What approvals are waiting on me right now?'),
  _SuggestedQuestion(
      Icons.sell_rounded, 'Cost Savings', 'Where can we cut AI tooling costs?'),
];

class _EmptyStateChat extends StatelessWidget {
  const _EmptyStateChat(
      {super.key, required this.userName, required this.onPrompt});

  final String userName;
  final ValueChanged<String> onPrompt;

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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            alignment: WrapAlignment.center,
            children: List.generate(_suggestedQuestions.length, (i) {
              final q = _suggestedQuestions[i];
              return _FadeSlideIn(
                delay: Duration(milliseconds: 120 + i * 60),
                child: _SuggestedChip(
                  icon: q.icon,
                  label: q.label,
                  onTap: () => onPrompt(q.prompt),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _SuggestedChip extends StatelessWidget {
  const _SuggestedChip(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: context.appColors.primaryLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MESSAGE LIST — each bubble animates in with fade + slight rise + scale.
// ---------------------------------------------------------------------------
class _MessageList extends StatelessWidget {
  const _MessageList(
      {super.key, required this.state, required this.scrollController});

  final CeoAiState state;
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
  child: ChatBubble(message: message),   // <- already wired
);

      },
    );
  }
}

/// Wraps a chat bubble in a one-time fade + rise + scale entrance so new
/// messages feel alive instead of just popping in.
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
// SHARED INPUT BAR — a single black "+" opens an attach menu (image / PDF /
// file). Attachment chip animates in above the text field, gradient send
// button pulses once there's something to send.
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
          // Animated attachment chip — grows in above the text field.
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
              hintText: 'Ask anything...',
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

/// Single black round "+" button that opens the attach bottom sheet.
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

/// Bottom-sheet menu shown when the "+" button is tapped: Photo / PDF / Browse.
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