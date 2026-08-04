import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';

import 'employee_ai_cubit.dart';

TextStyle appFontStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

extension _EmployeeAiThemeExtensions on BuildContext {
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get mutedTextColor =>
      Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
  Color get cardColor => Theme.of(this).cardColor;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
}

/// Employee · AI Copilot
/// Chat Assistant + AI Insights segmented view.
class EmployeeAiScreen extends StatelessWidget {
  const EmployeeAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeAiCubit(),
      child: const _EmployeeAiView(),
    );
  }
}

class _EmployeeAiView extends StatelessWidget {
  const _EmployeeAiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldColor,
      appBar: AppBar(title: const Text('AI Copilot')),
      body: SafeArea(
        child: BlocBuilder<EmployeeAiCubit, EmployeeAiState>(
          builder: (context, state) {
            if (state.isLoading && state.messages.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == EmployeeAiStatus.error &&
                state.messages.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    0,
                  ),
                  child: _SegmentToggle(segment: state.segment),
                ),
                Expanded(
                  child: state.segment == AiSegment.chat
                      ? _ChatView(state: state)
                      : _InsightsView(insights: state.insights),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SegmentToggle extends StatelessWidget {
  const _SegmentToggle({required this.segment});

  final AiSegment segment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Chat assistant',
              selected: segment == AiSegment.chat,
              onTap: () =>
                  context.read<EmployeeAiCubit>().selectSegment(AiSegment.chat),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'AI insights',
              selected: segment == AiSegment.insights,
              onTap: () => context
                  .read<EmployeeAiCubit>()
                  .selectSegment(AiSegment.insights),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: appFontStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : context.mutedTextColor,
          ),
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.state});

  final EmployeeAiState state;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    context.read<EmployeeAiCubit>().sendMessage(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.state.messages;

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: messages.length + (widget.state.isSending ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= messages.length) {
                return const _TypingBubble();
              }
              return _ChatBubble(message: messages[index]);
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Ask AI Copilot...',
                      filled: true,
                      fillColor: context.cardColor,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Material(
                  color: context.primaryColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.state.isSending ? null : _send,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.arrow_upward,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatSender.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? context.primaryColor : context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.text,
          style: appFontStyle(
            fontSize: 13,
            color: isUser ? Colors.white : context.onSurfaceColor,
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.mutedTextColor,
          ),
        ),
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
      return const EmptyState(
        title: 'No insights yet',
        message: 'Check back after your team has more activity.',
        icon: Icons.auto_awesome_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: insights.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => _InsightCard(insight: insights[index]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final AiInsight insight;

  IconData get _icon {
    switch (insight.severity) {
      case InsightSeverity.warning:
        return Icons.warning_amber_rounded;
      case InsightSeverity.positive:
        return Icons.trending_up_rounded;
      case InsightSeverity.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _iconColor(BuildContext context) {
    switch (insight.severity) {
      case InsightSeverity.warning:
        return const Color(0xFFBA7517);
      case InsightSeverity.positive:
        return const Color(0xFF3B6D11);
      case InsightSeverity.info:
        return context.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, size: 20, color: _iconColor(context)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style:
                      appFontStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: appFontStyle(
                    fontSize: 12,
                    color: context.mutedTextColor,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
