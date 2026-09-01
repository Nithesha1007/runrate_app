import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';


import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';

import 'employee_home_cubit.dart';

/// Runrate design-system tokens (see Design System & Style Guide).
/// TODO: move into /lib/theme if not already centralised there.
class RunrateColors {
  RunrateColors._();

  static const primary = Color(0xFF6D5BFF);
  static const primaryLight = Color(0xFFEEF0FF);
  static const secondary = Color(0xFF4B8BFF);
  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const border = Color(0xFFE9EAEE);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6D5BFF), Color(0xFF4B8BFF)],
  );

  // --- Accent palette used for icon chips / badges across the light
  // cards (budget / copilot / subscriptions / requests / alerts
  // sections) ------------------------------------------------------
  static const accentViolet = Color(0xFF8B5CF6);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentCyan = Color(0xFF0EA5E9);
  static const accentGreen = Color(0xFF22C55E);
  static const accentPink = Color(0xFFEC4899);

  static const auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentViolet, accentBlue, accentCyan],
  );
}

/// Body font (Inter) per the Runrate typography scale.
TextStyle rrText({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = RunrateColors.textPrimary,
  double? height,
}) {
  return GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

/// Heading font (Outfit) — reserved for hero / marketing-style content.
TextStyle rrHeading({
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.w700,
  Color color = Colors.white,
}) {
  return GoogleFonts.outfit(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

/// ---------------------------------------------------------------------
/// Shared light card shell — white surface with a subtle border and a
/// soft shadow, used by the Budget Health, AI Copilot, Active
/// Subscriptions, Request Status, and Recent Alerts sections.
/// ---------------------------------------------------------------------
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.colors,
    this.glowColor = RunrateColors.accentViolet,
  }) : padding = const EdgeInsets.all(AppSpacing.lg);

  final Widget child;
  final AppColorsData colors;
  final Color glowColor;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.06),
            blurRadius: 20,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Small pill used inside the light cards for a section eyebrow label,
/// e.g. "LIVE", "SYNCED", "AI".
class _NeonTag extends StatelessWidget {
  const _NeonTag({required this.label, this.color = RunrateColors.accentCyan});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: rrText(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Futuristic-but-light motion primitives, used by Active Subscriptions,
/// Request Status, and Recent Alerts to give those sections a livelier,
/// "connected" feel without switching to a dark theme.
/// ---------------------------------------------------------------------

/// White card with a slowly-rotating soft gradient border and a faint
/// tinted glow — the "futuristic" shell for the three animated sections.
class _FuturisticCard extends StatefulWidget {
  const _FuturisticCard({
    required this.child,
    required this.colors,
    this.glowColors = const [
      RunrateColors.accentViolet,
      RunrateColors.accentBlue,
      RunrateColors.accentCyan,
    ],
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final AppColorsData colors;
  final List<Color> glowColors;
  final EdgeInsets padding;

  @override
  State<_FuturisticCard> createState() => _FuturisticCardState();
}

class _FuturisticCardState extends State<_FuturisticCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: widget.glowColors.first.withOpacity(0.10),
            blurRadius: 26,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * 2 * math.pi;
          final begin = Alignment(math.cos(angle), math.sin(angle));
          final end = Alignment(-math.cos(angle), -math.sin(angle));
          return Container(
            padding: const EdgeInsets.all(1.4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(21),
              gradient: LinearGradient(
                begin: begin,
                end: end,
                colors: [
                  ...widget.glowColors.map((c) => c.withOpacity(0.55)),
                  widget.glowColors.first.withOpacity(0.55),
                ],
              ),
            ),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: widget.colors.surfaceElevated,
                borderRadius: BorderRadius.circular(19.6),
              ),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Small circular icon frame with a slowly spinning conic-gradient ring,
/// used for subscription logos to give them a "live sync" feel.
class _SpinningGradientRing extends StatefulWidget {
  const _SpinningGradientRing({
    required this.child,
    this.size = 38,
    this.colors = const [
      RunrateColors.accentViolet,
      RunrateColors.accentBlue,
      RunrateColors.accentCyan,
    ],
  });

  final Widget child;
  final double size;
  final List<Color> colors;

  @override
  State<_SpinningGradientRing> createState() => _SpinningGradientRingState();
}

class _SpinningGradientRingState extends State<_SpinningGradientRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
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
      builder: (context, child) {
        final angle = _controller.value * 2 * math.pi;
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(1.6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [...widget.colors, widget.colors.first],
              ),
            ),
            child: Transform.rotate(
              angle: -angle,
              child: child,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).brightness == Brightness.dark
              ? context.appColors.surfaceElevated
              : RunrateColors.surfaceElevated,
        ),
        child: widget.child,
      ),
    );
  }
}

/// A colored dot that emits a soft, radar-style pulse ring on a loop —
/// used for status indicators (subscription/request/alert freshness).
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
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
        final t = Curves.easeOut.transform(_controller.value);
        final ringScale = 1.0 + t * 2.2;
        final ringOpacity = (1 - t) * 0.45;
        return SizedBox(
          width: widget.size * 3.4,
          height: widget.size * 3.4,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(ringOpacity),
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
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

/// Gentle breathing scale/opacity loop for call-to-action badges that
/// want a little extra attention (e.g. "Verify" on an alert).
class _BreathingBadge extends StatefulWidget {
  const _BreathingBadge({required this.child});

  final Widget child;

  @override
  State<_BreathingBadge> createState() => _BreathingBadgeState();
}

class _BreathingBadgeState extends State<_BreathingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.97, end: 1.04)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}

/// Staggers a row's entrance with a fade + gentle upward slide — applied
/// to list rows so sections feel like they're animating into place.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Employee · Home
/// AI spend overview (gradient hero + progress ring), quick actions,
/// KPI stat cards, budget health, AI Copilot, active subscriptions,
/// request-a-tool CTA, request status, and recent alerts.
class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeHomeCubit(),
      child: const _EmployeeHomeView(),
    );
  }
}

class _EmployeeHomeView extends StatelessWidget {
  const _EmployeeHomeView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<EmployeeHomeCubit, EmployeeHomeState>(
          builder: (context, state) {
            if (state.status == EmployeeHomeStatus.loading &&
                state.employeeName.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }

            if (state.hasError && state.employeeName.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            return Stack(
              children: [
                RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () =>
                      context.read<EmployeeHomeCubit>().loadDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      100,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeHeader(state: state, colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _AiSpendHeroCard(state: state, colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _QuickActionsGrid(colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _StatCardsGrid(statCards: state.statCards, colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _BudgetHealthCard(state: state, colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _AiCopilotCard(colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _ActiveSubscriptionsCard(
                          subscriptions: state.subscriptions,
                          colors: colors,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _RequestNewToolBanner(colors: colors),
                        const SizedBox(height: AppSpacing.lg),
                        _RequestStatusCard(
                          requests: state.toolRequests,
                          colors: colors,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _RecentAlertsCard(alerts: state.alerts, colors: colors),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.xl,
                  bottom: AppSpacing.lg,
                  child: _AiCopilotFab(colors: colors),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.state, required this.colors});

  final EmployeeHomeState state;
  final AppColorsData colors;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: colors.primaryLight,
          child: Text(
            state.employeeInitials,
            style: rrText(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$_greeting, ${state.employeeName}',
                style: rrText(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      state.roleLabel,
                      style: rrText(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Your AI spend overview for this month',
                      style: rrText(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _NotificationBell(count: state.unreadNotifications, colors: colors),
      ],
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count, required this.colors});

  final int count;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 20,
            color: colors.textPrimary,
          ),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: colors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Gradient hero card — progress ring + pill-shaped stat chips, styled
/// after the "Engineering AI overview" card in the reference image.
/// ---------------------------------------------------------------------

class _AiSpendHeroCard extends StatelessWidget {
  const _AiSpendHeroCard({required this.state, required this.colors});

  final EmployeeHomeState state;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    final healthy = state.budgetHealthLabel == 'Healthy';
    final chipDotColor = healthy
        ? const Color(0xFF4ADE80)
        : (state.budgetHealthLabel == 'Near limit'
            ? RunrateColors.warning
            : RunrateColors.danger);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: RunrateColors.heroGradient,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'AI Tool Wallet',
                  style: rrHeading(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: chipDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.budgetHealthLabel,
                      style: rrText(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
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
                        value: state.budgetUsedFraction,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${state.budgetUsedPercent}%',
                      style: rrHeading(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroPillStat(
                      label: 'Assigned',
                      value: '\$${state.budgetAssigned.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _HeroPillStat(
                      label: 'Remaining',
                      value: '\$${state.budgetRemaining.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroPillStat(
                label: 'Used',
                value: '\$${state.budgetUsed.toStringAsFixed(0)}',
              ),
              _HeroPillStat(
                label: 'Subscriptions',
                value: '${state.subscriptions.length}',
              ),
              _HeroPillStat(
                label: 'Pending',
                value: '${state.toolRequests.where((r) => r.status == ToolRequestStatus.pending).length}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Wide, semi-transparent pill used for "Spend: $X" style stats in the
/// hero card, matching the reference image's chip styling.
class _HeroPillStat extends StatelessWidget {
  const _HeroPillStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: rrText(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.88),
              ),
            ),
            TextSpan(
              text: value,
              style: rrText(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Quick actions — 2x2 white cards with a gradient icon square + label,
/// matching "Ask AI / Team Report / Budget Details / Compare AI Usage".
/// ---------------------------------------------------------------------

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
}

class _QuickActionsGrid extends StatelessWidget {
  _QuickActionsGrid({required this.colors});

  final AppColorsData colors;

  final List<_QuickAction> _actions = const [
    _QuickAction(
      label: 'Ask AI',
      icon: Icons.auto_awesome_outlined,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF8B5CF6), Color(0xFF6D5BFF)],
      ),
    ),
    _QuickAction(
      label: 'My Wallet',
      icon: Icons.account_balance_wallet_outlined,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
      ),
    ),
    _QuickAction(
      label: 'Subscriptions',
      icon: Icons.subscriptions_outlined,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF10B981)],
      ),
    ),
    _QuickAction(
      label: 'Request Tool',
      icon: Icons.add_box_outlined,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.05,
      ),
      itemBuilder: (context, index) {
        final action = _actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            // TODO: navigate to the relevant feature (Ask AI / Wallet /
            // Subscriptions / Request Tool).
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: action.gradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, size: 19, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    action.label,
                    style: rrText(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------
/// Stat cards — small icon chip + label + trend badge on top row, big
/// bold value below, matching "Team Members · 18 ▲11%" styling.
/// ---------------------------------------------------------------------

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid({required this.statCards, required this.colors});

  final List<EmployeeStatCard> statCards;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    if (statCards.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: statCards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.7,
      ),
      itemBuilder: (context, index) {
        final stat = statCards[index];
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
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: RunrateColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(stat.icon, size: 14, color: RunrateColors.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stat.label,
                      style: rrText(fontSize: 12, color: RunrateColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (stat.trendLabel != null) ...[
                    Icon(
                      stat.trendUp
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: stat.trendUp
                          ? RunrateColors.success
                          : RunrateColors.danger,
                    ),
                    Text(
                      stat.trendLabel!,
                      style: rrText(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: stat.trendUp
                            ? RunrateColors.success
                            : RunrateColors.danger,
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              Text(
                stat.value,
                style: rrText(fontSize: 22, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetHealthCard extends StatelessWidget {
  const _BudgetHealthCard({required this.state, required this.colors});

  final EmployeeHomeState state;
  final AppColorsData colors;

  List<Color> get _barColors {
    if (state.budgetHealthLabel == 'Over budget') {
      return const [RunrateColors.danger, RunrateColors.accentPink];
    }
    if (state.budgetHealthLabel == 'Near limit') {
      return const [RunrateColors.warning, RunrateColors.accentPink];
    }
    return const [RunrateColors.accentGreen, RunrateColors.accentCyan];
  }

  @override
  Widget build(BuildContext context) {
    final barColors = _barColors;

    return _GlassCard(
      colors: colors,
      glowColor: RunrateColors.accentCyan,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: barColors),
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AI Budget Health',
                  style: rrText(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.textPrimary,
                  ),
                ),
              ),
              _NeonTag(label: state.budgetHealthLabel.toUpperCase(), color: barColors.first),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: 10,
                  color: RunrateColors.surface,
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FractionallySizedBox(
                  widthFactor: state.budgetUsedFraction,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: barColors),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${state.budgetUsed.toStringAsFixed(0)} of '
                '\$${state.budgetAssigned.toStringAsFixed(0)} used this month',
                style: rrText(
                  fontSize: 12,
                  color: RunrateColors.textSecondary,
                ),
              ),
              Text(
                '${state.budgetUsedPercent}%',
                style: rrText(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: barColors.first,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiCopilotCard extends StatelessWidget {
  const _AiCopilotCard({required this.colors});

  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      colors: colors,
      glowColor: RunrateColors.accentViolet,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: RunrateColors.auroraGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 17,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'AI Copilot',
                  style: rrText(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.textPrimary,
                  ),
                ),
              ),
              const _NeonTag(label: 'ONLINE', color: RunrateColors.accentGreen),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask me anything about your AI spend or compliance.',
            style: rrText(fontSize: 12, color: RunrateColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              // TODO: open the AI Copilot chat interface.
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: RunrateColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RunrateColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: RunrateColors.accentCyan,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Type a question...',
                      style: rrText(
                        fontSize: 13,
                        color: RunrateColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: RunrateColors.textSecondary.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating pill-shaped "AI Copilot" shortcut, positioned bottom-right
/// over the scroll content — matches the reference image's floating chip.
class _AiCopilotFab extends StatelessWidget {
  const _AiCopilotFab({required this.colors});

  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          // TODO: open the AI Copilot chat interface.
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF6D5BFF)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: RunrateColors.primary.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'AI Copilot',
                style: rrText(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSubscriptionsCard extends StatelessWidget {
  const _ActiveSubscriptionsCard({
    required this.subscriptions,
    required this.colors,
  });

  final List<EmployeeSubscription> subscriptions;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return _FuturisticCard(
      colors: colors,
      glowColors: const [
        RunrateColors.accentBlue,
        RunrateColors.accentCyan,
        RunrateColors.primary,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Active Subscriptions',
                  style: rrText(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.textPrimary,
                  ),
                ),
              ),
              const _NeonTag(label: 'SYNCED', color: RunrateColors.accentCyan),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                onTap: () {
                  // TODO: navigate to the full subscriptions list.
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: rrText(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: RunrateColors.primary,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: RunrateColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (subscriptions.isEmpty)
            Text(
              'No active subscriptions right now.',
              style: rrText(fontSize: 13, color: RunrateColors.textSecondary),
            )
          else
            for (var i = 0; i < subscriptions.length; i++) ...[
              _FadeSlideIn(
                delay: Duration(milliseconds: 70 * i),
                child: _SubscriptionRow(subscription: subscriptions[i]),
              ),
              if (i != subscriptions.length - 1) ...[
                const SizedBox(height: AppSpacing.sm),
            const    Divider(color: RunrateColors.border, height: 1),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
        ],
      ),
    );
  }
}

class _SubscriptionRow extends StatelessWidget {
  const _SubscriptionRow({required this.subscription});

  final EmployeeSubscription subscription;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SpinningGradientRing(
          size: 38,
          child: Icon(subscription.icon, size: 16, color: RunrateColors.primary),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subscription.name,
                style: rrText(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: RunrateColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subscription.planLabel,
                style: rrText(fontSize: 11, color: RunrateColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          subscription.priceLabel,
          style: rrText(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: RunrateColors.primary,
          ),
        ),
      ],
    );
  }
}

class _RequestNewToolBanner extends StatelessWidget {
  const _RequestNewToolBanner({required this.colors});

  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: RunrateColors.heroGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need a new AI tool?',
                  style: rrText(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Submit a request for approval.',
                  style: rrText(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: navigate to the new-tool request flow.
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: RunrateColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              elevation: 0,
            ),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              'Request',
              style: rrText(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: RunrateColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestStatusCard extends StatelessWidget {
  const _RequestStatusCard({required this.requests, required this.colors});

  final List<EmployeeToolRequest> requests;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) return const SizedBox.shrink();

    return _FuturisticCard(
      colors: colors,
      glowColors: const [
        RunrateColors.accentPink,
        RunrateColors.accentViolet,
        RunrateColors.accentBlue,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.radar_rounded,
                size: 17,
                color: RunrateColors.accentPink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Request Status',
                  style: rrText(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.textPrimary,
                  ),
                ),
              ),
              const _NeonTag(label: 'LIVE', color: RunrateColors.accentPink),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < requests.length; i++) ...[
            _FadeSlideIn(
              delay: Duration(milliseconds: 70 * i),
              child: _RequestStatusRow(request: requests[i]),
            ),
            if (i != requests.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _RequestStatusRow extends StatelessWidget {
  const _RequestStatusRow({required this.request});

  final EmployeeToolRequest request;

  Color get _glow {
    switch (request.status) {
      case ToolRequestStatus.approved:
        return RunrateColors.accentGreen;
      case ToolRequestStatus.pending:
        return RunrateColors.warning;
      case ToolRequestStatus.rejected:
        return RunrateColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: RunrateColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RunrateColors.border),
      ),
      child: Row(
        children: [
          _PulseDot(color: _glow, size: 7),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              request.toolName,
              style: rrText(fontSize: 13, color: RunrateColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _glow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _glow.withOpacity(0.3)),
            ),
            child: Text(
              request.status.label,
              style: rrText(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _glow,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAlertsCard extends StatelessWidget {
  const _RecentAlertsCard({required this.alerts, required this.colors});

  final List<EmployeeAlert> alerts;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return _FuturisticCard(
      colors: colors,
      glowColors: const [
        RunrateColors.accentBlue,
        RunrateColors.accentCyan,
        RunrateColors.accentViolet,
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
             const _SpinningGradientRing(
                size: 28,
                colors: const [
                  RunrateColors.accentBlue,
                  RunrateColors.accentCyan,
                ],
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 14,
                  color: RunrateColors.accentBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Recent Alerts',
                  style: rrText(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.textPrimary,
                  ),
                ),
              ),
              _NeonTag(label: '${alerts.length} NEW', color: RunrateColors.accentBlue),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < alerts.length; i++) ...[
            _FadeSlideIn(
              delay: Duration(milliseconds: 70 * i),
              child: _AlertRow(alert: alerts[i]),
            ),
            if (i != alerts.length - 1) ...[
              const SizedBox(height: AppSpacing.sm),
              Divider(color: RunrateColors.border, height: 1),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final EmployeeAlert alert;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _PulseDot(color: RunrateColors.accentCyan, size: 6),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: rrText(
                  fontSize: 12,
                  height: 1.4,
                  color: RunrateColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                alert.timeAgo,
                style: rrText(fontSize: 11, color: RunrateColors.textSecondary),
              ),
            ],
          ),
        ),
        if (alert.actionLabel != null) ...[
          const SizedBox(width: AppSpacing.sm),
          _BreathingBadge(
            child: InkWell(
              onTap: () {
                // TODO: handle the alert's action (e.g. verify receipt).
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: RunrateColors.accentBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: RunrateColors.accentBlue.withOpacity(0.3)),
                ),
                child: Text(
                  alert.actionLabel!,
                  style: rrText(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: RunrateColors.accentBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}