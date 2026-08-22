// ceo_home_screen.dart
import 'dart:io';

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
import '../more/profile_cubit.dart';

/// CEO Home dashboard — company-wide rollup across every department.
/// Section order: Header, Critical Alert banner, Company AI Overview hero,
/// Quick Actions, Key Executive Metrics (2-card KPI row: Active AI Users,
/// Unused Licenses — Total AI Spend and AI Adoption % removed, both are
/// already shown in the hero card and department cards), AI Usage &
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
            final profile = context.watch<ProfileCubit>().state;
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
                            ceoName: profile.name.isEmpty
                                ? data.ceoName
                                : profile.name,
                            companyName: profile.organization.isEmpty
                                ? data.companyName
                                : profile.organization,
                            avatarPath: profile.avatarPath,
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
                      const    _Staggered(
                            index: 2,
                            child:  _SectionHeader(
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
                              onViewAll: () => _openAiUsageDetail(context),
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
                          // const SizedBox(height: AppSpacing.xl),
                          // _Staggered(
                          //   index: 6,
                          //   child: _StrategicInsightsSection(
                          //       insights: data.insights),
                          // ),
                          // const SizedBox(height: AppSpacing.xl),
                          // _Staggered(
                          //   index: 7,
                          //   child: _EscalatedApprovalsSection(
                          //     requests: data.escalatedApprovals,
                          //     onApprove: (id) => context
                          //         .read<CeoHomeCubit>()
                          //         .approveEscalation(id),
                          //     onReject: (id, reason, note) => context
                          //         .read<CeoHomeCubit>()
                          //         .rejectEscalation(id,
                          //             reason: reason, note: note),
                          //     onDelegate: (id, delegateTo) => context
                          //         .read<CeoHomeCubit>()
                          //         .delegateEscalation(id,
                          //             delegateTo: delegateTo),
                          //   ),
                          // ),
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
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
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
    required this.avatarPath,
    required this.todayLabel,
    required this.greeting,
    required this.hasUnread,
    required this.isOnline,
  });

  final String ceoName;
  final String companyName;
  final String? avatarPath;
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
                        child: _HeaderAvatarImage(
                          path: avatarPath,
                          initials: ceoName
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
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
//
// v3 — "Ask AI" tile removed from this grid entirely (it's a permanent
// bottom-nav tab now, so surfacing it again here was a duplicate entry
// point). With only 3 tiles left (Company Report, Budget Forecast, Compare
// Departments), the plain 2x2 GridView layout is replaced with an
// asymmetric "advanced" layout: the first/primary action renders as a wide
// featured card with a soft gradient wash, a glowing icon badge, a one-line
// description, and a trailing arrow chip; the remaining two render as a
// tighter two-up row below it with the same gradient-badge treatment at a
// smaller scale. This reads as a deliberately designed action shelf rather
// than a generic icon grid, while still using the existing color/spacing/
// typography tokens so it drops into dark mode correctly.
// ---------------------------------------------------------------------------
class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.items, required this.onTap});

  final List<CeoQuickActionItem> items;
  final ValueChanged<CeoQuickActionItem> onTap;

  static const _accents = [
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
    [Color(0xFFF2994A), Color(0xFFF2C94C)],
  ];

  static const _descriptions = {
    'company_report': 'Full AI spend rollup, ready to share',
    'budget_forecast': 'Project next quarter\'s AI spend',
    'compare_departments': 'See who\'s over or under budget',
  };

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);
    // Ask AI already lives permanently in the bottom nav — don't duplicate
    // it here.
    final visible =
        items.where((i) => i.routeTag != 'ask_ai').take(3).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    final primary = visible.first;
    final rest = visible.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FeaturedActionCard(
          item: primary,
          accent: _accents[0],
          description: _descriptions[primary.routeTag] ?? '',
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
/// background, glowing icon badge, description line, trailing arrow chip.
class _FeaturedActionCard extends StatelessWidget {
  const _FeaturedActionCard({
    required this.item,
    required this.accent,
    required this.description,
    required this.onTap,
  });

  final CeoQuickActionItem item;
  final List<Color> accent;
  final String description;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(description,
                        style: AppTypography.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
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

  final CeoQuickActionItem item;
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
// KEY EXECUTIVE METRICS
//
// v2 — "Total AI Spend" and "AI Adoption %" removed from this section
// (they're already surfaced in the hero card's Spend chip and in each
// department's adoption ring, so repeating them here was redundant). Only
// "Active AI Users" and "Unused Licenses" remain. With just two cards this
// now renders as a single premium-looking row instead of a 2x2 grid, so
// each card gets more room: bigger number, trend pill, icon badge with a
// soft shadow.
// ---------------------------------------------------------------------------
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});

  final List<CeoKpiCardData> kpis;

  static const _accents = [
    [Color(0xFF2F80ED), Color(0xFF56CCF2)],
    [Color(0xFFE85D75), Color(0xFFF2994A)],
    [Color(0xFF6C5CE7), Color(0xFF8E7CFF)],
    [Color(0xFF11998E), Color(0xFF38EF7D)],
  ];

  bool _isExcluded(String label) {
    final l = label.toLowerCase();
    return l.contains('total ai spend') || l.contains('ai adoption');
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final visible = kpis.where((k) => !_isExcluded(k.label)).take(2).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(visible.length, (i) {
        final kpi = visible[i];
        final accent = _accents[i % _accents.length];
        final isPositive = kpi.trendValue >= 0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
                right: i == visible.length - 1 ? 0 : AppSpacing.md),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 400 + i * 80),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                    offset: Offset(0, (1 - value) * 12), child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                  boxShadow: [
                    BoxShadow(
                      color: accent[0].withValues(alpha: 0.10),
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: LinearGradient(colors: accent),
                          ),
                          child: Icon(kpi.icon, color: Colors.white, size: 18),
                        ),
                        const Spacer(),
                        if (kpi.trendValue != 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color:
                                  (isPositive ? colors.success : colors.danger)
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              kpi.trend,
                              style: AppTypography.caption(isPositive
                                      ? colors.success
                                      : colors.danger)
                                  .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(kpi.value,
                        style: AppTypography.h3(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
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
// v3 — removed the numbered rank badge (the small "1", "2" circle) since it
// added visual noise without adding information — the cards are already
// listed in spend order. The generic Material icon per tool is replaced
// with the tool's real brand mark (ChatGPT/OpenAI, Claude/Anthropic,
// GitHub Copilot, Gemini) pulled in as a small logo image with a graceful
// icon fallback if the image fails to load, so the card reads like a real
// vendor catalog entry rather than a placeholder icon. Layout is otherwise
// the same condensed card used elsewhere: name + vendor/category up top,
// spend + level pill on the right, a stat row (Users / Adoption /
// Cost per user), and a gradient progress bar along the bottom.
//
// v4 — logo source switched from logo.clearbit.com (which returns blank or
// wrong-shaped results for several AI-native brands, since Clearbit only
// indexes a company's marketing-site favicon/wordmark, not a curated
// square app icon) to Wikimedia Commons' official brand SVGs, served
// through Special:FilePath so Image.network gets back a rendered raster
// (Commons redirects that URL to a PNG thumbnail — Flutter's Image.network
// can't decode raw SVG without an extra package, so this avoids adding
// flutter_svg as a dependency). Each source below is the real, current
// icon-only brand mark for that product, not a wordmark or third-party
// redraw:
//   • ChatGPT → File:ChatGPT logo.svg (OpenAI's black speech-bubble mark)
//   • Claude  → File:Claude AI symbol.svg (Anthropic's icon-only mark, CC0)
//   • Gemini  → File:Google Gemini icon 2025.svg (current sparkle mark)
//   • Copilot → GitHub Copilot has no square standalone icon on Commons
//     (only thin wordmark strips), so this falls back to GitHub's own
//     Invertocat mark, since Copilot ships as part of the GitHub brand.
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
            child: _AiUsageToolCard(tool: visible[i]),
          ),
      ],
    );
  }
}

/// Brand info for a known AI tool: a real logo image, vendor, and category
/// — plus a fallback icon in case the image fails to load (offline, blocked
/// network, etc).
class _AiToolBrand {
  const _AiToolBrand({
    required this.logoUrl,
    required this.vendor,
    required this.category,
    required this.fallbackIcon,
  });

  final String logoUrl;
  final String vendor;
  final String category;
  final IconData fallbackIcon;
}

_AiToolBrand _brandForAiTool(String name) {
  final n = name.toLowerCase();
  if (n.contains('chatgpt') || n.contains('gpt')) {
    return const _AiToolBrand(
      logoUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/ChatGPT%20logo.svg?width=200',
      vendor: 'OpenAI',
      category: 'Generative AI',
      fallbackIcon: Icons.chat_bubble_rounded,
    );
  }
  if (n.contains('copilot')) {
    return const _AiToolBrand(
      logoUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/GitHub%20Invertocat%20Logo.svg?width=200',
      vendor: 'Microsoft',
      category: 'Dev Tools',
      fallbackIcon: Icons.code_rounded,
    );
  }
  if (n.contains('claude')) {
    return const _AiToolBrand(
      logoUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Claude%20AI%20symbol.svg?width=200',
      vendor: 'Anthropic',
      category: 'Generative AI',
      fallbackIcon: Icons.auto_awesome_rounded,
    );
  }
  if (n.contains('gemini')) {
    return const _AiToolBrand(
      logoUrl:
          'https://commons.wikimedia.org/wiki/Special:FilePath/Google%20Gemini%20icon%202025.svg?width=200',
      vendor: 'Google',
      category: 'Generative AI',
      fallbackIcon: Icons.diamond_outlined,
    );
  }
  return const _AiToolBrand(
    logoUrl: '',
    vendor: 'Third-party',
    category: 'AI Tool',
    fallbackIcon: Icons.smart_toy_rounded,
  );
}

class _AiUsageToolCard extends StatelessWidget {
  const _AiUsageToolCard({required this.tool});
  final AiToolUsage tool;

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

  double get _costPerUser =>
      tool.userCount == 0 ? 0 : tool.spend / tool.userCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final levelColor = _levelColor(colors);
    final brand = _brandForAiTool(tool.toolName);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
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
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: colors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: brand.logoUrl.isEmpty
                      ? Icon(brand.fallbackIcon, color: levelColor, size: 20)
                      : Image.network(
                          brand.logoUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) => Icon(
                              brand.fallbackIcon,
                              color: levelColor,
                              size: 20),
                        ),
                ),
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
                      '${brand.vendor} · ${brand.category}',
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
                    margin: const EdgeInsets.only(top: 3),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(_levelLabel(),
                        style: AppTypography.caption(levelColor).copyWith(
                            fontWeight: FontWeight.w700, fontSize: 10)),
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
  const _MiniStat(
      {required this.label, required this.value, required this.colors});
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
        Text(label,
            style: AppTypography.caption(colors.textSecondary)
                .copyWith(fontSize: 10)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DEPARTMENT PERFORMANCE — image, name, headcount, spend, adoption/health
// ring, animated spend-vs-budget progress bar, status badge, View Details.
// Top-tool line removed — tool usage now lives only in the AI Usage &
// Adoption section.
//
// v2 — redesigned card: bigger rounded-square department image, the status
// badge moved up next to the trend arrow (right by the name, where it's
// read first) instead of sitting alone at the bottom, and the spend figures
// + progress bar now share one soft inset row so the numbers and the bar
// read as a single unit rather than two disconnected lines. A tinted
// drop-shadow (colored by the department's status) replaces the flat
// border-only look for a bit more depth.
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _DeptAvatar(name: dept.name, size: 48),
                ),
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
                                    .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Icon(_trendIcon,
                              size: 15, color: _trendColor(colors)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(_statusLabelFor(status),
                                style: AppTypography.caption(statusColor)
                                    .copyWith(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text('${dept.headName} · ${dept.headcount} people',
                          style: AppTypography.caption(colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 40,
                  height: 40,
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
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('\$${_compact(dept.spend)} ',
                          style: AppTypography.caption(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text('of \$${_compact(dept.budget)} budget',
                          style: AppTypography.caption(colors.textSecondary)),
                      const Spacer(),
                      Text(
                        '${(dept.utilization * 100).toInt()}%',
                        style: AppTypography.caption(statusColor)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
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
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: _ScaleOnTap(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
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
              ),
            ),
          ],
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

class _HeaderAvatarImage extends StatelessWidget {
  const _HeaderAvatarImage({required this.path, required this.initials});

  final String? path;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final fallback =
        Text(initials, style: AppTypography.h3(AppColors.of(context).primary));
    if (path == null || path!.isEmpty) return fallback;
    return ClipOval(
      child: Image.file(
        File(path!),
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}