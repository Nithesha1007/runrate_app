// ceo_blog_insights_screen.dart
//
// v2 — visual pass:
//   • Each insight now carries a themed cover image (Unsplash), with a
//     graceful gradient+icon fallback via errorBuilder if the network image
//     fails to load — same pattern already used for department avatars in
//     ceo_home_screen.dart, so no new dependencies.
//   • Collapsing SliverAppBar with a soft gradient backdrop instead of a
//     flat AppBar, matching the hero-card language used elsewhere in the
//     CEO surface.
//   • The first (most relevant) insight renders as a large featured card
//     with a full-bleed image and gradient-scrim title overlay; the rest
//     render as compact list cards with a square thumbnail.
//   • Added a lightweight bookmark toggle per card (local state only — no
//     persistence layer exists yet) and a staggered fade/slide-in on load.
//   • Category filter chips now show a live count per category.

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
    required this.imageUrl,
    this.dateLabel = 'This week',
  });

  final String title;
  final String summary;
  final String body;
  final InsightCategory category;
  final String readTime;
  final IconData icon;
  final String imageUrl;
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
    imageUrl:
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=900&h=600&fit=crop&auto=format',
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
    imageUrl:
        'https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=900&h=600&fit=crop&auto=format',
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
    imageUrl:
        'https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=900&h=600&fit=crop&auto=format',
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
    imageUrl:
        'https://images.unsplash.com/photo-1552664730-d307ca884978?w=900&h=600&fit=crop&auto=format',
  ),
];

class CeoBlogInsightsScreen extends StatefulWidget {
  const CeoBlogInsightsScreen({super.key});

  @override
  State<CeoBlogInsightsScreen> createState() => _CeoBlogInsightsScreenState();
}

class _CeoBlogInsightsScreenState extends State<CeoBlogInsightsScreen> {
  InsightCategory? _filter;
  final Set<String> _bookmarked = {};

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

  void _toggleBookmark(String title) {
    setState(() {
      if (_bookmarked.contains(title)) {
        _bookmarked.remove(title);
      } else {
        _bookmarked.add(title);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = _filter == null
        ? kBlogInsights
        : kBlogInsights.where((i) => i.category == _filter).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          _CollapsingHeader(colors: colors, totalCount: kBlogInsights.length),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          count: kBlogInsights.length,
                          selected: _filter == null,
                          color: colors.primary,
                          onTap: () => setState(() => _filter = null),
                        ),
                        for (final c in InsightCategory.values) ...[
                          const SizedBox(width: AppSpacing.sm),
                          _FilterChip(
                            label: _labelFor(c),
                            count: kBlogInsights
                                .where((i) => i.category == c)
                                .length,
                            selected: _filter == c,
                            color: _colorFor(colors, c),
                            onTap: () => setState(() => _filter = c),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xxl),
            sliver: SliverList.separated(
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) {
                final insight = visible[i];
                final accent = _colorFor(colors, insight.category);
                final label = _labelFor(insight.category);
                final bookmarked = _bookmarked.contains(insight.title);
                final card = i == 0
                    ? _FeaturedInsightCard(
                        data: insight,
                        accent: accent,
                        categoryLabel: label,
                        bookmarked: bookmarked,
                        onBookmarkTap: () => _toggleBookmark(insight.title),
                      )
                    : _InsightArticleCard(
                        data: insight,
                        accent: accent,
                        categoryLabel: label,
                        bookmarked: bookmarked,
                        onBookmarkTap: () => _toggleBookmark(insight.title),
                      );
                return _StaggerIn(index: i, child: card);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COLLAPSING HEADER — gradient backdrop that shrinks into a compact bar,
// matching the hero-card visual language used on Home / AI Usage screens.
// ---------------------------------------------------------------------------
class _CollapsingHeader extends StatelessWidget {
  const _CollapsingHeader({required this.colors, required this.totalCount});
  final AppColorsData colors;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 148,
      backgroundColor: colors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.md),
        child: _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsets.only(left: 64, bottom: 16, right: AppSpacing.xl),
        title: Text('Blog & Insights',
            style: AppTypography.h3(Colors.white)
                .copyWith(fontWeight: FontWeight.w800)),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.secondary,
                colors.primary.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.xl,
                bottom: 44,
                child: Text(
                  '$totalCount reads on running AI spend responsibly',
                  style: AppTypography.caption(
                      Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// STAGGERED ENTRANCE
// ---------------------------------------------------------------------------
class _StaggerIn extends StatelessWidget {
  const _StaggerIn({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 340 + (index * 60).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// ---------------------------------------------------------------------------
// FILTER CHIP — now with a live count badge.
// ---------------------------------------------------------------------------
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style:
                  AppTypography.caption(selected ? color : colors.textSecondary)
                      .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? color.withValues(alpha: 0.22)
                    : colors.border.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTypography.caption(
                        selected ? color : colors.textSecondary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// COVER IMAGE — shared image widget with gradient+icon fallback so a broken
// network request never leaves a blank tile.
// ---------------------------------------------------------------------------
class _CoverImage extends StatelessWidget {
  const _CoverImage({
    required this.data,
    required this.accent,
  }) : fit = BoxFit.cover;

  final BlogInsightData data;
  final Color accent;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      data.imageUrl,
      fit: fit,
      errorBuilder: (context, error, stack) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent.withValues(alpha: 0.85), accent],
          ),
        ),
        alignment: Alignment.center,
        child: Icon(data.icon, color: Colors.white, size: 32),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: accent.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(accent.withValues(alpha: 0.5)),
            ),
          ),
        );
      },
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.bookmarked,
    required this.onTap,
    this.onLight = false,
  });

  final bool bookmarked;
  final VoidCallback onTap;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onLight
              ? Colors.black.withValues(alpha: 0.28)
              : colors.surface.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Icon(
            bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            key: ValueKey(bookmarked),
            color: bookmarked
                ? (onLight ? Colors.white : colors.primary)
                : (onLight ? Colors.white : colors.textSecondary),
            size: 16,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FEATURED CARD — the top/most relevant insight, rendered as a large
// full-bleed image with a gradient scrim and overlaid title/meta.
// ---------------------------------------------------------------------------
class _FeaturedInsightCard extends StatefulWidget {
  const _FeaturedInsightCard({
    required this.data,
    required this.accent,
    required this.categoryLabel,
    required this.bookmarked,
    required this.onBookmarkTap,
  });

  final BlogInsightData data;
  final Color accent;
  final String categoryLabel;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;

  @override
  State<_FeaturedInsightCard> createState() => _FeaturedInsightCardState();
}

class _FeaturedInsightCardState extends State<_FeaturedInsightCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final d = widget.data;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: widget.accent.withValues(alpha: 0.14),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _CoverImage(data: d, accent: widget.accent),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.35, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.accent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text('FEATURED',
                              style: AppTypography.caption(Colors.white)
                                  .copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                      letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(widget.categoryLabel,
                          style: AppTypography.caption(Colors.white)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _BookmarkButton(
                  bookmarked: widget.bookmarked,
                  onTap: widget.onBookmarkTap,
                  onLight: true,
                ),
              ),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.title,
                        style: AppTypography.h3(Colors.white)
                            .copyWith(fontWeight: FontWeight.w800, height: 1.2)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '${d.dateLabel} · ${d.readTime}',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topLeft,
                  child: Text(
                    _expanded ? d.body : d.summary,
                    style: AppTypography.body(colors.textSecondary)
                        .copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ScaleOnTap(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Show less' : 'Read full insight',
                        style: AppTypography.caption(widget.accent)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: widget.accent,
                      ),
                    ],
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

// ---------------------------------------------------------------------------
// COMPACT LIST CARD — remaining insights, square thumbnail + text.
// ---------------------------------------------------------------------------
class _InsightArticleCard extends StatefulWidget {
  const _InsightArticleCard({
    required this.data,
    required this.accent,
    required this.categoryLabel,
    required this.bookmarked,
    required this.onBookmarkTap,
  });

  final BlogInsightData data;
  final Color accent;
  final String categoryLabel;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;

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
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: _CoverImage(data: d, accent: widget.accent),
                      ),
                    ),
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: colors.surfaceElevated, width: 2),
                        ),
                        child: Icon(d.icon, color: Colors.white, size: 11),
                      ),
                    ),
                  ],
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
                          Expanded(
                            child: Text(d.dateLabel,
                                style: AppTypography.caption(
                                    colors.textSecondary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text(d.readTime,
                              style:
                                  AppTypography.caption(colors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(d.title,
                          style: AppTypography.body(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700, height: 1.25)),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                _BookmarkButton(
                  bookmarked: widget.bookmarked,
                  onTap: widget.onBookmarkTap,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topLeft,
              child: Text(
                _expanded ? d.body : d.summary,
                style: AppTypography.caption(colors.textSecondary)
                    .copyWith(height: 1.4),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: _ScaleOnTap(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Read more',
                      style: AppTypography.caption(widget.accent)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 15,
                      color: widget.accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SCALE-ON-TAP — small tactile wrapper for inline text buttons.
// ---------------------------------------------------------------------------
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
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}