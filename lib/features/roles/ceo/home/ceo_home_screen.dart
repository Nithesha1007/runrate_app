import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_home_cubit.dart';
import 'ceo_home_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/glow_background.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/simple_bar_chart.dart';
import '../../../../shared/widgets/insight_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';

// TODO: verify these four import paths against your actual folder structure —
// I inferred them from the sibling-feature-folder pattern your other CEO
// screens use (lib/features/ceo/<feature>/<file>.dart). Adjust if different.
import '../ai/ceo_ai_screen.dart';
import '../teams/ceo_teams_screen.dart';
import '../approvals/ceo_approvals_screen.dart';
import '../more/ceo_reports_screen.dart';

/// CEO · Home — company-wide spend KPIs, department comparison chart,
/// and AI-generated insights. Pull-to-refresh reloads all mock data.
///
/// This restores the real Cubit/repository/shared-widget architecture
/// (matching your other CEO screens) instead of the self-contained rewrite.
/// Only these two things are NEW vs. your original file:
///   1. Quick Actions + a couple of section headers now genuinely navigate
///      via Navigator.push to CeoReportsScreen / CeoAiScreen /
///      CeoTeamsScreen / CeoApprovalsScreen.
///   2. A light "Budget Overview" card + staggered fade/slide-in animation
///      on each section, built with AppCard + AppColors.primary/primaryLight
///      only (no invented colors), so it matches the rest of your app.
///
/// NOTE: Budget Health / Alerts / Approvals-preview data below is placeholder
/// mock data local to this file because I don't have your CeoHomeState
/// source to know what it currently exposes. Send me that file (plus
/// CeoHomeCubit + CeoMockRepository + AppColors) and I'll wire these
/// properly into the cubit instead of hardcoding them here.
class CeoHomeScreen extends StatelessWidget {
  const CeoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoHomeCubit(CeoMockRepository()),
      child: const _CeoHomeView(),
    );
  }
}

class _CeoHomeView extends StatelessWidget {
  const _CeoHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Good morning, Jordan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
          ),
        ],
      ),
      body: GlowBackground(
        child: BlocBuilder<CeoHomeCubit, CeoHomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () => context.read<CeoHomeCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: _buildBody(context, state),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CeoHomeState state) {
    if (state is CeoHomeError) {
      return _ErrorRetry(
          message: state.message,
          onRetry: () => context.read<CeoHomeCubit>().load());
    }
    if (state is CeoHomeLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: const [
            Expanded(child: SkeletonLoader(height: 96)),
            SizedBox(width: AppSpacing.md),
            Expanded(child: SkeletonLoader(height: 96)),
          ]),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonLoader(height: 200),
          const SizedBox(height: AppSpacing.lg),
          const SkeletonLoader(height: 90),
        ],
      );
    }
    final loaded = state as CeoHomeLoaded;
    final kpiEntries = loaded.kpis.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- Budget overview (light card, not a heavy gradient) ---------
        _Reveal(child: _budgetOverview(context, loaded)),
        const SizedBox(height: AppSpacing.xxl),

        // ---- KPI grid (your existing KpiCard, unchanged) -----------------
        _Reveal(
          delayMs: 60,
          child: LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.5,
              children: kpiEntries.map((e) {
                final isCurrency = e.key != 'Active Vendors';
                return KpiCard(
                  label: e.key,
                  value: e.value,
                  prefix: isCurrency ? '\$' : '',
                  icon: Icons.attach_money,
                );
              }).toList(),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ---- Department spend chart (your existing widget) --------------
        _Reveal(
          delayMs: 100,
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Spend by Department',
                          style: Theme.of(context).textTheme.headlineSmall),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CeoTeamsScreen()),
                      ),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SimpleBarChart(points: loaded.deptChart),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ---- Quick Actions — now genuinely navigate ----------------------
        _Reveal(
          delayMs: 140,
          child: Text('Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        _Reveal(
          delayMs: 160,
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.chat,
                  label: 'Ask AI',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CeoAiScreen()),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  icon: Icons.groups,
                  label: 'Compare\nDepartments',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CeoTeamsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _Reveal(
          delayMs: 180,
          child: Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.description,
                  label: 'Board Report',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CeoReportsScreen()),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _QuickAction(
                  icon: Icons.fact_check,
                  label: 'Review\nApprovals',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CeoApprovalsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // ---- Insights (your existing widget/state, unchanged) -----------
        _Reveal(
          delayMs: 220,
          child: Text('Insights',
              style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.md),
        ...loaded.insights.asMap().entries.map((entry) => _Reveal(
              delayMs: 240 + entry.key * 20,
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: InsightCard(insight: entry.value),
              ),
            )),
      ],
    );
  }

  /// Light, on-brand overview card — uses only AppColors.primary /
  /// AppColors.primaryLight, same as the rest of your app, instead of a
  /// custom gradient.
  Widget _budgetOverview(BuildContext context, CeoHomeLoaded loaded) {
    final theme = Theme.of(context);
    return AppCard(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.appColors.primaryLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Company AI Spend',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text('On track — 74% of monthly budget used',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: AppSpacing.sm),
          Text(label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
          const SizedBox(height: AppSpacing.md),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Lightweight fade + slide-up entrance for a section. No external packages.
class _Reveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  const _Reveal({required this.child, this.delayMs = 0});

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.05),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
