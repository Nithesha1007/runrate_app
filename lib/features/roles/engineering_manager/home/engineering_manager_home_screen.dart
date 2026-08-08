import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/home/ceo_home_cubit.dart';
import 'package:runrate/features/roles/engineering_manager/ai/engineering_manager_ai_screen.dart';
import 'package:runrate/features/roles/engineering_manager/approvals/engineering_manager_approvals_screen.dart';
import 'package:runrate/features/roles/engineering_manager/home/engineering_manager_home_cubit.dart';
import 'package:runrate/features/roles/engineering_manager/teams/engineering_manager_teams_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';

/// CEO Home dashboard.
///
/// NOTE: This screen intentionally shows only a compact, ~1–1.5 screen
/// summary. Anything that belongs to another tab (full team member list,
/// AI insights feed, activity timeline, approval history, reports, etc.)
/// lives in that tab, not here. If `CeoHomeData` still exposes fields like
/// `teamMembers`, `insights`, `recentActivity`, `productivitySummary`, or
/// `aiManagerSummary`, they are simply unused by this view — safe to
/// keep in the cubit for other screens to reuse, or trim later.
class EngineeringManagerHomeScreen extends StatelessWidget {
  const EngineeringManagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerHomeCubit()..loadDashboard(),
      child: const _EngineeringManagerHomeView(),
    );
  }
}

class _EngineeringManagerHomeView extends StatefulWidget {
  const _EngineeringManagerHomeView();

  @override
  State<_EngineeringManagerHomeView> createState() =>
      _EngineeringManagerHomeViewState();
}

class _EngineeringManagerHomeViewState
    extends State<_EngineeringManagerHomeView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageController;
  late final Animation<double> _pageFade;

  @override
  void initState() {
    super.initState();
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _pageFade = CurvedAnimation(parent: _pageController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocConsumer<EngineeringManagerHomeCubit,
            EngineeringManagerHomeState>(
          listener: (context, state) {
            if (state is EngineeringManagerHomeLoaded) {
              _pageController.forward(from: 0);
            }
          },
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerHomeInitial() ||
              EngineeringManagerHomeLoading() =>
                const _LoadingView(),
              EngineeringManagerHomeError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context
                      .read<EngineeringManagerHomeCubit>()
                      .loadDashboard(),
                ),
              EngineeringManagerHomeLoaded(:final data) => FadeTransition(
                  opacity: _pageFade,
                  child: RefreshIndicator(
                    color: colors.primary,
                    onRefresh: () =>
                        context.read<EngineeringManagerHomeCubit>().refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHeader(
                            managerName: data.managerName,
                            teamName: data.teamName,
                            todayLabel: data.todayLabel,
                            greeting: data.greeting,
                            hasUnread: data.hasUnreadNotifications,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 0,
                            child: _HeroOverviewCard(data: data),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 1,
                            child: _QuickActionsGrid(
                              items: data.quickActions,
                              onTap: (item) =>
                                  _handleQuickAction(context, item),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 2,
                            child: _KpiGrid(kpis: data.kpis),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 3,
                            child: _BudgetHealthCard(data: data.budgetHealth),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 4,
                            child: _TopAiToolsSection(
                              tools: data.toolUsage.take(4).toList(),
                              onViewAll: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EngineeringManagerTeamsScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 5,
                            child: _PendingApprovalsSection(
                              requests: data.pendingRequests.take(3).toList(),
                              onApprove: (id) => context
                                  .read<EngineeringManagerHomeCubit>()
                                  .approveRequest(id),
                              onReject: (id) => context
                                  .read<EngineeringManagerHomeCubit>()
                                  .rejectRequest(id),
                              onViewAll: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const EngineeringManagerApprovalsScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            };
          },
        ),
      ),
      floatingActionButton:
          BlocBuilder<EngineeringManagerHomeCubit, EngineeringManagerHomeState>(
        builder: (context, state) {
          if (state is! EngineeringManagerHomeLoaded) {
            return const SizedBox.shrink();
          }
          return _ScaleOnTap(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => const EngineeringManagerAiScreen()),
            ),
            child: FloatingActionButton.extended(
              onPressed: null,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('AI Copilot'),
            ),
          );
        },
      ),
    );
  }

  void _handleQuickAction(BuildContext context, QuickActionItem item) {
    switch (item.routeTag) {
      case 'analytics':
      case 'members':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EngineeringManagerTeamsScreen()));
      case 'reports':
      case 'recommendations':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EngineeringManagerAiScreen()));
      case 'approvals':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const EngineeringManagerApprovalsScreen()));
      case 'budget':
        Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const _BudgetDetailRoute()));
      default:
        break;
    }
  }
}

/// Slide-up + fade stagger wrapper for cards, indexed by section order.
class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 18),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Subtle scale-down-on-tap wrapper for tactile buttons.
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
      onTapDown: (_) => setState(() => _scale = 0.94),
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: const [
          _ShimmerCard(height: 210),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 84),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 150),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 120),
        ],
      ),
    );
  }
}

class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard({required this.height});

  final double height;

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
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
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmer = (_controller.value * 2).clamp(0.0, 1.0);
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [colors.surface, colors.surfaceElevated, colors.surface],
              stops: [0.0, shimmer, 1.0],
            ),
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.managerName,
    required this.teamName,
    required this.todayLabel,
    required this.greeting,
    required this.hasUnread,
  });

  final String managerName;
  final String teamName;
  final String todayLabel;
  final String greeting;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              GestureDetector(
                onTap: () =>
                    Navigator.of(context).pushNamed(RouteNames.profile),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: colors.primaryLight,
                  child: Text(
                    managerName
                        .split(' ')
                        .map((e) => e.isNotEmpty ? e[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase(),
                    style: AppTypography.h3(colors.primary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: AppTypography.caption(colors.textSecondary)),
                    Text(managerName,
                        style: AppTypography.h3(colors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$teamName · $todayLabel',
                        style: AppTypography.caption(colors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(RouteNames.notifications),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: colors.textPrimary),
              ),
              if (hasUnread)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                        color: colors.danger, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _BudgetStatus { healthy, warning, critical }

_BudgetStatus _statusFor(double utilization) {
  if (utilization >= 0.95) return _BudgetStatus.critical;
  if (utilization >= 0.8) return _BudgetStatus.warning;
  return _BudgetStatus.healthy;
}

String _statusLabelFor(_BudgetStatus status) {
  switch (status) {
    case _BudgetStatus.healthy:
      return 'Healthy';
    case _BudgetStatus.warning:
      return 'Warning';
    case _BudgetStatus.critical:
      return 'Critical';
  }
}

// ---------------------------------------------------------------------------
// BRAND MAP — real per-tool identity instead of one generic bolt icon.
// Put official logo assets here once you've grabbed them from each brand kit:
//   assets/icons/tools/claude.png, chatgpt.png, copilot.png, cursor.png, gemini.png
// If an asset is missing, it falls back to a colored initials badge — never
// a broken image, never a placeholder icon.
// ---------------------------------------------------------------------------
class ToolBrand {
  const ToolBrand({
    required this.initials,
    required this.color,
    required this.bg,
    this.assetPath,
  });

  final String initials;
  final Color color;
  final Color bg;
  final String? assetPath;
}

const Map<String, ToolBrand> kToolBrands = {
  'Claude': ToolBrand(
    initials: 'C',
    color: Color(0xFFD97757),
    bg: Color(0xFFFBEDE6),
    assetPath: 'assets/icons/tools/claude.png',
  ),
  'ChatGPT Enterprise': ToolBrand(
    initials: 'G',
    color: Color(0xFF10A37F),
    bg: Color(0xFFE6F6F1),
    assetPath: 'assets/icons/tools/chatgpt.png',
  ),
  'GitHub Copilot': ToolBrand(
    initials: 'GH',
    color: Color(0xFF24292F),
    bg: Color(0xFFEDEEF0),
    assetPath: 'assets/icons/tools/copilot.png',
  ),
  'Cursor': ToolBrand(
    initials: 'CU',
    color: Color(0xFF0A0A0A),
    bg: Color(0xFFF0F0F1),
    assetPath: 'assets/icons/tools/cursor.png',
  ),
  'Gemini': ToolBrand(
    initials: 'GM',
    color: Color(0xFF4285F4),
    bg: Color(0xFFEAF1FE),
    assetPath: 'assets/icons/tools/gemini.png',
  ),
};

ToolBrand _brandFor(String name) =>
    kToolBrands[name] ??
    const ToolBrand(
        initials: 'AI', color: Color(0xFF6C5CE7), bg: Color(0xFFEFECFD));

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.name, this.size = 40});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = _brandFor(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: brand.bg,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      clipBehavior: Clip.antiAlias,
      child: brand.assetPath == null
          ? _initials(brand)
          : Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: Image.asset(
                brand.assetPath!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => _initials(brand),
              ),
            ),
    );
  }

  Widget _initials(ToolBrand brand) => Center(
        child: Text(
          brand.initials,
          style: TextStyle(
            color: brand.color,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.36,
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// HERO CARD — soft translucent track (no more black ring), a real gradient
// sweep progress arc via ShaderMask, and a slow breathing glow that runs
// continuously behind the card, not just on load.
// ---------------------------------------------------------------------------
class _HeroOverviewCard extends StatefulWidget {
  const _HeroOverviewCard({required this.data});
  final EngineeringManagerHomeData data;

  @override
  State<_HeroOverviewCard> createState() => _HeroOverviewCardState();
}

class _HeroOverviewCardState extends State<_HeroOverviewCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final data = widget.data;
    final progress = (data.budgetUtilization * 100).round();
    final status = _statusFor(data.budgetUtilization);
    final statusColor = switch (status) {
      _BudgetStatus.healthy => colors.success,
      _BudgetStatus.warning => colors.warning,
      _BudgetStatus.critical => colors.danger,
    };

    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) {
        final t = _glow.value;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withOpacity(0.28 + t * 0.12),
                blurRadius: 32 + t * 10,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.secondary,
                colors.primary.withOpacity(0.85),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Engineering AI overview',
                        style: AppTypography.h3(Colors.white)),
                  ),
                  _StatusPill(
                      label: _statusLabelFor(status), color: statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // soft track — never solid black
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation(
                                Colors.white.withOpacity(0.18)),
                          ),
                        ),
                        // gradient sweep progress
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: data.budgetUtilization),
                          duration: const Duration(milliseconds: 1100),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => ShaderMask(
                            shaderCallback: (rect) => const SweepGradient(
                              startAngle: 0,
                              endAngle: 6.28,
                              colors: [
                                Colors.white,
                                Color(0xFFB9C7FF),
                                Colors.white,
                              ],
                            ).createShader(rect),
                            child: SizedBox(
                              width: 96,
                              height: 96,
                              child: CircularProgressIndicator(
                                value: value,
                                strokeWidth: 9,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.transparent,
                                valueColor:
                                    const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                          ),
                        ),
                        _AnimatedCounterText(
                          target: progress,
                          suffix: '%',
                          style: AppTypography.h3(Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatChip(
                            label: 'Spend',
                            value: '\$${data.currentSpend.toStringAsFixed(0)}'),
                        const SizedBox(height: AppSpacing.sm),
                        _StatChip(
                            label: 'Remaining',
                            value:
                                '\$${data.remainingBudget.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _MetricPill(
                      label: 'AI adoption',
                      value: '${(data.adoptionRate * 100).toInt()}%'),
                  _MetricPill(
                      label: 'Active users', value: '${data.activeUsers}'),
                  _MetricPill(
                      label: 'Productivity',
                      value: '${data.productivityScore.toInt()}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(Colors.white)),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  const _AnimatedCounterText({
    required this.target,
    required this.style,
    this.suffix = '',
  });

  final int target;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text('$value$suffix', style: style),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: AppTypography.caption(Colors.white.withOpacity(0.8))),
          Text(value,
              style: AppTypography.caption(Colors.white)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label · $value',
          style: AppTypography.caption(Colors.white)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onViewAll});

  final String title;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
            child: Text(title, style: AppTypography.h3(colors.textPrimary))),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child:
                Text('View all', style: AppTypography.caption(colors.primary)),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// QUICK ACTIONS — row-style tile (icon left, title+subtitle right) instead
// of a tall square with a Spacer, so there's no dead vertical space. Each
// action gets its own gradient accent so the four don't look identical.
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items, required this.onTap});

  final List<QuickActionItem> items;
  final ValueChanged<QuickActionItem> onTap;

  static const _accents = [
    [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF2994A), Color(0xFFF2C94C)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 700 ? 4 : 2;
        final visible = items.take(4).toList();
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: 2.6,
          children: List.generate(visible.length, (i) {
            final item = visible[i];
            final accent = _accents[i % _accents.length];
            return _ScaleOnTap(
              onTap: () => onTap(item),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm + 2),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: accent),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 19),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(item.title,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(item.subtitle,
                              style:
                                  AppTypography.caption(colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<KpiCardData> kpis;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: kpis.take(4).map((kpi) {
        final isPositive = kpi.trendValue >= 0;
        return Container(
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
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: colors.primaryLight,
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(kpi.icon, color: colors.primary, size: 16),
                  ),
                  const Spacer(),
                  Text(kpi.trend,
                      style: AppTypography.caption(
                          isPositive ? colors.success : colors.danger)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              _AnimatedCounterOrText(
                  value: kpi.value,
                  style: AppTypography.h3(colors.textPrimary)),
              Text(kpi.label,
                  style: AppTypography.caption(colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Animates a numeric KPI value if it parses as an int; otherwise renders as-is.
class _AnimatedCounterOrText extends StatelessWidget {
  const _AnimatedCounterOrText({required this.value, required this.style});

  final String value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final numeric = int.tryParse(value.replaceAll(RegExp(r'[^0-9\-]'), ''));
    if (numeric == null) {
      return Text(value, style: style);
    }
    final prefix = value.startsWith(RegExp(r'[^\d\-]')) ? value[0] : '';
    final suffix = value.endsWith('%') ? '%' : '';
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: numeric),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$prefix$v$suffix', style: style),
    );
  }
}

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.data});

  final BudgetHealthData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final status = _statusFor(data.utilization);
    final statusColor = switch (status) {
      _BudgetStatus.healthy => colors.success,
      _BudgetStatus.warning => colors.warning,
      _BudgetStatus.critical => colors.danger,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text('Team budget health',
                      style: AppTypography.h3(colors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusLabelFor(status),
                    style: AppTypography.caption(statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _LabeledValue(
                    label: 'Spend', value: '\$${data.used.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _LabeledValue(
                    label: 'Remaining',
                    value: '\$${data.remaining.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _LabeledValue(
                    label: 'Forecast',
                    value: '${(data.forecast * 100).toInt()}%'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: data.utilization),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: statusColor,
                backgroundColor: colors.primaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledValue extends StatelessWidget {
  const _LabeledValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption(colors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: AppTypography.body(colors.textPrimary)),
      ],
    );
  }
}

class _TopAiToolsSection extends StatelessWidget {
  const _TopAiToolsSection({required this.tools, required this.onViewAll});

  final List<ToolUsageData> tools;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Top AI tools', onViewAll: onViewAll),
        const SizedBox(height: AppSpacing.md),
        ...tools.map((tool) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ToolUsageRow(tool: tool),
            )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// TOOL ROW — brand badge instead of a generic bolt icon, plus a small donut
// ring for utilization instead of flat percentage text.
// ---------------------------------------------------------------------------
class _ToolUsageRow extends StatelessWidget {
  const _ToolUsageRow({required this.tool});

  final ToolUsageData tool;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final brand = _brandFor(tool.name);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _BrandBadge(name: tool.name, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tool.name,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                    '${tool.activeUsers} active · \$${tool.monthlyCost.toInt()}/mo',
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: tool.utilization,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(brand.color),
                ),
                Text('${tool.licenseUsage}',
                    style: AppTypography.caption(colors.textPrimary)
                        .copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingApprovalsSection extends StatelessWidget {
  const _PendingApprovalsSection({
    required this.requests,
    required this.onApprove,
    required this.onReject,
    required this.onViewAll,
  });

  final List<PendingRequestData> requests;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Pending approvals', onViewAll: onViewAll),
        const SizedBox(height: AppSpacing.md),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Text('No pending requests right now.',
                style: AppTypography.body(colors.textSecondary)),
          )
        else
          ...requests.map((request) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _PendingRequestCard(
                  request: request,
                  onApprove: () => onApprove(request.id),
                  onReject: () => onReject(request.id),
                ),
              )),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PENDING REQUEST CARD — Reject is a real destructive-style button (soft
// red tint, border, icon) instead of a bare outline; Approve is a solid
// gradient button with a shadow and check icon. Priority badge is color-
// coded (High = danger, Medium = warning, Low = success) instead of always
// purple.
// ---------------------------------------------------------------------------
class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final PendingRequestData request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  Color _priorityColor(AppColorsData colors) {
    switch (request.priority.toLowerCase()) {
      case 'high':
        return colors.danger;
      case 'medium':
        return colors.warning;
      default:
        return colors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pColor = _priorityColor(colors);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(request.employeeName,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: pColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(request.priority,
                    style: AppTypography.caption(pColor)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${request.requestedTool} · \$${request.monthlyCost.toInt()}/mo',
              style: AppTypography.caption(colors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScaleOnTap(
                  onTap: onReject,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.danger.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 16, color: colors.danger),
                        const SizedBox(width: 6),
                        Text('Reject',
                            style: AppTypography.caption(colors.danger)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScaleOnTap(
                  onTap: onApprove,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary]),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withOpacity(0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Approve',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetDetailRoute extends StatelessWidget {
  const _BudgetDetailRoute();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Budget details')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Budget overview',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(
                'Spend remains on plan, with forecasted growth in GitHub Copilot and Claude licensing.',
                style: AppTypography.body(colors.textSecondary)),
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
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load your dashboard',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
                style: AppTypography.body(colors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
