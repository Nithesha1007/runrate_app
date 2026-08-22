// ai_usage_detail_screen.dart
//
// Full "AI Portfolio Overview" screen — replaces
// `_AiUsageDetailPlaceholderRoute` in ceo_home_screen.dart. Reached from the
// "View all AI usage" link in the Home AI Usage & Adoption section.
//
// Sections: hero portfolio card (active tools, annual run rate, Optimize
// Spend / export actions), a dynamic AI Insight callout, search + category
// filter + sort controls, and the full tool utilization list with per-tool
// spend, trend, adoption ring, and unused-seat callouts.
//
// v2 — visual pass:
//   • Real brand logo images for the tools that have an official, square,
//     icon-only mark on Wikimedia Commons (ChatGPT, Claude, Gemini,
//     GitHub Copilot, Notion, Grammarly). Loaded through Commons'
//     Special:FilePath redirector, which returns a rendered PNG thumbnail —
//     so Image.network works with zero extra SVG dependencies. Every logo
//     keeps its existing icon fallback if the network image fails to load.
//   • Tools without a verified square Commons icon (Jasper, Midjourney,
//     Zapier, Otter.ai, Perplexity, Writer) keep a polished gradient
//     Material-icon badge instead of risking a broken/wrong image.
//   • Hero card gets a soft decorative glow and a subtle top accent stripe
//     per tool category on each card for faster visual scanning.
//   • Tool cards are now tappable (scale-on-tap) and surface a "Reclaim
//     $X/mo" chip when a tool has unused seats, making the optimization
//     opportunity visible at a glance instead of only in the insight
//     callout.
//   • AI Insight callout gets a subtle pulsing icon to draw the eye without
//     being distracting.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';

// =============================================================================
// MODELS
// =============================================================================

enum AiToolCategory { generativeAi, devTools, marketing, productivity }

extension AiToolCategoryX on AiToolCategory {
  String get label => switch (this) {
        AiToolCategory.generativeAi => 'Generative AI',
        AiToolCategory.devTools => 'Dev Tools',
        AiToolCategory.marketing => 'Marketing',
        AiToolCategory.productivity => 'Productivity',
      };

  List<Color> get accentGradient => switch (this) {
        AiToolCategory.generativeAi => const [
            Color(0xFF6C5CE7),
            Color(0xFF8E7CFF)
          ],
        AiToolCategory.devTools => const [
            Color(0xFF2F80ED),
            Color(0xFF56CCF2)
          ],
        AiToolCategory.marketing => const [
            Color(0xFFE85D75),
            Color(0xFFF2994A)
          ],
        AiToolCategory.productivity => const [
            Color(0xFF11998E),
            Color(0xFF38EF7D)
          ],
      };
}

class AiToolDetail {
  const AiToolDetail({
    required this.name,
    required this.vendor,
    required this.category,
    required this.icon,
    required this.monthlySpend,
    required this.trendPercent,
    required this.activeUsers,
    required this.adoptionRate,
    required this.unusedSeats,
  });

  final String name;
  final String vendor;
  final AiToolCategory category;
  final IconData icon;
  final double monthlySpend;
  final double trendPercent; // signed, e.g. +5, -8
  final int activeUsers;
  final double adoptionRate; // 0..1
  final int unusedSeats;

  double get costPerSeat => (activeUsers + unusedSeats) == 0
      ? 0
      : monthlySpend / (activeUsers + unusedSeats);

  double get reclaimableMonthly => costPerSeat * unusedSeats;
}

enum AiUsageSort { spendDesc, adoptionAsc, usersDesc, unusedDesc }

extension AiUsageSortX on AiUsageSort {
  String get label => switch (this) {
        AiUsageSort.spendDesc => 'Highest spend',
        AiUsageSort.adoptionAsc => 'Lowest adoption',
        AiUsageSort.usersDesc => 'Most users',
        AiUsageSort.unusedDesc => 'Most unused seats',
      };
}

class AiUsagePortfolioData {
  const AiUsagePortfolioData({required this.tools});
  final List<AiToolDetail> tools;

  int get activeToolCount => tools.length;
  double get monthlySpend => tools.fold(0, (s, t) => s + t.monthlySpend);
  double get annualRunRate => monthlySpend * 12;
  int get totalUnusedSeats => tools.fold(0, (s, t) => s + t.unusedSeats);
  double get totalReclaimableMonthly =>
      tools.fold(0, (s, t) => s + t.reclaimableMonthly);

  AiToolDetail get lowestAdoptionTool =>
      tools.reduce((a, b) => a.adoptionRate <= b.adoptionRate ? a : b);
}

sealed class AiUsageDetailState {
  const AiUsageDetailState();
}

class AiUsageDetailLoading extends AiUsageDetailState {
  const AiUsageDetailLoading();
}

class AiUsageDetailLoaded extends AiUsageDetailState {
  const AiUsageDetailLoaded(this.data);
  final AiUsagePortfolioData data;
}

class AiUsageDetailError extends AiUsageDetailState {
  const AiUsageDetailError(this.message);
  final String message;
}

// =============================================================================
// CUBIT — swap `_mockData()` for a real API call once the endpoint exists.
// =============================================================================

class AiUsageDetailCubit extends Cubit<AiUsageDetailState> {
  AiUsageDetailCubit() : super(const AiUsageDetailLoading()) {
    load();
  }

  Future<void> load() async {
    emit(const AiUsageDetailLoading());
    try {
      await Future.delayed(const Duration(milliseconds: 550));
      emit(AiUsageDetailLoaded(_mockData()));
    } catch (e) {
      emit(AiUsageDetailError(e.toString()));
    }
  }

  AiUsagePortfolioData _mockData() {
    return const AiUsagePortfolioData(tools: [
      AiToolDetail(
        name: 'ChatGPT Enterprise',
        vendor: 'OpenAI',
        category: AiToolCategory.generativeAi,
        icon: Icons.chat_bubble_rounded,
        monthlySpend: 48200,
        trendPercent: 5,
        activeUsers: 191,
        adoptionRate: 0.82,
        unusedSeats: 12,
      ),
      AiToolDetail(
        name: 'Claude Enterprise',
        vendor: 'Anthropic',
        category: AiToolCategory.generativeAi,
        icon: Icons.auto_awesome_rounded,
        monthlySpend: 22400,
        trendPercent: 0,
        activeUsers: 96,
        adoptionRate: 0.64,
        unusedSeats: 18,
      ),
      AiToolDetail(
        name: 'GitHub Copilot',
        vendor: 'Microsoft',
        category: AiToolCategory.devTools,
        icon: Icons.code_rounded,
        monthlySpend: 31200,
        trendPercent: 12,
        activeUsers: 124,
        adoptionRate: 0.92,
        unusedSeats: 2,
      ),
      AiToolDetail(
        name: 'Jasper',
        vendor: 'Jasper',
        category: AiToolCategory.marketing,
        icon: Icons.edit_note_rounded,
        monthlySpend: 4000,
        trendPercent: -8,
        activeUsers: 22,
        adoptionRate: 0.45,
        unusedSeats: 14,
      ),
      AiToolDetail(
        name: 'Gemini Advanced',
        vendor: 'Google',
        category: AiToolCategory.generativeAi,
        icon: Icons.diamond_outlined,
        monthlySpend: 6800,
        trendPercent: -2,
        activeUsers: 19,
        adoptionRate: 0.38,
        unusedSeats: 9,
      ),
      AiToolDetail(
        name: 'Notion AI',
        vendor: 'Notion',
        category: AiToolCategory.productivity,
        icon: Icons.description_outlined,
        monthlySpend: 3200,
        trendPercent: 9,
        activeUsers: 88,
        adoptionRate: 0.71,
        unusedSeats: 6,
      ),
      AiToolDetail(
        name: 'Grammarly Business',
        vendor: 'Grammarly',
        category: AiToolCategory.productivity,
        icon: Icons.spellcheck_rounded,
        monthlySpend: 2600,
        trendPercent: 3,
        activeUsers: 140,
        adoptionRate: 0.79,
        unusedSeats: 8,
      ),
      AiToolDetail(
        name: 'Midjourney',
        vendor: 'Midjourney',
        category: AiToolCategory.marketing,
        icon: Icons.image_outlined,
        monthlySpend: 1800,
        trendPercent: 15,
        activeUsers: 14,
        adoptionRate: 0.51,
        unusedSeats: 4,
      ),
      AiToolDetail(
        name: 'Zapier AI',
        vendor: 'Zapier',
        category: AiToolCategory.productivity,
        icon: Icons.bolt_rounded,
        monthlySpend: 2100,
        trendPercent: 6,
        activeUsers: 33,
        adoptionRate: 0.55,
        unusedSeats: 7,
      ),
      AiToolDetail(
        name: 'Otter.ai',
        vendor: 'Otter',
        category: AiToolCategory.productivity,
        icon: Icons.mic_none_rounded,
        monthlySpend: 1400,
        trendPercent: -4,
        activeUsers: 41,
        adoptionRate: 0.60,
        unusedSeats: 5,
      ),
      AiToolDetail(
        name: 'Perplexity Enterprise',
        vendor: 'Perplexity',
        category: AiToolCategory.generativeAi,
        icon: Icons.travel_explore_rounded,
        monthlySpend: 3400,
        trendPercent: 18,
        activeUsers: 27,
        adoptionRate: 0.48,
        unusedSeats: 10,
      ),
      AiToolDetail(
        name: 'Writer',
        vendor: 'Writer',
        category: AiToolCategory.marketing,
        icon: Icons.create_rounded,
        monthlySpend: 1500,
        trendPercent: -1,
        activeUsers: 12,
        adoptionRate: 0.33,
        unusedSeats: 11,
      ),
    ]);
  }
}

// =============================================================================
// BRAND MAP — real logos for tools that have a verified, square, icon-only
// mark on Wikimedia Commons. Everything else falls back to a gradient badge
// using the Material icon already defined on AiToolDetail.
//
// Images are served through Commons' Special:FilePath redirector
// (`?width=200`), which 302-redirects to a rendered PNG thumbnail — so
// Image.network can decode it directly with no flutter_svg dependency.
// =============================================================================

String? _brandLogoUrlFor(String toolName) {
  final n = toolName.toLowerCase();
  if (n.contains('chatgpt') || n.contains('gpt')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/ChatGPT%20logo.svg?width=200';
  }
  if (n.contains('copilot')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/GitHub%20Invertocat%20Logo.svg?width=200';
  }
  if (n.contains('claude')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Claude%20AI%20symbol.svg?width=200';
  }
  if (n.contains('gemini')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Google%20Gemini%20icon%202025.svg?width=200';
  }
  if (n.contains('notion')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Notion-logo.svg?width=200';
  }
  if (n.contains('grammarly')) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/Grammarly%20logo%202024.svg?width=200';
  }
  return null;
}

// =============================================================================
// SCREEN
// =============================================================================

class AiUsageDetailScreen extends StatelessWidget {
  const AiUsageDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AiUsageDetailCubit(),
      child: const _AiUsageDetailView(),
    );
  }
}

class _AiUsageDetailView extends StatefulWidget {
  const _AiUsageDetailView();

  @override
  State<_AiUsageDetailView> createState() => _AiUsageDetailViewState();
}

class _AiUsageDetailViewState extends State<_AiUsageDetailView> {
  final _searchController = TextEditingController();
  AiToolCategory? _category;
  AiUsageSort _sort = AiUsageSort.spendDesc;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AiToolDetail> _filterAndSort(List<AiToolDetail> tools) {
    var result = tools.where((t) {
      final matchesCategory = _category == null || t.category == _category;
      final matchesQuery = _query.isEmpty ||
          t.name.toLowerCase().contains(_query.toLowerCase()) ||
          t.vendor.toLowerCase().contains(_query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    result.sort((a, b) => switch (_sort) {
          AiUsageSort.spendDesc => b.monthlySpend.compareTo(a.monthlySpend),
          AiUsageSort.adoptionAsc => a.adoptionRate.compareTo(b.adoptionRate),
          AiUsageSort.usersDesc => b.activeUsers.compareTo(a.activeUsers),
          AiUsageSort.unusedDesc => b.unusedSeats.compareTo(a.unusedSeats),
        });
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<AiUsageDetailCubit, AiUsageDetailState>(
          builder: (context, state) {
            return switch (state) {
              AiUsageDetailLoading() => _LoadingBody(colors: colors),
              AiUsageDetailError(:final message) => _ErrorBody(
                  message: message,
                  onRetry: () => context.read<AiUsageDetailCubit>().load(),
                ),
              AiUsageDetailLoaded(:final data) => _LoadedBody(
                  data: data,
                  query: _query,
                  category: _category,
                  sort: _sort,
                  searchController: _searchController,
                  visibleTools: _filterAndSort(data.tools),
                  onQueryChanged: (v) => setState(() => _query = v),
                  onCategoryChanged: (c) => setState(() => _category = c),
                  onSortChanged: (s) => setState(() => _sort = s),
                  onRefresh: () => context.read<AiUsageDetailCubit>().load(),
                ),
            };
          },
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// LOADED BODY
// -----------------------------------------------------------------------
class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.data,
    required this.query,
    required this.category,
    required this.sort,
    required this.searchController,
    required this.visibleTools,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final AiUsagePortfolioData data;
  final String query;
  final AiToolCategory? category;
  final AiUsageSort sort;
  final TextEditingController searchController;
  final List<AiToolDetail> visibleTools;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AiToolCategory?> onCategoryChanged;
  final ValueChanged<AiUsageSort> onSortChanged;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _TopBar(),
                  const SizedBox(height: AppSpacing.lg),
                  _PortfolioHeroCard(data: data),
                  const SizedBox(height: AppSpacing.lg),
                  _InsightCallout(data: data),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Tool Utilization',
                      style: AppTypography.h3(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.md),
                  _SearchAndFilterBar(
                    controller: searchController,
                    category: category,
                    sort: sort,
                    onQueryChanged: onQueryChanged,
                    onCategoryChanged: onCategoryChanged,
                    onSortChanged: onSortChanged,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          if (visibleTools.isEmpty)
            SliverToBoxAdapter(child: _EmptyResults(colors: colors))
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.xl, 120),
              sliver: SliverList.separated(
                itemCount: visibleTools.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => _StaggerIn(
                  index: i,
                  child: _ToolCard(tool: visibleTools[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaggerIn extends StatelessWidget {
  const _StaggerIn({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 45).clamp(0, 500)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 14),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

// -----------------------------------------------------------------------
// TOP BAR
// -----------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        _RoundIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text('AI Usage & Adoption',
              style: AppTypography.h3(colors.textPrimary)),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: colors.border),
            ),
            child: Icon(icon, color: colors.textPrimary, size: 19),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------
// PORTFOLIO HERO CARD
//
// v2 — added a soft decorative glow (two blurred circles clipped inside the
// card radius) behind the content for a bit of depth, and a third hero
// stat tile (Reclaimable/mo) so the optimization opportunity is visible
// without scrolling to the insight callout below.
// -----------------------------------------------------------------------
class _PortfolioHeroCard extends StatelessWidget {
  const _PortfolioHeroCard({required this.data});
  final AiUsagePortfolioData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.secondary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -20,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI Portfolio Overview',
                                style: AppTypography.h3(Colors.white)),
                            const SizedBox(height: 2),
                            Text(
                                'Active deployments across the organization',
                                style: AppTypography.caption(
                                    Colors.white.withValues(alpha: 0.85))),
                          ],
                        ),
                      ),
                      _GlassIconButton(
                        icon: Icons.autorenew_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Refreshing portfolio…')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _HeroStatTile(
                          label: 'ACTIVE TOOLS',
                          value: '${data.activeToolCount}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _HeroStatTile(
                          label: 'ANNUAL RUN RATE',
                          value: '\$${_compact(data.annualRunRate)}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _HeroStatTile(
                    label: 'RECLAIMABLE / MONTH',
                    value: '\$${_compact(data.totalReclaimableMonthly)}',
                    icon: Icons.savings_rounded,
                    fullWidth: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _ScaleTap(
                          onTap: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Spend optimization scan started…')),
                          ),
                          child: Container(
                            height: 46,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_fix_high_rounded,
                                    size: 17, color: colors.primary),
                                const SizedBox(width: 8),
                                Text('Optimize Spend',
                                    style: AppTypography.body(colors.primary)
                                        .copyWith(
                                            fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _GlassIconButton(
                        icon: Icons.ios_share_rounded,
                        onTap: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Exporting portfolio report…')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  const _HeroStatTile({
    required this.label,
    required this.value,
    this.icon,
    this.fullWidth = false,
  });
  final String label;
  final String value;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
      ),
      child: fullWidth
          ? Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white.withValues(alpha: 0.85),
                      size: 16),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(label,
                      style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.8))
                          .copyWith(letterSpacing: 0.4, fontSize: 10)),
                ),
                Text(value,
                    style: AppTypography.body(Colors.white)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.caption(
                            Colors.white.withValues(alpha: 0.8))
                        .copyWith(letterSpacing: 0.4, fontSize: 10)),
                const SizedBox(height: 4),
                Text(value,
                    style: AppTypography.h2(Colors.white)
                        .copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ScaleTap(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 19),
      ),
    );
  }
}

class _ScaleTap extends StatefulWidget {
  const _ScaleTap({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
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

// -----------------------------------------------------------------------
// AI INSIGHT CALLOUT — dynamically calls out the lowest-adoption tool.
// v2 — the icon badge now pulses gently (a slow scale/opacity breathe) so
// the callout draws the eye on first load without being distracting.
// -----------------------------------------------------------------------
class _InsightCallout extends StatefulWidget {
  const _InsightCallout({required this.data});
  final AiUsagePortfolioData data;

  @override
  State<_InsightCallout> createState() => _InsightCalloutState();
}

class _InsightCalloutState extends State<_InsightCallout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tool = widget.data.lowestAdoptionTool;
    const target = 0.60;
    final savings = tool.reclaimableMonthly;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final t = _pulseController.value;
              return Transform.scale(
                scale: 1.0 + (t * 0.08),
                child: Opacity(opacity: 0.85 + (t * 0.15), child: child),
              );
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_awesome_rounded,
                  color: colors.primary, size: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Insight',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: AppTypography.caption(colors.textSecondary),
                    children: [
                      TextSpan(
                          text:
                              '${tool.name} adoption is below target (${(target * 100).toInt()}%). '
                              'Consolidating unused seats could save '),
                      TextSpan(
                        text: '\$${savings.toStringAsFixed(0)}/mo. ',
                        style: AppTypography.caption(colors.primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                          text:
                              '${widget.data.tools.first.name} utilization is strong, but '
                              '${widget.data.totalUnusedSeats} seats remain unassigned company-wide.'),
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

// -----------------------------------------------------------------------
// SEARCH + FILTER + SORT
// -----------------------------------------------------------------------
class _SearchAndFilterBar extends StatelessWidget {
  const _SearchAndFilterBar({
    required this.controller,
    required this.category,
    required this.sort,
    required this.onQueryChanged,
    required this.onCategoryChanged,
    required this.onSortChanged,
  });

  final TextEditingController controller;
  final AiToolCategory? category;
  final AiUsageSort sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AiToolCategory?> onCategoryChanged;
  final ValueChanged<AiUsageSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: TextField(
                  controller: controller,
                  onChanged: onQueryChanged,
                  style: AppTypography.body(colors.textPrimary),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search_rounded,
                        size: 18, color: colors.textSecondary),
                    hintText: 'Search tools or vendors',
                    hintStyle: AppTypography.caption(colors.textSecondary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _SortButton(sort: sort, onSortChanged: onSortChanged),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _CategoryChip(
                label: 'All',
                selected: category == null,
                onTap: () => onCategoryChanged(null),
              ),
              for (final c in AiToolCategory.values)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: _CategoryChip(
                    label: c.label,
                    selected: category == c,
                    onTap: () => onCategoryChanged(c),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(label,
            style: AppTypography.caption(
                    selected ? Colors.white : colors.textSecondary)
                .copyWith(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSortChanged});
  final AiUsageSort sort;
  final ValueChanged<AiUsageSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return PopupMenuButton<AiUsageSort>(
      initialValue: sort,
      onSelected: onSortChanged,
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => AiUsageSort.values
          .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
          .toList(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Icon(Icons.tune_rounded, size: 18, color: colors.textPrimary),
      ),
    );
  }
}

// -----------------------------------------------------------------------
// TOOL CARD
//
// v2 — now tap-scalable (opens a "coming soon" snackbar until a real
// per-tool detail route exists), shows a real brand logo image when one is
// available (falls back to the original gradient Material-icon badge
// otherwise), carries a thin category-colored accent stripe down the left
// edge for fast visual scanning, and surfaces a "Reclaim $X/mo" chip next
// to the unused-seats stat whenever a tool has seats sitting idle.
// -----------------------------------------------------------------------
class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final AiToolDetail tool;

  Color _adoptionColor(AppColorsData colors) {
    if (tool.adoptionRate >= 0.7) return colors.success;
    if (tool.adoptionRate >= 0.5) return colors.warning;
    return colors.danger;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final adoptionColor = _adoptionColor(colors);
    final isPositiveTrend = tool.trendPercent > 0;
    final isFlatTrend = tool.trendPercent == 0;
    final logoUrl = _brandLogoUrlFor(tool.name);
    final accent = tool.category.accentGradient;

    return _ScaleTap(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${tool.name} details — coming soon')),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            border: Border.all(color: colors.border),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: accent,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              padding: logoUrl != null
                                  ? const EdgeInsets.all(8)
                                  : EdgeInsets.zero,
                              decoration: BoxDecoration(
                                color: logoUrl != null
                                    ? colors.surface
                                    : adoptionColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                                border: logoUrl != null
                                    ? Border.all(color: colors.border)
                                    : null,
                              ),
                              child: logoUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.network(
                                        logoUrl,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stack) => Icon(
                                                tool.icon,
                                                color: adoptionColor,
                                                size: 20),
                                      ),
                                    )
                                  : Icon(tool.icon,
                                      color: adoptionColor, size: 20),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(tool.name,
                                      style: AppTypography.body(
                                              colors.textPrimary)
                                          .copyWith(
                                              fontWeight: FontWeight.w700),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(
                                      '${tool.vendor} · ${tool.category.label}',
                                      style: AppTypography.caption(
                                          colors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('\$${_compact(tool.monthlySpend)}/mo',
                                    style: AppTypography.body(
                                            colors.textPrimary)
                                        .copyWith(
                                            fontWeight: FontWeight.w700)),
                                if (!isFlatTrend)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: (isPositiveTrend
                                              ? colors.success
                                              : colors.danger)
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${isPositiveTrend ? '↑' : '↓'} ${tool.trendPercent.abs().toStringAsFixed(0)}%',
                                      style: AppTypography.caption(
                                              isPositiveTrend
                                                  ? colors.success
                                                  : colors.danger)
                                          .copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10),
                                    ),
                                  )
                                else
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text('→ 0%',
                                        style: AppTypography.caption(
                                            colors.textSecondary)),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(
                              child: _StatColumn(
                                label: 'Active Users',
                                value: '${tool.activeUsers}',
                                colors: colors,
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                label: 'Adoption',
                                value:
                                    '${(tool.adoptionRate * 100).toInt()}%',
                                colors: colors,
                              ),
                            ),
                            Expanded(
                              child: _StatColumn(
                                label: 'Unused Seats',
                                value: '${tool.unusedSeats}',
                                valueColor: tool.unusedSeats > 0
                                    ? colors.danger
                                    : null,
                                colors: colors,
                              ),
                            ),
                          ],
                        ),
                        if (tool.unusedSeats > 0) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 5),
                            decoration: BoxDecoration(
                              color: colors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.savings_outlined,
                                    size: 13, color: colors.danger),
                                const SizedBox(width: 5),
                                Text(
                                  'Reclaim \$${tool.reclaimableMonthly.toStringAsFixed(0)}/mo from ${tool.unusedSeats} idle seat${tool.unusedSeats == 1 ? '' : 's'}',
                                  style: AppTypography.caption(colors.danger)
                                      .copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                                begin: 0, end: tool.adoptionRate.clamp(0, 1)),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                              value: value,
                              minHeight: 6,
                              color: adoptionColor,
                              backgroundColor: colors.border,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.colors,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption(colors.textSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.body(valueColor ?? colors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// -----------------------------------------------------------------------
// LOADING / ERROR / EMPTY
// -----------------------------------------------------------------------
class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopBar(),
          const SizedBox(height: AppSpacing.lg),
          _ShimmerBlock(height: 240, colors: colors),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBlock(height: 84, colors: colors),
          const SizedBox(height: AppSpacing.lg),
          _ShimmerBlock(height: 44, colors: colors),
          const SizedBox(height: AppSpacing.md),
          _ShimmerBlock(height: 110, colors: colors),
          const SizedBox(height: AppSpacing.sm),
          _ShimmerBlock(height: 110, colors: colors),
        ],
      ),
    );
  }
}

class _ShimmerBlock extends StatefulWidget {
  const _ShimmerBlock({required this.height, required this.colors});
  final double height;
  final AppColorsData colors;

  @override
  State<_ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<_ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmer = (_controller.value * 2).clamp(0.0, 1.0);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                widget.colors.surface,
                widget.colors.surfaceElevated,
                widget.colors.surface
              ],
              stops: [0.0, shimmer, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _TopBar(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 40, color: colors.danger),
                  const SizedBox(height: AppSpacing.md),
                  Text('Couldn\'t load AI usage data',
                      style: AppTypography.h3(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Text(message,
                      style: AppTypography.body(colors.textSecondary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  OutlinedButton(
                      onPressed: onRetry, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 36, color: colors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text('No tools match your filters',
              style: AppTypography.body(colors.textSecondary)),
        ],
      ),
    );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}