// ceo_blog_insights_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';

enum InsightCategory { budget, aiTrends, security, productivity }

class BlogInsightData {
  const BlogInsightData({
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.readTime,
    required this.icon,
    this.dateLabel = 'This week',
  });

  final String title;
  final String summary;
  final String body;
  final InsightCategory category;
  final String readTime;
  final IconData icon;
  final String dateLabel;
}

const List<BlogInsightData> kBlogInsights = [
  BlogInsightData(
    title: 'Keeping AI spend inside budget as usage scales',
    summary:
        'Five practical controls — seat audits, usage tiers, and spend caps — that keep AI tool costs predictable as more teams adopt them.',
    body:
        'As departments adopt more AI tools, spend tends to creep up quietly through unused seats, duplicate subscriptions, and ad-hoc '
        'upgrades approved outside the usual budget cycle. The most effective companies treat AI spend like cloud spend: they set a monthly '
        'cap per department, review seat utilization every 30 days, and require sign-off above a fixed threshold. Pairing a hard budget cap '
        'with a lightweight approval workflow — rather than blocking purchases outright — keeps teams moving fast while giving finance a '
        'clear audit trail. Reviewing unused-license reports monthly alone typically recovers 10-15% of AI spend without cutting any '
        'active usage.',
    category: InsightCategory.budget,
    readTime: '4 min read',
    icon: Icons.account_balance_wallet_rounded,
  ),
  BlogInsightData(
    title: 'Where current AI development spend is actually going',
    summary:
        'A breakdown of how engineering, sales, and support teams are allocating AI budget in 2026 — and where overlap quietly wastes money.',
    body:
        'Engineering teams are the heaviest AI spenders today, largely driven by code-assistant seats and inference costs for internal '
        'tooling. Sales and support are close behind, mostly through enterprise chat-assistant licenses. The biggest source of waste isn\'t '
        'any single tool — it\'s overlap: multiple departments independently licensing similar writing or coding assistants because there\'s '
        'no shared visibility into what other teams already pay for. Centralizing tool requests through one intake process, even informally, '
        'is consistently the fastest way to spot and eliminate duplicate spend.',
    category: InsightCategory.aiTrends,
    readTime: '5 min read',
    icon: Icons.trending_up_rounded,
  ),
  BlogInsightData(
    title: 'A lightweight framework for AI vendor risk review',
    summary:
        'Not every new AI tool needs a full security review — here\'s how to triage requests by data sensitivity and spend size.',
    body:
        'Full vendor security reviews don\'t scale when every team wants to try a new AI tool. A simpler triage works well in practice: '
        'tools that touch customer data or exceed a set monthly cost get a full review; everything else gets a lightweight checklist '
        'covering data retention, SSO support, and export controls. This keeps genuine risk under control without turning every '
        'small trial into a weeks-long approval process.',
    category: InsightCategory.security,
    readTime: '3 min read',
    icon: Icons.shield_rounded,
  ),
  BlogInsightData(
    title: 'Turning AI adoption numbers into productivity signal',
    summary:
        'Seat counts and login frequency don\'t tell you if AI tools are actually helping. Here\'s what to track instead.',
    body:
        'Adoption percentage is a vanity metric on its own — a team can have 90% adoption and still be using a tool for one trivial task '
        'a week. Better signals are task-completion time, ticket or PR throughput per person, and whether usage is sustained month over '
        'month rather than spiking after a training session and fading out. Tracking a small number of outcome metrics per department, '
        'instead of raw usage, gives a much clearer read on ROI when it\'s time to renew or cut a license.',
    category: InsightCategory.productivity,
    readTime: '4 min read',
    icon: Icons.bolt_rounded,
  ),
];

class CeoBlogInsightsScreen extends StatefulWidget {
  const CeoBlogInsightsScreen({super.key});

  @override
  State<CeoBlogInsightsScreen> createState() => _CeoBlogInsightsScreenState();
}

class _CeoBlogInsightsScreenState extends State<CeoBlogInsightsScreen> {
  InsightCategory? _filter;

  String _labelFor(InsightCategory c) {
    switch (c) {
      case InsightCategory.budget:
        return 'Budget';
      case InsightCategory.aiTrends:
        return 'AI Trends';
      case InsightCategory.security:
        return 'Security';
      case InsightCategory.productivity:
        return 'Productivity';
    }
  }

  Color _colorFor(AppColorsData colors, InsightCategory c) {
    switch (c) {
      case InsightCategory.budget:
        return colors.primary;
      case InsightCategory.aiTrends:
        return colors.success;
      case InsightCategory.security:
        return colors.info;
      case InsightCategory.productivity:
        return colors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = _filter == null
        ? kBlogInsights
        : kBlogInsights.where((i) => i.category == _filter).toList();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Blog & Insights')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
        children: [
          Text('AI budget & strategy reads',
              style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: 2),
          Text('Short, practical pieces on running AI spend responsibly',
              style: AppTypography.caption(colors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _filter == null,
                  color: colors.primary,
                  onTap: () => setState(() => _filter = null),
                ),
                for (final c in InsightCategory.values) ...[
                  const SizedBox(width: AppSpacing.sm),
                  _FilterChip(
                    label: _labelFor(c),
                    selected: _filter == c,
                    color: _colorFor(colors, c),
                    onTap: () => setState(() => _filter = c),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final insight in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _InsightArticleCard(
                data: insight,
                accent: _colorFor(colors, insight.category),
                categoryLabel: _labelFor(insight.category),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: selected ? color.withValues(alpha: 0.4) : colors.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.caption(selected ? color : colors.textSecondary)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _InsightArticleCard extends StatefulWidget {
  const _InsightArticleCard({
    required this.data,
    required this.accent,
    required this.categoryLabel,
  });

  final BlogInsightData data;
  final Color accent;
  final String categoryLabel;

  @override
  State<_InsightArticleCard> createState() => _InsightArticleCardState();
}

class _InsightArticleCardState extends State<_InsightArticleCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final d = widget.data;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(d.icon, color: widget.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: widget.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(widget.categoryLabel,
                              style: AppTypography.caption(widget.accent)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        Text(d.dateLabel,
                            style:
                                AppTypography.caption(colors.textSecondary)),
                        const Spacer(),
                        Text(d.readTime,
                            style:
                                AppTypography.caption(colors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(d.title,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _expanded ? d.body : d.summary,
            style: AppTypography.caption(colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded ? 'Show less' : 'Read more',
                style: AppTypography.caption(widget.accent)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
