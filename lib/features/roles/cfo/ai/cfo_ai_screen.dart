import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_ai_cubit.dart';

/// CFO · AI Copilot
/// Chat Assistant + AI Insights segmented view, wired to [CfoAiCubit].
class CfoAiScreen extends StatelessWidget {
  const CfoAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoAiCubit(),
      child: const _CfoAiView(),
    );
  }
}

class _CfoAiView extends StatelessWidget {
  const _CfoAiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Copilot')),
      body: SafeArea(
        child: BlocBuilder<CfoAiCubit, CfoAiState>(
          builder: (context, state) {
            if (state is CfoAiLoading || state is CfoAiInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoAiError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoAiCubit>().load(),
              );
            }

            final data = (state as CfoAiLoaded).data;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: _TabSwitcher(activeTab: data.activeTab),
                ),
                Expanded(
                  child: data.activeTab == CfoAiTab.chat
                      ? _ChatView(data: data)
                      : _InsightsView(insights: data.insights),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Tab switcher
/// ---------------------------------------------------------------------

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({required this.activeTab});

  final CfoAiTab activeTab;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<CfoAiTab>(
      segments: const [
        ButtonSegment(value: CfoAiTab.chat, label: Text('Chat assistant'), icon: Icon(Icons.chat_bubble_outline)),
        ButtonSegment(value: CfoAiTab.insights, label: Text('AI insights'), icon: Icon(Icons.insights_outlined)),
      ],
      selected: {activeTab},
      onSelectionChanged: (selection) => context.read<CfoAiCubit>().switchTab(selection.first),
      showSelectedIcon: false,
    );
  }
}

/// ---------------------------------------------------------------------
/// Chat view
/// ---------------------------------------------------------------------

class _ChatView extends StatefulWidget {
  const _ChatView({required this.data});

  final CfoAiData data;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.messages.length != widget.data.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    _controller.clear();
    context.read<CfoAiCubit>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: widget.data.messages.length + (widget.data.isAssistantTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == widget.data.messages.length) {
                return const _TypingBubble();
              }
              return _ChatBubble(message: widget.data.messages[index]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Ask about cash flow, spend, or budgets…',
                  ),
                  onSubmitted: (_) => _send(),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                onPressed: _send,
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.sender == ChatSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 32,
          height: 16,
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Insights view
/// ---------------------------------------------------------------------

class _InsightsView extends StatelessWidget {
  const _InsightsView({required this.insights});

  final List<AiInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Center(child: Text('No insights yet.', style: Theme.of(context).textTheme.bodyMedium));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: insights.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => AppCard(child: _InsightTile(insight: insights[index])),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({required this.insight});

  final AiInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (icon, color) = switch (insight.severity) {
      InsightSeverity.warning => (Icons.warning_amber_outlined, Colors.amber.shade700),
      InsightSeverity.positive => (Icons.trending_up, Colors.green.shade600),
      InsightSeverity.info => (Icons.lightbulb_outline, theme.colorScheme.primary),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(insight.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(insight.description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Error state
/// ---------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}