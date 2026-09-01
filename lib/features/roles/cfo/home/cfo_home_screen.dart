import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_home_cubit.dart';

/// ---------------------------------------------------------------------
/// Palette — sampled from the reference design
/// ---------------------------------------------------------------------

/// Semantic tokens straight from the Runrate design-system doc (Phase 1 —
/// Design Foundation). Keep all colors here; don't hardcode hex elsewhere.
class _Palette {
  static const primary = Color(0xFF6D5BFF);
  static const primaryLight = Color(0xFFEEF0FF);
  static const secondary = Color(0xFF4B8BFF);
  static const surface = Color(0xFFF8FAFC);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const border = Color(0xFFE5E7EB);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);

  // Component radii from the style guide.
  static const radiusButton = 12.0;
  static const radiusCard = 20.0;

  // Aliases used across this file for readability.
  static const gradientStart = primary;
  static const gradientEnd = secondary;
  static const scaffoldBg = surface;
  static const avatarBg = primaryLight;
  static const avatarText = primary;
  static const mutedText = textSecondary;
  static const cardBorder = border;

  // ---------------------------------------------------------------------
  // Futuristic accents — light "holo glass" surfaces used only by the
  // Department Breakdown and Recent Reports panels: white/frosted
  // backgrounds, gradient hairline borders, and glowing colored shadows
  // instead of a dark theme.
  // ---------------------------------------------------------------------
  static const panelBg = Color(0xFFFFFFFF);
  static const panelSurfaceAlt = Color(0xFFF4F6FE);
  static const neonCyan = Color(0xFF15B8D6);
  static const neonPink = Color(0xFFEC4899);
  static const glassStroke = Color(0xFFEBEDF7);
}

/// CFO · Home
/// "Runrate" dashboard — greeting header, gradient budget overview,
/// quick actions, stat cards, and recent reports — wired to
/// [CfoHomeCubit].
///
/// Note: bottom navigation (Home / AI / Teams / Approvals / More) is
/// assumed to live in the parent tab shell, not in this screen, so it
/// isn't duplicated here.
class CfoHomeScreen extends StatelessWidget {
  const CfoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoHomeCubit(),
      child: const _CfoHomeView(),
    );
  }
}

class _CfoHomeView extends StatelessWidget {
  const _CfoHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.scaffoldBg,
      body: SafeArea(
        child: BlocBuilder<CfoHomeCubit, CfoHomeState>(
          builder: (context, state) {
            if (state is CfoHomeLoading || state is CfoHomeInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoHomeError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoHomeCubit>().loadDashboard(),
              );
            }

            final loaded = state as CfoHomeLoaded;
            final data = loaded.data;
            return Stack(
              children: [
                RefreshIndicator(
                  onRefresh: () => context.read<CfoHomeCubit>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 0),
                          child: _GreetingTopBar(
                            userName: data.userName,
                            userInitials: data.userInitials,
                            roleLabel: data.roleLabel,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _OverviewGradientCard(
                            title: data.periodTitle,
                            statusLabel: data.budgetSummary.status.label,
                            summary: data.budgetSummary,
                            extraMetrics: data.extraMetrics,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _QuickActionsGrid(
                            costOptimization: data.costOptimization,
                            onAskAi: () {
                              // TODO: navigate to AI insights chat.
                            },
                            onTeamReport: () =>
                                context.read<CfoHomeCubit>().generateReport(),
                            onBudgetDetails: () {
                              // TODO: navigate to full department breakdown.
                            },
                            onCompare: () {
                              // TODO: navigate to department comparison.
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _StatCardsGrid(statCards: data.statCards),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _DepartmentBreakdownSection(
                            departments: data.departments,
                            onViewAll: () {
                              // TODO: navigate to full department breakdown.
                            },
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xl),
                          child: _RecentReportsSection(
                            reports: data.recentReports,
                            isGenerating: loaded.isGeneratingReport,
                            onGenerate: () =>
                                context.read<CfoHomeCubit>().generateReport(),
                            onDownload: (report) {
                              // TODO: download/export report.
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: AppSpacing.xl,
                  bottom: AppSpacing.lg,
                  child: _AiCopilotButton(
                    onTap: () {
                      // TODO: open AI copilot.
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Greeting top bar — avatar + "Good morning" + name + role/date, bell
/// ---------------------------------------------------------------------

class _GreetingTopBar extends StatelessWidget {
  const _GreetingTopBar({
    required this.userName,
    required this.userInitials,
    required this.roleLabel,
  });

  final String userName;
  final String userInitials;
  final String roleLabel;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _dateLabel {
    const weekdays = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun'
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _Palette.avatarBg,
            shape: BoxShape.circle,
          ),
          child: Text(
            userInitials,
            style: theme.textTheme.titleMedium?.copyWith(
              color: _Palette.avatarText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: _Palette.mutedText),
              ),
              Text(
                userName,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 2),
              Text(
                '$roleLabel · $_dateLabel',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: _Palette.mutedText),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            // TODO: navigate to notifications.
          },
          customBorder: const CircleBorder(),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _Palette.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: _Palette.cardBorder),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded,
                    color: _Palette.textPrimary, size: 20),
                Positioned(
                  top: 10,
                  right: 11,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: _Palette.danger,
                      shape: BoxShape.circle,
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

/// ---------------------------------------------------------------------
/// Gradient overview card — circular progress + spend pills + metric pills
/// ---------------------------------------------------------------------

class _OverviewGradientCard extends StatelessWidget {
  const _OverviewGradientCard({
    required this.title,
    required this.statusLabel,
    required this.summary,
    required this.extraMetrics,
  });

  final String title;
  final String statusLabel;
  final BudgetSummary summary;
  final List<OverviewMetric> extraMetrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_Palette.gradientStart, _Palette.gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _Palette.gradientEnd.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusPill(label: statusLabel),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CircularPercent(percent: summary.percentConsumed),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MetricPill(
                      label: 'Spend',
                      value: formatUsdCompact(summary.totalSpend,
                          forceExact: true),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _MetricPill(
                      label: 'Remaining',
                      value: formatUsdCompact(summary.remaining,
                          forceExact: true),
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
              for (final metric in extraMetrics)
                _MetricPill(
                    label: metric.label, value: metric.value, compact: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _Palette.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularPercent extends StatelessWidget {
  const _CircularPercent({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 9,
              backgroundColor: Colors.white.withOpacity(0.22),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    this.compact = false,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 14, vertical: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: compact ? 13 : 14,
            fontWeight: FontWeight.w500,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Quick actions — 2x2 grid of tappable tiles
/// ---------------------------------------------------------------------

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.costOptimization,
    required this.onAskAi,
    required this.onTeamReport,
    required this.onBudgetDetails,
    required this.onCompare,
  });

  final CostOptimizationInsight costOptimization;
  final VoidCallback onAskAi;
  final VoidCallback onTeamReport;
  final VoidCallback onBudgetDetails;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    final actions = <_QuickActionTile>[
      _QuickActionTile(
        icon: Icons.auto_awesome_rounded,
        label: 'Ask AI',
        subtitle: costOptimization.description,
        color: _Palette.primary,
        onTap: onAskAi,
      ),
      _QuickActionTile(
        icon: Icons.bar_chart_rounded,
        label: 'Team Report',
        subtitle: 'Generate a new report',
        color: _Palette.secondary,
        onTap: onTeamReport,
      ),
      _QuickActionTile(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Budget Details',
        subtitle: 'Spend and forecast',
        color: _Palette.success,
        onTap: onBudgetDetails,
      ),
      _QuickActionTile(
        icon: Icons.groups_2_outlined,
        label: 'Compare Depts',
        subtitle: 'Benchmark spend',
        color: _Palette.warning,
        onTap: onCompare,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 2.05,
      children: actions,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_Palette.radiusCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _Palette.surfaceElevated,
          borderRadius: BorderRadius.circular(_Palette.radiusCard),
          border: Border.all(color: _Palette.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: _Palette.mutedText),
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

/// ---------------------------------------------------------------------
/// Stat cards — 2x2 grid with a trend badge
/// ---------------------------------------------------------------------

class _StatCardsGrid extends StatelessWidget {
  const _StatCardsGrid({required this.statCards});

  final List<OverviewStatCard> statCards;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: [for (final card in statCards) _StatCard(card: card)],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.card});

  final OverviewStatCard card;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor =
        card.trendUp ? _Palette.success : _Palette.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _Palette.surfaceElevated,
        borderRadius: BorderRadius.circular(_Palette.radiusCard),
        border: Border.all(color: _Palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _Palette.avatarBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(card.icon, size: 17, color: _Palette.primary),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    card.trendUp
                        ? Icons.arrow_drop_up_rounded
                        : Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: trendColor,
                  ),
                  Text(
                    card.trendLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: trendColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(
            card.value,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            card.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: _Palette.mutedText),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Floating AI Copilot button
/// ---------------------------------------------------------------------

class _AiCopilotButton extends StatelessWidget {
  const _AiCopilotButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_Palette.gradientStart, _Palette.gradientEnd],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _Palette.gradientEnd.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'AI Copilot',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Shared animation helpers
/// ---------------------------------------------------------------------

/// Fades + slides a child in on mount, staggered by [index]. Give the
/// instance a fresh [Key] (e.g. tied to a filter or item id) whenever you
/// want the entrance to replay.
class _AnimatedEntrance extends StatefulWidget {
  const _AnimatedEntrance({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<_AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.14),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 55 * widget.index), () {
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

/// Icon button that scales down on press for a bit of tactile feedback.
/// Styled for the light "holo glass" panels (Recent Reports).
class _BouncyIconButton extends StatefulWidget {
  const _BouncyIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_BouncyIconButton> createState() => _BouncyIconButtonState();
}

class _BouncyIconButtonState extends State<_BouncyIconButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.85),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _Palette.panelSurfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: _Palette.neonCyan.withOpacity(0.35)),
          ),
          child: Icon(widget.icon, size: 17, color: _Palette.neonCyan),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Futuristic glass panel — shared "holo card" chrome for Department
/// Breakdown and Recent Reports: white surface, gradient hairline border,
/// and two soft glow blobs tinting opposite corners.
/// ---------------------------------------------------------------------

class _FuturisticPanel extends StatelessWidget {
  const _FuturisticPanel({required this.child, required this.glowColors});

  final Widget child;
  final List<Color> glowColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_Palette.radiusCard + 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            glowColors[0].withOpacity(0.55),
            glowColors[1].withOpacity(0.25),
            _Palette.glassStroke,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: glowColors[0].withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_Palette.radiusCard + 1),
        child: Container(
          decoration: const BoxDecoration(color: _Palette.panelBg),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: _GlowBlob(color: glowColors[0], size: 150),
              ),
              Positioned(
                bottom: -50,
                left: -40,
                child: _GlowBlob(color: glowColors[1], size: 170),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.14), color.withOpacity(0)],
          ),
        ),
      ),
    );
  }
}

/// Glowing gradient icon badge used in the panel headers.
class _PanelHeaderIcon extends StatelessWidget {
  const _PanelHeaderIcon({required this.icon, required this.colors});

  final IconData icon;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: colors),
        boxShadow: [
          BoxShadow(
              color: colors.last.withOpacity(0.4),
              blurRadius: 14,
              spreadRadius: 0.5),
        ],
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }
}

/// Small pulsing "live" indicator dot.
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});

  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

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
        final t = _controller.value;
        return SizedBox(
          width: 16,
          height: 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 6 + t * 10,
                height: 6 + t * 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity((1 - t) * 0.45),
                ),
              ),
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: widget.color),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// ---------------------------------------------------------------------
/// Department breakdown — filterable chips, expandable rows, glowing
/// gradient progress bars, presented as a white "holo glass" panel
/// ---------------------------------------------------------------------

enum _DeptFilter { all, overBudget }

class _DepartmentBreakdownSection extends StatefulWidget {
  const _DepartmentBreakdownSection({
    required this.departments,
    required this.onViewAll,
  });

  final List<DepartmentSpend> departments;
  final VoidCallback onViewAll;

  @override
  State<_DepartmentBreakdownSection> createState() =>
      _DepartmentBreakdownSectionState();
}

class _DepartmentBreakdownSectionState
    extends State<_DepartmentBreakdownSection> {
  _DeptFilter _filter = _DeptFilter.all;

  static const _accentPairs = [
    [_Palette.neonCyan, _Palette.primary],
    [_Palette.secondary, _Palette.neonCyan],
    [_Palette.warning, _Palette.neonPink],
    [_Palette.success, _Palette.neonCyan],
  ];

  @override
  Widget build(BuildContext context) {
    final overBudgetCount =
        widget.departments.where((d) => d.isOverBudget).length;
    final visible = _filter == _DeptFilter.all
        ? widget.departments
        : widget.departments.where((d) => d.isOverBudget).toList();

    return _FuturisticPanel(
      glowColors: const [_Palette.primary, _Palette.neonCyan],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            const  Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _PanelHeaderIcon(
                    icon: Icons.account_balance_wallet_outlined,
                    colors: [_Palette.primary, _Palette.neonCyan],
                  ),
                   SizedBox(width: AppSpacing.sm),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEPARTMENT BREAKDOWN',
                        style: TextStyle(
                          color: _Palette.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          _PulseDot(color: _Palette.neonCyan),
                          SizedBox(width: 2),
                          Text(
                            'LIVE SYNC',
                            style: TextStyle(
                              color: _Palette.mutedText,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              InkWell(
                onTap: widget.onViewAll,
                borderRadius: BorderRadius.circular(8),
                child:const Padding(
                  padding:
                       EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children:  [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: _Palette.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: _Palette.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _filter == _DeptFilter.all,
                onTap: () => setState(() => _filter = _DeptFilter.all),
              ),
              const SizedBox(width: AppSpacing.xs),
              _FilterChip(
                label: overBudgetCount > 0
                    ? 'Over Budget ($overBudgetCount)'
                    : 'Over Budget',
                selected: _filter == _DeptFilter.overBudget,
                accent: _Palette.neonPink,
                onTap: overBudgetCount == 0
                    ? null
                    : () => setState(() => _filter = _DeptFilter.overBudget),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: visible.isEmpty
                ? const Padding(
                    key: const ValueKey('empty'),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'No departments over budget 🎉',
                        style: TextStyle(color: _Palette.mutedText),
                      ),
                    ),
                  )
                : Column(
                    key: ValueKey(_filter),
                    children: [
                      for (var i = 0; i < visible.length; i++) ...[
                        _AnimatedEntrance(
                          key: ValueKey('${_filter}_${visible[i].name}'),
                          index: i,
                          child: _DepartmentRow(
                            department: visible[i],
                            accent: _accentPairs[
                                widget.departments.indexOf(visible[i]) %
                                    _accentPairs.length],
                          ),
                        ),
                        if (i != visible.length - 1)
                          const SizedBox(height: AppSpacing.sm),
                      ],
                    ],
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
    required this.onTap,
    this.accent,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? _Palette.primary;
    final disabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? color.withOpacity(0.12) : _Palette.panelSurfaceAlt,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : _Palette.glassStroke,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: color.withOpacity(0.25),
                        blurRadius: 10,
                        spreadRadius: 0.5),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: disabled
                  ? _Palette.mutedText.withOpacity(0.5)
                  : (selected ? color : _Palette.mutedText),
            ),
          ),
        ),
      ),
    );
  }
}

class _DepartmentRow extends StatefulWidget {
  const _DepartmentRow({required this.department, required this.accent});

  final DepartmentSpend department;
  final List<Color> accent;

  @override
  State<_DepartmentRow> createState() => _DepartmentRowState();
}

class _DepartmentRowState extends State<_DepartmentRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final department = widget.department;
    final overBudget = department.isOverBudget;
    final barColors =
        overBudget ? [_Palette.neonPink, _Palette.danger] : widget.accent;
    final variance = (department.budgeted - department.actual).abs();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _Palette.panelSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: overBudget
                ? _Palette.neonPink.withOpacity(0.4)
                : _Palette.glassStroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: barColors),
                    boxShadow: [
                      BoxShadow(
                          color: barColors.last.withOpacity(0.35),
                          blurRadius: 10),
                    ],
                  ),
                  child: Text(
                    department.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (overBudget) ...[
                            const Icon(Icons.warning_amber_rounded,
                                size: 14, color: _Palette.neonPink),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              department.name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: overBudget
                                    ? _Palette.neonPink
                                    : _Palette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${formatUsdCompact(department.actual)} / ${formatUsdCompact(department.budgeted)}',
                        style:const TextStyle(
                          color: _Palette.mutedText,
                          fontSize: 11.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${(department.progress * 100).round()}%',
                  style: TextStyle(
                    color: barColors.last,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: _Palette.mutedText),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: department.progress.clamp(0, 1).toDouble(),
              ),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 8,
                      color: _Palette.border,
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: barColors),
                          boxShadow: [
                            BoxShadow(
                              color: barColors.last.withOpacity(0.45),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: _Palette.panelBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _Palette.glassStroke),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DetailStat(
                                label: 'BUDGETED',
                                value: formatUsdCompact(department.budgeted,
                                    forceExact: true),
                              ),
                            ),
                            const _VerticalDivider(),
                            Expanded(
                              child: _DetailStat(
                                label: overBudget ? 'OVER BY' : 'REMAINING',
                                value: formatUsdCompact(variance,
                                    forceExact: true),
                                valueColor: overBudget
                                    ? _Palette.neonPink
                                    : _Palette.success,
                              ),
                            ),
                            const _VerticalDivider(),
                            Expanded(
                              child: _DetailStat(
                                label: 'USED',
                                value:
                                    '${(department.progress * 100).round()}%',
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),
          ],
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 30, color: _Palette.glassStroke);
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat(
      {required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:const TextStyle(
            color: _Palette.mutedText,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: valueColor ?? _Palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Recent reports — animated list with a holo skeleton while generating
/// ---------------------------------------------------------------------

class _RecentReportsSection extends StatefulWidget {
  const _RecentReportsSection({
    required this.reports,
    required this.isGenerating,
    required this.onGenerate,
    required this.onDownload,
  });

  final List<RecentReport> reports;
  final bool isGenerating;
  final VoidCallback onGenerate;
  final ValueChanged<RecentReport> onDownload;

  @override
  State<_RecentReportsSection> createState() => _RecentReportsSectionState();
}

class _RecentReportsSectionState extends State<_RecentReportsSection> {
  final _listKey = GlobalKey<AnimatedListState>();
  late List<RecentReport> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.reports);
  }

  @override
  void didUpdateWidget(covariant _RecentReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.reports;
    if (incoming.length > _items.length) {
      final newCount = incoming.length - _items.length;
      for (var i = 0; i < newCount; i++) {
        _items.insert(0, incoming[newCount - 1 - i]);
        _listKey.currentState?.insertItem(
          0,
          duration: const Duration(milliseconds: 380),
        );
      }
    } else if (incoming.length != _items.length) {
      _items = List.of(incoming);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FuturisticPanel(
      glowColors: const [_Palette.secondary, _Palette.neonPink],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
            const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   _PanelHeaderIcon(
                    icon: Icons.receipt_long_outlined,
                    colors: [_Palette.secondary, _Palette.neonPink],
                  ),
                   SizedBox(width: AppSpacing.sm),
                   Text(
                    'RECENT REPORTS',
                    style: TextStyle(
                      color: _Palette.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_Palette.secondary, _Palette.neonPink]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: _Palette.neonPink.withOpacity(0.35),
                        blurRadius: 10),
                  ],
                ),
                child: Text(
                  '${_items.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: widget.isGenerating
                ? const _GeneratingSkeleton(key: ValueKey('skeleton'))
                : const SizedBox.shrink(key: ValueKey('no-skeleton')),
          ),
          AnimatedList(
            key: _listKey,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: _items.length,
            itemBuilder: (context, index, animation) {
              final report = _items[index];
              return SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(
                  opacity: animation,
                  child: _AnimatedEntrance(
                    index: index,
                    child: _ReportRow(
                      report: report,
                      onDownload: () => widget.onDownload(report),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          _GenerateReportButton(
            isGenerating: widget.isGenerating,
            onGenerate: widget.onGenerate,
          ),
        ],
      ),
    );
  }
}

class _GeneratingSkeleton extends StatefulWidget {
  const _GeneratingSkeleton({super.key});

  @override
  State<_GeneratingSkeleton> createState() => _GeneratingSkeletonState();
}

class _GeneratingSkeletonState extends State<_GeneratingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _Palette.panelSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Palette.neonCyan.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_Palette.secondary, _Palette.neonCyan]),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: _Palette.neonCyan.withOpacity(0.35),
                      blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _ShimmerBar(
                      width: 150,
                      progress: _controller.value,
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => _ShimmerBar(
                      width: 90,
                      progress: _controller.value,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
         const Text(
              'SYNTHESIZING',
              style: TextStyle(
                color: _Palette.neonCyan,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A skeleton bar with a neon highlight sweeping across it, used while a
/// report is being generated.
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar({required this.width, required this.progress});

  final double width;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 10,
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            begin: Alignment(-1 + progress * 3, 0),
            end: Alignment(1 + progress * 3, 0),
            colors: const [
              _Palette.border,
              _Palette.neonCyan,
              _Palette.border,
            ],
            stops: const [0.35, 0.5, 0.65],
          ),
        ),
      ),
    );
  }
}

class _GenerateReportButton extends StatefulWidget {
  const _GenerateReportButton({
    required this.isGenerating,
    required this.onGenerate,
  });

  final bool isGenerating;
  final VoidCallback onGenerate;

  @override
  State<_GenerateReportButton> createState() => _GenerateReportButtonState();
}

class _GenerateReportButtonState extends State<_GenerateReportButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isGenerating;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _scale = 0.98),
      onTapUp: disabled ? null : (_) => setState(() => _scale = 1),
      onTapCancel: disabled ? null : () => setState(() => _scale = 1),
      onTap: disabled ? null : widget.onGenerate,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: disabled
                ? null
                : const LinearGradient(
                    colors: [_Palette.primary, _Palette.neonCyan]),
            color: disabled ? _Palette.panelSurfaceAlt : null,
            borderRadius: BorderRadius.circular(_Palette.radiusButton),
            border:
                disabled ? Border.all(color: _Palette.glassStroke) : null,
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                        color: _Palette.neonCyan.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6)),
                  ],
          ),
          child: widget.isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _Palette.primary),
                )
              : const Text(
                  'Generate New Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onDownload});

  final RecentReport report;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: _Palette.panelSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _Palette.glassStroke),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_Palette.primary, _Palette.neonCyan],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: _Palette.neonCyan.withOpacity(0.3),
                      blurRadius: 10),
                ],
              ),
              child: Icon(
                report.icon == ReportIcon.chart
                    ? Icons.bar_chart_rounded
                    : Icons.description_outlined,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: _Palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(report.generatedLabel,
                      style: const TextStyle(
                        color: _Palette.mutedText,
                        fontSize: 11.5,
                      )),
                ],
              ),
            ),
            _BouncyIconButton(
              icon: Icons.file_download_outlined,
              onTap: onDownload,
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Error state
/// ---------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
           const  Icon(Icons.error_outline,
                size: 40, color: _Palette.danger),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — compact USD ($1.2M, $600k, $1,200)
/// ---------------------------------------------------------------------

String formatUsdCompact(double value, {bool forceExact = false}) {
  final isNegative = value < 0;
  final v = value.abs();

  String formatted;
  if (!forceExact && v >= 1000000) {
    formatted = '${(v / 1000000).toStringAsFixed(1)}M';
  } else if (!forceExact && v >= 1000) {
    formatted = '${(v / 1000).round()}k';
  } else {
    formatted = _withThousandsSeparator(v.round());
  }

  return '${isNegative ? '-' : ''}\$$formatted';
}

String _withThousandsSeparator(int n) {
  final digits = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i != 0 && remaining % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}