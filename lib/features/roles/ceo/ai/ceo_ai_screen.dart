import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_ai_cubit.dart';
import 'ceo_ai_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../../../shared/widgets/segmented_toggle.dart';
import '../../../../shared/widgets/chat_bubble.dart';
import '../../../../shared/widgets/typing_indicator.dart';
import '../../../../shared/widgets/insight_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

/// CEO · AI — Chat Assistant with typing indicator + suggested quick-reply
/// chips, and an Insights sub-view, switched via a segmented toggle.
///
/// Only changes vs. original (cubit/state/colors untouched):
///  - _send() now guards against sending an empty/whitespace-only message.
///  - Quick-reply chip labels get maxLines/ellipsis so a longer suggestion
///    can't overflow the 36px-tall chip row on narrow screens.
///  - Bottom input row is wrapped in SafeArea so it doesn't sit under the
///    home-indicator on notched phones.
class CeoAiScreen extends StatelessWidget {
  const CeoAiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoAiCubit(CeoMockRepository()),
      child: const _CeoAiView(),
    );
  }
}

class _CeoAiView extends StatefulWidget {
  const _CeoAiView();
  @override
  State<_CeoAiView> createState() => _CeoAiViewState();
}

class _CeoAiViewState extends State<_CeoAiView> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  static const _quickReplies = [
    'Why is Engineering up?',
    'Where can we save?',
    'What\'s our budget forecast?',
  ];

  void _send(BuildContext context, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    context.read<CeoAiCubit>().sendMessage(trimmed);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  backgroundColor: context.appColors.primaryLight,
                  child: const Icon(Icons.auto_awesome,
                      color: AppColors.primary, size: 18),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.scaffoldBackgroundColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('AI Copilot'),
          ],
        ),
      ),
      body: GlowBackground(
        child: BlocBuilder<CeoAiCubit, CeoAiState>(
          builder: (context, state) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                      AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
                  child: SegmentedToggle(
                    options: const ['Chat', 'Insights'],
                    selectedIndex: state.viewIndex,
                    onChanged: (i) => context.read<CeoAiCubit>().setView(i),
                  ),
                ),
                Expanded(
                    child: state.viewIndex == 0
                        ? _buildChat(context, state)
                        : _buildInsights(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChat(BuildContext context, CeoAiState state) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl, vertical: AppSpacing.md),
            itemCount: state.messages.length + (state.isTyping ? 1 : 0),
            itemBuilder: (context, i) {
              if (i == state.messages.length) {
                return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: TypingIndicator()));
              }
              return ChatBubble(message: state.messages[i]);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _quickReplies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ActionChip(
                label: Text(
                  _quickReplies[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _send(context, _quickReplies[i]),
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                        hintText: 'Ask about spend, vendors, budgets...'),
                    onSubmitted: (text) => _send(context, text),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  style:
                      IconButton.styleFrom(backgroundColor: AppColors.primary),
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: () => _send(context, _textController.text),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsights(BuildContext context, CeoAiState state) {
    if (state.insightsLoading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: const [
          SkeletonLoader(height: 80),
          SizedBox(height: 12),
          SkeletonLoader(height: 80),
          SizedBox(height: 12),
          SkeletonLoader(height: 80)
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: state.insights
          .map((i) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: InsightCard(insight: i)))
          .toList(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
