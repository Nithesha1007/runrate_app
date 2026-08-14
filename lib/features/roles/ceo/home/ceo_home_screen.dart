// ceo_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/home/ai_usage_details_screen.dart';
import 'package:runrate/features/roles/ceo/home/ceobudget_health_card.dart';
import 'dart:async';

import 'ceo_home_cubit.dart';

import '../shared/models/alert_model.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';

/// CEO Home dashboard — company-wide rollup across every department.
/// Section order: Header, Critical Alert banner, Company AI Overview hero,
/// Quick Actions, Key Executive Metrics (4-card KPI grid), AI Usage &
/// Adoption, Budget Health, Department Performance, AI Strategic Insights,
/// Executive Approvals, Today's Focus. Company Snapshot, Company Health
/// Score, and Recent Executive Decisions were removed — each duplicated a
/// number already shown elsewhere on this screen.
class CeoHomeScreen extends StatelessWidget {
  const CeoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoHomeCubit()..loadDashboard(),
      child: const _CeoHomeView(),
    );
  }
}

class _CeoHomeView extends StatefulWidget {
  const _CeoHomeView();

  @override
  State<_CeoHomeView> createState() => _CeoHomeViewState();
}

class _CeoHomeViewState extends State<_CeoHomeView>
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
        child: BlocConsumer<CeoHomeCubit, CeoHomeState>(
          listener: (context, state) {
            if (state is CeoHomeLoaded) {
              _pageController.forward(from: 0);
            }
          },
          builder: (context, state) {
            return switch (state) {
              CeoHomeInitial() || CeoHomeLoading() => const _LoadingView(),
              CeoHomeError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<CeoHomeCubit>().loadDashboard(),
                ),
              CeoHomeLoaded(:final data) => FadeTransition(
                  opacity: _pageFade,
                  child: RefreshIndicator(
                    color: colors.primary,
                    onRefresh: () => context.read<CeoHomeCubit>().refresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HomeHeader(
                            ceoName: data.ceoName,
                            companyName: data.companyName,
                            todayLabel: data.todayLabel,
                            greeting: data.greeting,
                            hasUnread: data.hasUnreadNotifications,
                            isOnline: data.isOnline,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _Staggered(
                            index: 0,
                            child: _AlertBanner(
                              alerts: data.alerts,
                              onAlertTap: (alert) =>
                                  _handleAlertTap(context, alert),
                            ),
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
                                  _handleQuickAction(context, item, data),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 2,
                            child: const _SectionHeader(
                                title: 'Key Executive Metrics'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _Staggered(
                            index: 2,
                            child: _KpiGrid(kpis: data.kpis),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 3,
                            child: _AiUsageAdoptionSection(
                              tools: data.aiToolUsage,
                              onViewAll: () =>
                                  _openAiUsageDetail(context),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 4,
                            child: CeoBudgetHealthCard(data: data.budgetHealth),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 5,
                            child: _DepartmentBreakdownSection(
                              departments: data.departments,
                              onTapDepartment: (dept) =>
                                  _openDepartmentDashboard(context, dept),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 6,
                            child: _StrategicInsightsSection(
                                insights: data.insights),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 7,
                            child: _EscalatedApprovalsSection(
                              requests: data.escalatedApprovals,
                              onApprove: (id) => context
                                  .read<CeoHomeCubit>()
                                  .approveEscalation(id),
                              onReject: (id, reason, note) => context
                                  .read<CeoHomeCubit>()
                                  .rejectEscalation(id,
                                      reason: reason, note: note),
                              onDelegate: (id, delegateTo) => context
                                  .read<CeoHomeCubit>()
                                  .delegateEscalation(id,
                                      delegateTo: delegateTo),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          _Staggered(
                            index: 8,
                            child: _TodaysFocusSection(focus: data.todaysFocus),
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

  void _handleQuickAction(
      BuildContext context, CeoQuickActionItem item, CeoHomeData data) {
    switch (item.routeTag) {
      case 'ask_ai':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Switch to the AI tab to chat with your copilot')),
        );
      case 'company_report':
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                _ExecutiveSummaryRoute(summary: data.aiExecutiveSummary)));
      case 'budget_forecast':
        _showComingSoon(context, 'Budget Forecast');
      case 'compare_departments':
        _showComingSoon(context, 'Compare Departments');
      default:
        break;
    }
  }

  void _handleAlertTap(BuildContext context, ExecutiveAlert alert) {
    if (alert.id == 'al2') {
      _openUnusedLicenses(context);
    } else {
      _showComingSoon(context, alert.title);
    }
  }

  void _openUnusedLicenses(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const _UnusedLicensesPlaceholderRoute(),
    ));
  }

  void _openAiUsageDetail(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AiUsageDetailScreen(),
    ));
  }

  void _openDepartmentDashboard(BuildContext context, DepartmentSummary dept) {
    _showComingSoon(context, '${dept.name} dashboard');
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon')),
    );
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
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 700)),
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
          _ShimmerCard(height: 60),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 220),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 84),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 160),
          SizedBox(height: AppSpacing.md),
          _ShimmerCard(height: 130),
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

// ---------------------------------------------------------------------------
// HEADER — avatar with online-status dot, greeting, notification bell +
// settings icon.
// ---------------------------------------------------------------------------
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.ceoName,
    required this.companyName,
    required this.todayLabel,
    required this.greeting,
    required this.hasUnread,
    required this.isOnline,
  });

  final String ceoName;
  final String companyName;
  final String todayLabel;
  final String greeting;
  final bool hasUnread;
  final bool? isOnline;

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
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Hero(
                      tag: 'ceo-avatar',
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: colors.primaryLight,
                        child: Text(
                          ceoName
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: AppTypography.h3(colors.primary),
                        ),
                      ),
                    ),
                    if (isOnline == true)
                      Positioned(
                        bottom: -1,
                        right: -1,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors.success,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: colors.background, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting,
                        style: AppTypography.caption(colors.textSecondary)),
                    Text(ceoName,
                        style: AppTypography.h3(colors.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$companyName · $todayLabel',
                        style: AppTypography.caption(colors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(RouteNames.notifications),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: Icon(Icons.notifications_outlined,
                    color: colors.textPrimary, size: 20),
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
        const SizedBox(width: AppSpacing.sm),
        GestureDetector(
          onTap: () => Navigator.of(context).pushNamed(RouteNames.security),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Icon(Icons.settings_outlined,
                color: colors.textPrimary, size: 20),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// EXECUTIVE ALERT BANNER — one alert visible at a time, auto-advances every
// few seconds, swipeable, dot indicator underneath, tappable → drills into
// the relevant screen (e.g. unused licenses).
// ---------------------------------------------------------------------------
class _AlertBanner extends StatefulWidget {
  const _AlertBanner({required this.alerts, required this.onAlertTap});
  final List<ExecutiveAlert> alerts;
  final ValueChanged<ExecutiveAlert> onAlertTap;

  @override
  State<_AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<_AlertBanner> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    if (widget.alerts.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.alerts.length;
        _controller.animateToPage(next,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color _colorFor(AppColorsData colors, AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.warning:
        return colors.warning;
      case AlertSeverity.critical:
        return colors.danger;
      case AlertSeverity.positive:
        return colors.success;
      case AlertSeverity.info:
        return colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.alerts.isEmpty) return const SizedBox.shrink();
    final colors = AppColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 56,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.alerts.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final alert = widget.alerts[i];
              final color = _colorFor(colors, alert.severity);
              return _ScaleOnTap(
                onTap: () => widget.onAlertTap(alert),
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(alert.icon, color: color, size: 18),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            alert.title,
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: color, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.alerts.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.alerts.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? colors.primary : colors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
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
// DEPARTMENT BRAND MAP
// ---------------------------------------------------------------------------
class DeptBrand {
  const DeptBrand({
    required this.initials,
    required this.color,
    required this.bg,
    required this.imageUrl,
  });

  final String initials;
  final Color color;
  final Color bg;
  final String imageUrl;
}

const Map<String, DeptBrand> kDeptBrands = {
  'Engineering': DeptBrand(
    initials: 'EN',
    color: Color(0xFF6C5CE7),
    bg: Color(0xFFEFECFD),
    imageUrl:
        'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=200&h=200&fit=crop&auto=format',
  ),
  'Marketing': DeptBrand(
    initials: 'MK',
    color: Color(0xFFE85D75),
    bg: Color(0xFFFCEAEE),
    imageUrl:
        'https://images.unsplash.com/photo-1533750349088-cd871a92f312?w=200&h=200&fit=crop&auto=format',
  ),
  'Sales': DeptBrand(
    initials: 'SA',
    color: Color(0xFF2F80ED),
    bg: Color(0xFFE8F0FE),
    imageUrl:
        'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=200&h=200&fit=crop&auto=format',
  ),
  'Operations': DeptBrand(
    initials: 'OP',
    color: Color(0xFFF2994A),
    bg: Color(0xFFFDF1E5),
    imageUrl:
        'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=200&h=200&fit=crop&auto=format',
  ),
  'Finance': DeptBrand(
    initials: 'FN',
    color: Color(0xFF11998E),
    bg: Color(0xFFE3F6F4),
    imageUrl:
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=200&h=200&fit=crop&auto=format',
  ),
  'HR': DeptBrand(
    initials: 'HR',
    color: Color(0xFF9B51E0),
    bg: Color(0xFFF3E9FC),
    imageUrl:
        'https://images.unsplash.com/photo-1521791136064-7986c2920216?w=200&h=200&fit=crop&auto=format',
  ),
  'Customer Success': DeptBrand(
    initials: 'CS',
    color: Color(0xFF11998E),
    bg: Color(0xFFE6F6F4),
    imageUrl:
        'https://images.unsplash.com/photo-1553775282-20af80779df7?w=200&h=200&fit=crop&auto=format',
  ),
};

DeptBrand _deptBrandFor(String name) =>
    kDeptBrands[name] ??
    const DeptBrand(
      initials: 'DP',
      color: Color(0xFF6C5CE7),
      bg: Color(0xFFEFECFD),
      imageUrl: '',
    );

class _DeptAvatar extends StatelessWidget {
  const _DeptAvatar({required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final brand = _deptBrandFor(name);
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: brand.imageUrl.isEmpty
          ? _fallback(brand)
          : Image.network(
              brand.imageUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => _fallback(brand),
            ),
    );
  }

  Widget _fallback(DeptBrand brand) {
    return Container(
      width: size,
      height: size,
      color: brand.bg,
      alignment: Alignment.center,
      child: Text(
        brand.initials,
        style: TextStyle(
          color: brand.color,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO CARD — Budget Used %, AI Health Score /100, Total AI Spend,
// Remaining Budget, AI ROI, Active AI Users. (Productivity pill removed —
// not part of the approved metric list and not shown anywhere else.)
// ---------------------------------------------------------------------------
class _HeroOverviewCard extends StatelessWidget {
  const _HeroOverviewCard({required this.data});
  final CeoHomeData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final progress = (data.budgetUtilization * 100).round();
    final status = _statusFor(data.budgetUtilization);
    final statusColor = switch (status) {
      _BudgetStatus.healthy => colors.success,
      _BudgetStatus.warning => colors.warning,
      _BudgetStatus.critical => colors.danger,
    };

    return ClipRRect(
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
                  child: Text('Company AI overview',
                      style: AppTypography.h3(Colors.white)),
                ),
                _StatusPill(label: _statusLabelFor(status), color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 92,
                        height: 92,
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
                            width: 92,
                            height: 92,
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
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AnimatedCounterText(
                            target: progress,
                            suffix: '%',
                            style: AppTypography.h3(Colors.white),
                          ),
                          Text('budget',
                              style: AppTypography.caption(
                                  Colors.white.withValues(alpha: 0.75))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AnimatedCounterText(
                            target: data.overallHealthScore,
                            style: AppTypography.h1(Colors.white),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 3),
                            child: Text('/100',
                                style: AppTypography.caption(
                                    Colors.white.withValues(alpha: 0.75))),
                          ),
                        ],
                      ),
                      Text('AI health score',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _StatChip(
                    label: 'Spend', value: '\$${_compact(data.totalSpend)}'),
                _StatChip(
                    label: 'Remaining',
                    value: '\$${_compact(data.remainingBudget)}'),
                _MetricPill(label: 'AI ROI', value: '${data.roiScore.toInt()}'),
                _MetricPill(
                    label: 'Active users', value: '${data.totalActiveUsers}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
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
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        Expanded(
            child: Text(title, style: AppTypography.h3(colors.textPrimary))),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// QUICK ACTIONS
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items, required this.onTap});

  final List<CeoQuickActionItem> items;
  final ValueChanged<CeoQuickActionItem> onTap;

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
          childAspectRatio: 1.4,
          children: List.generate(visible.length, (i) {
            final item = visible[i];
            final accent = _accents[i % _accents.length];
            return _ScaleOnTap(
              onTap: () => onTap(item),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(colors: accent),
                      ),
                      child: Icon(item.icon, color: Colors.white, size: 16),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.title,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 2,
                      softWrap: true,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: AppTypography.caption(colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

// ---------------------------------------------------------------------------
// KEY EXECUTIVE METRICS — exactly 4 cards: Total AI Spend, Active AI Users,
// AI Adoption %, Unused Licenses.
// ---------------------------------------------------------------------------
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<CeoKpiCardData> kpis;

  static const _accents = [
    Color(0xFF6C5CE7),
    Color(0xFF2F80ED),
    Color(0xFF11998E),
    Color(0xFFE85D75),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = kpis.take(4).toList();
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.15,
      children: List.generate(visible.length, (i) {
        final kpi = visible[i];
        final accent = _accents[i % _accents.length];
        final isPositive = kpi.trendValue >= 0;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 400 + i * 60),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(scale: 0.92 + 0.08 * value, child: child),
          ),
          child: Container(
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
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(kpi.icon, color: accent, size: 16),
                    ),
                    const Spacer(),
                    if (kpi.trendValue != 0)
                      Text(kpi.trend,
                          style: AppTypography.caption(
                              isPositive ? colors.success : colors.danger)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(kpi.value, style: AppTypography.h3(colors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  kpi.label,
                  style: AppTypography.caption(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  kpi.subtitle,
                  style: AppTypography.caption(colors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------
// AI USAGE & ADOPTION — top tools with user count, usage level, spend.
// Lives on its own, not inside Department Performance.
//
// v2 — the old layout crammed name / users / level pill / spend into one
// horizontal row per tool, which got tight enough on narrower screens that
// it read as cluttered rather than scannable. This redesign gives each tool
// its own card: icon (color-coded by usage level) + name + spend up top,
// user count + level pill below, and a level-colored mini progress bar
// along the bottom — the same visual language as the tool cards on the
// full AI Usage detail screen, just condensed to fit four on Home.
// ---------------------------------------------------------------------------
class _AiUsageAdoptionSection extends StatelessWidget {
  const _AiUsageAdoptionSection({
    required this.tools,
    required this.onViewAll,
  });

  final List<AiToolUsage> tools;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = tools.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'AI Usage & Adoption')),
            _ScaleOnTap(
              onTap: onViewAll,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View all',
                      style: AppTypography.caption(colors.primary)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.primary, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _AiUsageToolCard(tool: visible[i], rank: i + 1),
          ),
      ],
    );
  }
}

IconData _iconForAiTool(String name) {
  final n = name.toLowerCase();
  if (n.contains('chatgpt')) return Icons.chat_bubble_rounded;
  if (n.contains('copilot')) return Icons.code_rounded;
  if (n.contains('claude')) return Icons.auto_awesome_rounded;
  if (n.contains('gemini')) return Icons.diamond_outlined;
  return Icons.smart_toy_rounded;
}

/// (vendor, category) shown as a subtitle under the tool name — turns a
/// bare tool name into something that reads like a real software catalog
/// entry, matching the reference "Tool Utilization" cards.
(String, String) _vendorCategoryForAiTool(String name) {
  final n = name.toLowerCase();
  if (n.contains('chatgpt')) return ('OpenAI', 'Generative AI');
  if (n.contains('copilot')) return ('Microsoft', 'Dev Tools');
  if (n.contains('claude')) return ('Anthropic', 'Generative AI');
  if (n.contains('gemini')) return ('Google', 'Generative AI');
  return ('Third-party', 'AI Tool');
}

/// AI Usage tool card — v2.
///
/// The plain "name / spend / users / level pill / bar" layout worked but
/// read as a basic list row rather than a proper catalog entry. This
/// version adds: a rank badge (spend-ranked, since `tools` already arrives
/// sorted by spend from the cubit), a vendor • category subtitle under the
/// name (via `_vendorCategoryForAiTool`), a three-column stat row (Users /
/// Adoption / Cost per user — adoption and cost-per-user are derived from
/// `usageLevel` and `spend`/`userCount` since the Home summary model
/// doesn't carry a raw adoption rate), and a gradient (not flat) progress
/// bar. This is the same information density as the tool cards on the full
/// AI Usage detail screen, condensed to fit four on Home.
class _AiUsageToolCard extends StatelessWidget {
  const _AiUsageToolCard({required this.tool, required this.rank});
  final AiToolUsage tool;
  final int rank;

  Color _levelColor(AppColorsData colors) {
    switch (tool.usageLevel) {
      case AiUsageLevel.high:
        return colors.success;
      case AiUsageLevel.medium:
        return colors.warning;
      case AiUsageLevel.low:
        return colors.danger;
    }
  }

  String _levelLabel() {
    switch (tool.usageLevel) {
      case AiUsageLevel.high:
        return 'High';
      case AiUsageLevel.medium:
        return 'Medium';
      case AiUsageLevel.low:
        return 'Low';
    }
  }

  double get _adoptionFraction => switch (tool.usageLevel) {
        AiUsageLevel.high => 0.88,
        AiUsageLevel.medium => 0.55,
        AiUsageLevel.low => 0.24,
      };

  double get _costPerUser => tool.userCount == 0 ? 0 : tool.spend / tool.userCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final levelColor = _levelColor(colors);
    final (vendor, category) = _vendorCategoryForAiTool(tool.toolName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(_iconForAiTool(tool.toolName),
                        color: levelColor, size: 20),
                  ),
                  Positioned(
                    top: -6,
                    left: -6,
                    child: Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.textPrimary,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surfaceElevated, width: 2),
                      ),
                      child: Text(
                        '$rank',
                        style: AppTypography.caption(colors.surfaceElevated)
                            .copyWith(fontWeight: FontWeight.w800, fontSize: 9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.toolName,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$vendor · $category',
                      style: AppTypography.caption(colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${_compact(tool.spend)}',
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_levelLabel(),
                        style: AppTypography.caption(levelColor)
                            .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    label: 'Users',
                    value: '${tool.userCount}',
                    colors: colors,
                  ),
                ),
                Container(width: 1, height: 22, color: colors.border),
                Expanded(
                  child: _MiniStat(
                    label: 'Adoption',
                    value: '${(_adoptionFraction * 100).toInt()}%',
                    colors: colors,
                  ),
                ),
                Container(width: 1, height: 22, color: colors.border),
                Expanded(
                  child: _MiniStat(
                    label: 'Cost/user',
                    value: '\$${_costPerUser.toStringAsFixed(0)}',
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Container(color: colors.border),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _adoptionFraction),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              levelColor,
                              levelColor.withValues(alpha: 0.65),
                            ],
                          ),
                        ),
                      ),
                    ),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.colors});
  final String label;
  final String value;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value,
            style: AppTypography.caption(colors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700)),
        Text(label, style: AppTypography.caption(colors.textSecondary).copyWith(fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DEPARTMENT PERFORMANCE — image, name, headcount, spend, adoption/health
// ring, animated spend-vs-budget progress bar, status badge, View Details.
// Top-tool line removed — tool usage now lives only in the AI Usage &
// Adoption section.
// ---------------------------------------------------------------------------
class _DepartmentBreakdownSection extends StatelessWidget {
  const _DepartmentBreakdownSection({
    required this.departments,
    required this.onTapDepartment,
  });

  final List<DepartmentSummary> departments;
  final ValueChanged<DepartmentSummary> onTapDepartment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Department performance'),
        const SizedBox(height: AppSpacing.md),
        ...departments.map((dept) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _DepartmentCard(
                dept: dept,
                onTap: () => onTapDepartment(dept),
              ),
            )),
      ],
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  const _DepartmentCard({required this.dept, required this.onTap});

  final DepartmentSummary dept;
  final VoidCallback onTap;

  IconData get _trendIcon => switch (dept.trend) {
        DepartmentTrend.up => Icons.trending_up_rounded,
        DepartmentTrend.down => Icons.trending_down_rounded,
        DepartmentTrend.flat => Icons.trending_flat_rounded,
      };

  Color _trendColor(AppColorsData colors) => switch (dept.trend) {
        DepartmentTrend.up => colors.success,
        DepartmentTrend.down => colors.danger,
        DepartmentTrend.flat => colors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final brand = _deptBrandFor(dept.name);
    final status = _statusFor(dept.utilization);
    final statusColor = switch (status) {
      _BudgetStatus.healthy => colors.success,
      _BudgetStatus.warning => colors.warning,
      _BudgetStatus.critical => colors.danger,
    };

    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
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
                _DeptAvatar(name: dept.name, size: 44),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(dept.name,
                                style: AppTypography.body(colors.textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Icon(_trendIcon,
                              size: 16, color: _trendColor(colors)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${dept.headName} · ${dept.headcount} people',
                          style: AppTypography.caption(colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                          '\$${_compact(dept.spend)} of \$${_compact(dept.budget)}',
                          style: AppTypography.caption(colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
                        value: dept.adoptionRate.clamp(0, 1),
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colors.border,
                        valueColor: AlwaysStoppedAnimation(brand.color),
                      ),
                      Text('${(dept.adoptionRate * 100).toInt()}',
                          style: AppTypography.caption(colors.textPrimary)
                              .copyWith(
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------
            // Animated department spend-vs-budget progress bar. Uses the
            // same statusColor (healthy/warning/critical) as the badge
            // below, and the same TweenAnimationBuilder pattern as the
            // company-wide budget health card for a consistent feel.
            // -----------------------------------------------------------
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(
                        begin: 0.0,
                        end: dept.utilization.clamp(0.0, 1.0),
                      ),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 6,
                        color: statusColor,
                        backgroundColor: colors.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(dept.utilization * 100).toInt()}%',
                  style: AppTypography.caption(statusColor)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_statusLabelFor(status),
                      style: AppTypography.caption(statusColor)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                _ScaleOnTap(
                  onTap: onTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View details',
                          style: AppTypography.caption(colors.primary)
                              .copyWith(fontWeight: FontWeight.w700)),
                      Icon(Icons.chevron_right_rounded,
                          color: colors.primary, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI STRATEGIC INSIGHTS — top 3 only, each with icon + priority badge +
// timestamp + Read more.
// ---------------------------------------------------------------------------
class _StrategicInsightsSection extends StatelessWidget {
  const _StrategicInsightsSection({required this.insights});

  final List<StrategicInsightData> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'AI strategic insights'),
        const SizedBox(height: AppSpacing.md),
        ...insights.take(3).map((insight) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _InsightCard(insight: insight),
            )),
      ],
    );
  }
}

class _InsightCard extends StatefulWidget {
  const _InsightCard({required this.insight});

  final StrategicInsightData insight;

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _expanded = false;

  ({Color color, String label}) _style(AppColorsData colors) {
    switch (widget.insight.impact) {
      case StrategicImpact.costSaving:
        return (color: colors.success, label: 'Cost saving');
      case StrategicImpact.risk:
        return (color: colors.danger, label: 'Risk');
      case StrategicImpact.growth:
        return (color: colors.primary, label: 'Growth');
    }
  }

  Color _priorityColor(AppColorsData colors) {
    switch (widget.insight.priority.toLowerCase()) {
      case 'high':
        return colors.danger;
      case 'medium':
        return colors.warning;
      default:
        return colors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final s = _style(colors);
    final insight = widget.insight;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: s.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(insight.icon, color: s.color, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(insight.title,
                          style: AppTypography.body(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: s.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child:
                          Text(s.label, style: AppTypography.caption(s.color)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(insight.description,
                    style: AppTypography.caption(colors.textSecondary),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _priorityColor(colors).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(insight.priority.toUpperCase(),
                          style: AppTypography.caption(_priorityColor(colors))
                              .copyWith(
                                  fontWeight: FontWeight.w700, fontSize: 10)),
                    ),
                    const SizedBox(width: 6),
                    Text(insight.timestampLabel,
                        style: AppTypography.caption(colors.textSecondary)),
                    const Spacer(),
                    _ScaleOnTap(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Text(_expanded ? 'Show less' : 'Read more',
                          style: AppTypography.caption(s.color)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
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
// EXECUTIVE APPROVALS — vendor, purpose, monthly/annual cost, risk badge,
// reason, Approve / Reject / View Details / Delegate.
// ---------------------------------------------------------------------------
class _EscalatedApprovalsSection extends StatelessWidget {
  const _EscalatedApprovalsSection({
    required this.requests,
    required this.onApprove,
    required this.onReject,
    required this.onDelegate,
  });

  final List<EscalatedApprovalData> requests;
  final ValueChanged<String> onApprove;
  final void Function(String id, String reason, String? note) onReject;
  final void Function(String id, String delegateTo) onDelegate;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Executive approvals'),
        const SizedBox(height: AppSpacing.md),
        if (requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: Text('Nothing needs your sign-off right now.',
                style: AppTypography.body(colors.textSecondary)),
          )
        else
          ...requests.map((request) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _EscalatedApprovalCard(
                  request: request,
                  onApprove: () => onApprove(request.id),
                  onReject: (reason, note) =>
                      onReject(request.id, reason, note),
                  onDelegate: (delegateTo) =>
                      onDelegate(request.id, delegateTo),
                ),
              )),
      ],
    );
  }
}

class _EscalatedApprovalCard extends StatelessWidget {
  const _EscalatedApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
    required this.onDelegate,
  });

  final EscalatedApprovalData request;
  final VoidCallback onApprove;
  final void Function(String reason, String? note) onReject;
  final ValueChanged<String> onDelegate;

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

  Color _riskColor(AppColorsData colors) {
    switch (request.riskLevel.toLowerCase()) {
      case 'high':
        return colors.danger;
      case 'medium':
        return colors.warning;
      default:
        return colors.success;
    }
  }

  Future<void> _openRejectSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_RejectResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RejectReasonSheet(toolName: request.tool),
    );
    if (result != null) {
      onReject(result.reason, result.note);
    }
  }

  Future<void> _openDelegateSheet(BuildContext context) async {
    final colors = AppColors.of(context);
    const delegates = [
      'CFO — Marcus Bell',
      'COO — Rita Alvarez',
      'VP Eng — Priya Nair'
    ];
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Delegate this approval',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            for (final d in delegates)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _ScaleOnTap(
                  onTap: () => Navigator.of(sheetContext).pop(d),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colors.border),
                    ),
                    child: Text(d,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (choice != null) onDelegate(choice);
  }

  void _openDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(request.tool),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor: ${request.vendor}'),
            const SizedBox(height: 6),
            Text('Purpose: ${request.purpose}'),
            const SizedBox(height: 6),
            Text(
                'Monthly: \$${request.monthlyCost.toInt()} · Annual: \$${request.annualCost.toInt()}'),
            const SizedBox(height: 6),
            Text('Risk level: ${request.riskLevel}'),
            const SizedBox(height: 6),
            Text('Why CEO approval: ${request.reason}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pColor = _priorityColor(colors);
    final rColor = _riskColor(colors);
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
              _DeptAvatar(name: request.department, size: 32),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.department,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Requested by ${request.requestedBy}',
                        style: AppTypography.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 3),
                decoration: BoxDecoration(
                  color: pColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(request.priority,
                    style: AppTypography.caption(pColor)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('${request.tool} · ${request.vendor}',
              style: AppTypography.body(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(request.purpose,
              style: AppTypography.caption(colors.textSecondary)),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: 6,
            children: [
              Text(
                  '\$${request.monthlyCost.toInt()}/mo · \$${request.annualCost.toInt()}/yr',
                  style: AppTypography.caption(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: rColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${request.riskLevel} risk',
                    style: AppTypography.caption(rColor)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ScaleOnTap(
                  onTap: () => _openRejectSheet(context),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: colors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: colors.danger),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ScaleOnTap(
                  onTap: () => _openDetails(context),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Icon(Icons.visibility_outlined,
                        size: 16, color: colors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: _ScaleOnTap(
                  onTap: () => _openDelegateSheet(context),
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.info.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: colors.info.withValues(alpha: 0.3)),
                    ),
                    child: Icon(Icons.forward_rounded,
                        size: 16, color: colors.info),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                flex: 2,
                child: _ScaleOnTap(
                  onTap: onApprove,
                  child: Container(
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary]),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_rounded,
                            size: 15, color: Colors.white),
                        SizedBox(width: 4),
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

class _RejectResult {
  const _RejectResult(this.reason, this.note);
  final String reason;
  final String? note;
}

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({required this.toolName});
  final String toolName;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  static const _reasons = [
    'Over department budget',
    'Duplicate or overlapping tool',
    'Not aligned with strategy',
    'Vendor / security concern',
    'Other',
  ];

  String? _selectedReason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Text('Reject request',
                  style: AppTypography.h3(colors.textPrimary)),
              const SizedBox(height: 2),
              Text(widget.toolName,
                  style: AppTypography.caption(colors.textSecondary)),
              const SizedBox(height: AppSpacing.lg),
              Text('Reason',
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _reasons.map((reason) {
                  final selected = _selectedReason == reason;
                  return ChoiceChip(
                    label: Text(reason),
                    selected: selected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedReason = reason),
                    labelStyle: AppTypography.caption(
                        selected ? Colors.white : colors.textPrimary),
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceElevated,
                    side: BorderSide(color: colors.border),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Add more detail (optional)',
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _noteController,
                maxLines: 3,
                style: AppTypography.body(colors.textPrimary),
                decoration: InputDecoration(
                  hintText:
                      'e.g. Switch to the shared Claude Team plan instead',
                  hintStyle: AppTypography.caption(colors.textSecondary),
                  filled: true,
                  fillColor: colors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedReason == null
                          ? null
                          : () => Navigator.of(context).pop(
                                _RejectResult(
                                  _selectedReason!,
                                  _noteController.text.trim().isEmpty
                                      ? null
                                      : _noteController.text.trim(),
                                ),
                              ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.danger,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TODAY'S FOCUS — exactly 3 items: Highest Risk Department, Largest
// Opportunity, Biggest Saving.
// ---------------------------------------------------------------------------
class _TodaysFocusSection extends StatelessWidget {
  const _TodaysFocusSection({required this.focus});
  final TodaysFocusData focus;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final rows = [
      (
        Icons.warning_amber_rounded,
        colors.danger,
        'Highest risk department',
        focus.highestRiskDepartment
      ),
      (
        Icons.lightbulb_rounded,
        colors.warning,
        'Largest opportunity',
        focus.largestOpportunity
      ),
      (
        Icons.savings_rounded,
        colors.success,
        'Biggest savings',
        focus.biggestSavings
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: "Today's focus"),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: rows[i].$2.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(rows[i].$1, color: rows[i].$2, size: 17),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rows[i].$3,
                                style: AppTypography.caption(
                                    colors.textSecondary)),
                            Text(rows[i].$4,
                                style: AppTypography.body(colors.textPrimary)
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != rows.length - 1)
                  Divider(height: 1, color: colors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExecutiveSummaryRoute extends StatelessWidget {
  const _ExecutiveSummaryRoute({required this.summary});
  final String summary;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Executive Summary')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company at a glance',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(summary, style: AppTypography.body(colors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Placeholder destination for the unused-licenses alert / KPI card until a
/// real license-management screen exists in the app's route table.
class _UnusedLicensesPlaceholderRoute extends StatelessWidget {
  const _UnusedLicensesPlaceholderRoute();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Unused Licenses')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.person_off_outlined, size: 40, color: colors.warning),
            const SizedBox(height: AppSpacing.md),
            Text('Unused license detail is coming soon',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'This will list every seat inactive for 30+ days, grouped by department and tool, so you can reassign or reclaim them.',
              style: AppTypography.body(colors.textSecondary),
            ),
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