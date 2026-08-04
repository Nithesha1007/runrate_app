import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import 'org_admin_ai_cubit.dart';

/// Org Admin · AI Copilot
/// Chat Assistant + AI Insights segmented view. Wired to
/// [OrgAdminAiCubit].
class OrgAdminAiScreen extends StatelessWidget {
  const OrgAdminAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgAdminAiCubit()..loadInsights(),
      child: const _OrgAdminAiView(),
    );
  }
}

class _OrgAdminAiView extends StatelessWidget {
  const _OrgAdminAiView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Admin · AI Copilot')),
      body: SafeArea(
        child: BlocBuilder<OrgAdminAiCubit, OrgAdminAiState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: SegmentedButton<AiSegment>(
                    segments: const [
                      ButtonSegment(
                        value: AiSegment.chat,
                        label: Text('Chat assistant'),
                        icon: Icon(Icons.chat_bubble_outline),
                      ),
                      ButtonSegment(
                        value: AiSegment.insights,
                        label: Text('AI insights'),
                        icon: Icon(Icons.insights_outlined),
                      ),
                    ],
                    selected: {state.segment},
                    onSelectionChanged: (selection) =>
                        context.read<OrgAdminAiCubit>().switchSegment(selection.first),
                  ),
                ),
                Expanded(
                  child: state.segment == AiSegment.chat
                      ? const _ChatView()
                      : _InsightsView(state: state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView();

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(BuildContext context, String value) {
    if (value.trim().isEmpty) return;
    context.read<OrgAdminAiCubit>().sendMessage(value);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrgAdminAiCubit, OrgAdminAiState>(
      builder: (context, state) {
        return Column(
          children: [
            Expanded(
              child: state.messages.isEmpty
                  ? const EmptyState(
                      title: 'Ask your AI copilot',
                      message: 'Ask about spend, approvals, or team activity to get started.',
                      icon: Icons.smart_toy_outlined,
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        final isAdmin = message.sender == ChatSender.admin;
                        return Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.75,
                            ),
                            decoration: BoxDecoration(
                              color: isAdmin
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(message.text),
                          ),
                        );
                      },
                    ),
            ),
            if (state.isSending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask the AI copilot...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) => _send(context, value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: () => _send(context, _controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({required this.state});

  final OrgAdminAiState state;

  Color _severityColor(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Colors.blue;
      case InsightSeverity.warning:
        return Colors.orange;
      case InsightSeverity.critical:
        return Colors.red;
    }
  }

  IconData _severityIcon(InsightSeverity severity) {
    switch (severity) {
      case InsightSeverity.info:
        return Icons.info_outline;
      case InsightSeverity.warning:
        return Icons.warning_amber_outlined;
      case InsightSeverity.critical:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state.status == OrgAdminAiStatus.loading || state.status == OrgAdminAiStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == OrgAdminAiStatus.error) {
      return Center(child: Text(state.errorMessage ?? 'Something went wrong.'));
    }
    if (state.insights.isEmpty) {
      return const EmptyState(
        title: 'No insights yet',
        message: 'AI-generated insights about your organization will show up here.',
        icon: Icons.insights_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<OrgAdminAiCubit>().loadInsights(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.xl),
        itemCount: state.insights.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final insight = state.insights[index];
          return AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_severityIcon(insight.severity), color: _severityColor(insight.severity)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.title, style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(insight.summary, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}