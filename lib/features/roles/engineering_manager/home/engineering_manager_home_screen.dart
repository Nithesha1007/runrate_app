import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/engineering_manager/ai/engineering_manager_ai_screen.dart';
import 'package:runrate/features/roles/engineering_manager/approvals/engineering_manager_approvals_screen.dart';
import 'package:runrate/features/roles/engineering_manager/home/engineering_manager_home_cubit.dart';
import 'package:runrate/features/roles/engineering_manager/teams/engineering_manager_teams_screen.dart';
import 'package:runrate/features/roles/ceo/more/profile_cubit.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';

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
    return const Padding(
      padding:  EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
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
    required this.teamName,
    required this.todayLabel,
    required this.greeting,
    required this.hasUnread,
  });

  final String teamName;
  final String todayLabel;
  final String greeting;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final profile = context.watch<ProfileCubit>().state;
    final managerName = profile.name.isNotEmpty ? profile.name : 'Manager';
    final avatarUrl = profile.avatarUrl;
    final imageProvider = avatarUrl == null || avatarUrl.isEmpty
        ? null
        : (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')
            ? NetworkImage(avatarUrl)
            : FileImage(File(avatarUrl)) as ImageProvider);
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
                  backgroundImage: imageProvider,
                  child: Text(
                    imageProvider == null
                        ? managerName
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                            .toUpperCase()
                        : '',
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
// BRAND BADGE
//
// v2 — real logo images added for the tools that have a verified, official,
// square icon-only mark on Wikimedia Commons: ChatGPT, Claude, GitHub
// Copilot (via GitHub's Invertocat mark), and Gemini. Served through
// Commons' Special:FilePath redirector (`?width=200`), which 302-redirects
// to a rendered PNG thumbnail, so Image.network decodes it directly with no
// flutter_svg dependency.
//
// Cursor is deliberately kept on the original gradient Material-icon badge:
// the only Cursor mark on Commons (File:Cursor logo.svg) is a wide
// horizontal wordmark (800×195, tagged as a "text logo"), not a square
// icon — dropping a wordmark into a small circular badge would look
// squashed or unreadable, so the custom bolt-on-dark badge stays as the
// better real-world result here.
//
// Every logo keeps the gradient badge as its errorBuilder fallback, so a
// failed network request never leaves a blank circle.
// ---------------------------------------------------------------------------
class ToolBrand {
  const ToolBrand({
    required this.icon,
    required this.colors,
    this.logoUrl,
  });

  final IconData icon;
  final List<Color> colors; // gradient, 2 stops — also used as fallback bg
  final String? logoUrl;
}

const Map<String, ToolBrand> kToolBrands = {
  'Claude': ToolBrand(
    icon: Icons.auto_awesome_rounded,
    colors: [Color(0xFFD97757), Color(0xFFF2A67D)],
    logoUrl:
        'https://commons.wikimedia.org/wiki/Special:FilePath/Claude%20AI%20symbol.svg?width=200',
  ),
  'ChatGPT Enterprise': ToolBrand(
    icon: Icons.psychology_alt_rounded,
    colors: [Color(0xFF10A37F), Color(0xFF4FD1A5)],
    logoUrl:
        'https://commons.wikimedia.org/wiki/Special:FilePath/ChatGPT%20logo.svg?width=200',
  ),
  'GitHub Copilot': ToolBrand(
    icon: Icons.terminal_rounded,
    colors: [Color(0xFF24292F), Color(0xFF57606A)],
    logoUrl:
        'https://commons.wikimedia.org/wiki/Special:FilePath/GitHub%20Invertocat%20Logo.svg?width=200',
  ),
  'Cursor': ToolBrand(
    icon: Icons.bolt_rounded,
    colors: [Color(0xFF3B3B3B), Color(0xFF6E6E6E)],
    // No verified square icon on Commons — see note above. Stays icon-only.
  ),
  'Gemini': ToolBrand(
    icon: Icons.diamond_rounded,
    colors: [Color(0xFF4285F4), Color(0xFF9B72CB)],
    logoUrl:
        'https://commons.wikimedia.org/wiki/Special:FilePath/Google%20Gemini%20icon%202025.svg?width=200',
  ),
};

ToolBrand _brandFor(String name) =>
    kToolBrands[name] ??
    const ToolBrand(
      icon: Icons.smart_toy_rounded,
      colors: [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
    );

class _BrandBadge extends StatelessWidget {
  const _BrandBadge({required this.name, this.size = 40});
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = _brandFor(name);
    final logoUrl = brand.logoUrl;

    final gradientFallback = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: brand.colors,
        ),
        boxShadow: [
          BoxShadow(
            color: brand.colors.first.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(brand.icon, color: Colors.white, size: size * 0.5),
    );

    if (logoUrl == null) return gradientFallback;

    // Real logo: white circular plate (so transparent-background brand
    // marks read cleanly regardless of theme) with a thin ring and the
    // same soft brand-tinted shadow as the gradient badge, so both variants
    // sit at the same visual weight in a list.
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: brand.colors.first.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stack) => Icon(
            brand.icon,
            color: brand.colors.first,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO CARD
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
                color: colors.primary.withValues(alpha: 0.28 + t * 0.12),
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
                colors.primary.withValues(alpha: 0.85),
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
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation(
                                Colors.white.withValues(alpha: 0.18)),
                          ),
                        ),
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
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
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
        color: Colors.white.withValues(alpha: 0.12),
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
// QUICK ACTIONS
//
// v2 — "Ask AI" tile removed from this grid (it's a duplicate entry point:
// the AI copilot is reached from the bottom-nav AI tab). With 3 tiles left
// (Team Report, Budget Details, Compare AI Usage) the plain grid is
// replaced with the same asymmetric "advanced" layout used on the CEO
// home screen: the first action renders as a wide featured card with a
// gradient wash, a glowing icon badge, a short description line and a
// trailing arrow chip; the remaining two sit in a tighter two-up row below
// with the same gradient-badge treatment at a smaller scale.
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items, required this.onTap});

  final List<QuickActionItem> items;
  final ValueChanged<QuickActionItem> onTap;

  static const _accents = [
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF2994A), Color(0xFFF2C94C)],
  ];

  bool _isAskAi(QuickActionItem item) =>
      item.routeTag == 'ask_ai' ||
      item.routeTag == 'ai_copilot' ||
      item.title.toLowerCase().trim() == 'ask ai';

  @override
  Widget build(BuildContext context) {
    // Ask AI already lives permanently in the bottom nav — don't duplicate
    // it here.
    final visible = items.where((i) => !_isAskAi(i)).take(3).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final primary = visible.first;
    final rest = visible.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeaturedActionCard(
          item: primary,
          accent: _accents[0],
          onTap: () => onTap(primary),
        ),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: List.generate(rest.length, (i) {
              final item = rest[i];
              final accent = _accents[(i + 1) % _accents.length];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == rest.length - 1 ? 0 : AppSpacing.md),
                  child: _CompactActionCard(
                    item: item,
                    accent: accent,
                    onTap: () => onTap(item),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Wide featured tile for the primary quick action — gradient wash
/// background, glowing icon badge, and a trailing arrow chip.
class _FeaturedActionCard extends StatelessWidget {
  const _FeaturedActionCard({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  final QuickActionItem item;
  final List<Color> accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent[0].withValues(alpha: 0.12),
              accent[1].withValues(alpha: 0.06),
              colors.surfaceElevated,
            ],
          ),
          border: Border.all(color: accent[0].withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: accent[0].withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: accent),
                boxShadow: [
                  BoxShadow(
                    color: accent[0].withValues(alpha: 0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(item.title,
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent[0].withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  color: accent[0], size: 17),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smaller tile used for the two secondary quick actions in the row below
/// the featured card.
class _CompactActionCard extends StatelessWidget {
  const _CompactActionCard({
    required this.item,
    required this.accent,
    required this.onTap,
  });

  final QuickActionItem item;
  final List<Color> accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: accent[0].withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: accent),
                boxShadow: [
                  BoxShadow(
                    color: accent[0].withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(item.icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.title,
              style: AppTypography.body(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// KPI GRID
//
// v2 — the plain 2x2 grid of thin, cramped tiles (icon + label crammed on
// one line, number underneath) was replaced with an "advanced" KPI card
// (gradient icon badge, trend pill, big number, label) — but built as a
// GridView with a fixed `childAspectRatio`, the tile height was locked
// regardless of content, so it clipped/overflowed at the bottom on
// narrower screens.
//
// v3 — same visual language, but built as a plain Column of two Rows
// instead of a GridView. Each tile sizes itself to its own content
// (`mainAxisSize.min`, no forced aspect ratio), wrapped in
// `IntrinsicHeight` so the two tiles in a row still match each other's
// height. This can't overflow no matter the label length, and with
// tighter padding/icon/font sizes than before it also takes noticeably
// less vertical space overall. Team Members, Active AI Users, Active AI
// Tools, and Pending Approvals each keep a distinct accent so the grid
// doesn't read as four identical boxes.
// ---------------------------------------------------------------------------
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<KpiCardData> kpis;

  static const _accents = [
    [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFE85D75), Color(0xFFF2994A)],
  ];

  @override
  Widget build(BuildContext context) {
    final visible = kpis.take(4).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final rows = <List<int>>[];
    for (var i = 0; i < visible.length; i += 2) {
      rows.add([i, if (i + 1 < visible.length) i + 1]);
    }

    return Column(
      children: [
        for (var r = 0; r < rows.length; r++) ...[
          if (r != 0) const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < rows[r].length; c++) ...[
                  if (c != 0) const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _KpiTile(
                      kpi: visible[rows[r][c]],
                      accent: _accents[rows[r][c] % _accents.length],
                      delayMs: 300 + rows[r][c] * 70,
                    ),
                  ),
                ],
                if (rows[r].length == 1) const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(
      {required this.kpi, required this.accent, required this.delayMs});

  final KpiCardData kpi;
  final List<Color> accent;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isPositive = kpi.trendValue >= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 10), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: accent[0].withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(colors: accent),
                  ),
                  child: Icon(kpi.icon, color: Colors.white, size: 13),
                ),
                const Spacer(),
                if (kpi.trend.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive ? colors.success : colors.danger)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      kpi.trend,
                      style: AppTypography.caption(
                              isPositive ? colors.success : colors.danger)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 9),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _AnimatedCounterOrText(
              value: kpi.value,
              style: AppTypography.body(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 1),
            Text(
              kpi.label,
              style: AppTypography.caption(colors.textSecondary)
                  .copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

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

// ---------------------------------------------------------------------------
// BUDGET HEALTH CARD — redesigned. Segmented used/remaining bar with a
// "% used" caption, and three compact dot-labeled stats underneath instead
// of the old three-column layout stacked above a separate progress bar.
// ---------------------------------------------------------------------------
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
    final pct = (data.utilization * 100).round().clamp(0, 100);

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
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(_statusLabelFor(status),
                    style: AppTypography.caption(statusColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: data.utilization.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Row(
                  children: [
                    Expanded(
                      flex: (value * 1000).round().clamp(1, 999),
                      child: Container(color: statusColor),
                    ),
                    Expanded(
                      flex: (1000 - (value * 1000).round()).clamp(1, 999),
                      child: Container(color: colors.primaryLight),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('$pct% of budget used',
              style: AppTypography.caption(colors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _BudgetStat(
                    dotColor: statusColor,
                    label: 'Spend',
                    value: '\$${data.used.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _BudgetStat(
                    dotColor: colors.border,
                    label: 'Remaining',
                    value: '\$${data.remaining.toStringAsFixed(0)}'),
              ),
              Expanded(
                child: _BudgetStat(
                    dotColor: colors.secondary,
                    label: 'Forecast',
                    value: '${(data.forecast * 100).toInt()}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat(
      {required this.dotColor, required this.label, required this.value});

  final Color dotColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(label, style: AppTypography.caption(colors.textSecondary)),
          ],
        ),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.body(colors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700)),
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
          _BrandBadge(name: tool.name, size: 42),
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
                  valueColor: AlwaysStoppedAnimation(brand.colors.first),
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

// ---------------------------------------------------------------------------
// PENDING APPROVALS — glassy gradient corner ribbon for priority, requester
// avatar, tool brand badge, animated urgency pulse for High priority, and a
// bolder split-action row.
// ---------------------------------------------------------------------------
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
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
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

class _PendingRequestCard extends StatefulWidget {
  const _PendingRequestCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  final PendingRequestData request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  State<_PendingRequestCard> createState() => _PendingRequestCardState();
}

class _PendingRequestCardState extends State<_PendingRequestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  bool get _isHigh => widget.request.priority.toLowerCase() == 'high';

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

  Color _priorityColor(AppColorsData colors) {
    switch (widget.request.priority.toLowerCase()) {
      case 'high':
        return colors.danger;
      case 'medium':
        return colors.warning;
      default:
        return colors.success;
    }
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pColor = _priorityColor(colors);
    final request = widget.request;
    final brand = _brandFor(request.requestedTool);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: pColor.withValues(alpha: 0.28)),
            boxShadow: [
              BoxShadow(
                color: pColor.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.secondary],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initialsFor(request.employeeName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.employeeName,
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Requested ${request.requestDate}',
                            style: AppTypography.caption(colors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    _BrandBadge(name: request.requestedTool, size: 34),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.requestedTool,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text('\$${request.monthlyCost.toInt()}/mo',
                              style: AppTypography.caption(brand.colors.first)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(request.justification,
                  style: AppTypography.caption(colors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _ScaleOnTap(
                      onTap: widget.onReject,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.danger.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                              color: colors.danger.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded,
                                size: 16, color: colors.danger),
                            const SizedBox(width: 6),
                            Text('Reject',
                                style: AppTypography.caption(colors.danger)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: _ScaleOnTap(
                      onTap: widget.onApprove,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary]),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Corner priority ribbon — pulses gently for High priority.
        Positioned(
          top: -8,
          right: AppSpacing.md,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              final scale = _isHigh ? 1.0 + _pulse.value * 0.06 : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 5),
              decoration: BoxDecoration(
                color: pColor,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: pColor.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isHigh) ...[
                    const Icon(Icons.priority_high_rounded,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 2),
                  ],
                  Text(request.priority,
                      style: AppTypography.caption(Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
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
            OutlinedButton(onPressed: onRetry, child: const Text('Retry',)),
          ],
        ),
      ),
    );
  }
}