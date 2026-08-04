import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'engineering_manager_ai_cubit.dart';

/// Engineering Manager · AI Copilot
/// Chat Assistant + AI Insights segmented view.
class EngineeringManagerAiScreen extends StatelessWidget {
  const EngineeringManagerAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerAiCubit()..loadInsights(),
      child: const _EngineeringManagerAiView(),
    );
  }
}

class _EngineeringManagerAiView extends StatefulWidget {
  const _EngineeringManagerAiView();

  @override
  State<_EngineeringManagerAiView> createState() => _EngineeringManagerAiViewState();
}

class _EngineeringManagerAiViewState extends State<_EngineeringManagerAiView> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Copilot')),
      body: SafeArea(
        child: BlocConsumer<EngineeringManagerAiCubit, EngineeringManagerAiState>(
          listener: (context, state) {
            if (state is EngineeringManagerAiLoaded) _scrollToBottom();
          },
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerAiInitial() ||
              EngineeringManagerAiLoading() =>
                const Center(child: CircularProgressIndicator()),
              EngineeringManagerAiError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<EngineeringManagerAiCubit>().loadInsights(),
                ),
              EngineeringManagerAiLoaded(:final data) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                      child: _SegmentToggle(
                        selected: data.selectedSegment,
                        onChanged: (segment) =>
                            context.read<EngineeringManagerAiCubit>().switchSegment(segment),
                      ),
                    ),
                    Expanded(
                      child: data.selectedSegment == AiSegment.chat
                          ? _ChatView(data: data, scrollController: _scrollController)
                          : _InsightsView(insights: data.insights),
                    ),
                    if (data.selectedSegment == AiSegment.chat)
                      _ChatInputBar(
                        controller: _inputController,
                        onSend: (text) {
                          context.read<EngineeringManagerAiCubit>().sendMessage(text);
                          _inputController.clear();
                        },
                      ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({required this.selected, required this.onChanged});

  final AiSegment selected;
  final ValueChanged<AiSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Chat assistant',
              selected: selected == AiSegment.chat,
              onTap: () => onChanged(AiSegment.chat),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'AI insights',
              selected: selected == AiSegment.insights,
              onTap: () => onChanged(AiSegment.insights),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatelessWidget {
  const _ChatView({required this.data, required this.scrollController});

  final EngineeringManagerAiData data;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: data.messages.length + (data.isAiTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= data.messages.length) {
          return const _TypingBubble();
        }
        return _ChatBubble(message: data.messages[index]);
      },
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isFromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
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
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.sm + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Ask about sprint, bugs, or PRs',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton.filled(
            onPressed: () => onSend(controller.text),
            icon: const Icon(Icons.arrow_upward),
          ),
        ],
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({required this.insights});

  final List<AiInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const _EmptyView(
        title: 'No insights yet',
        message: 'Check back once the team has more sprint activity.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: insights.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final insight = insights[index];
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: insight.severity.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(insight.severity.icon, size: 20, color: insight.severity.foreground),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: insight.severity.foreground,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      insight.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: insight.severity.foreground,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load AI Copilot', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}