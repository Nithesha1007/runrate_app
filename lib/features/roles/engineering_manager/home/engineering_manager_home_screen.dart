import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'engineering_manager_home_cubit.dart';

/// Engineering Manager · Home
/// Dashboard with header, Sprint Progress, Team Snapshot, Bug Summary,
/// and Pending PR Reviews. Bottom nav is provided by the parent shell.
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

class _EngineeringManagerHomeView extends StatelessWidget {
  const _EngineeringManagerHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerHomeCubit, EngineeringManagerHomeState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerHomeInitial() ||
              EngineeringManagerHomeLoading() =>
                const Center(child: CircularProgressIndicator()),
              EngineeringManagerHomeError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<EngineeringManagerHomeCubit>().loadDashboard(),
                ),
              EngineeringManagerHomeLoaded(:final data) => RefreshIndicator(
                  onRefresh: () => context.read<EngineeringManagerHomeCubit>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.md,
                      AppSpacing.xl,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HomeHeader(
                          managerName: data.managerName,
                          hasUnread: data.hasUnreadNotifications,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SprintProgressCard(data: data),
                        const SizedBox(height: AppSpacing.lg),
                        _TeamSnapshotCard(
                          team: data.team,
                          overflowCount: data.overflowTeamCount,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _BugSummaryRow(
                          criticalCount: data.criticalBugCount,
                          openCount: data.openBugCount,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _PendingPrReviewsCard(reviews: data.pendingPrReviews),
                      ],
                    ),
                  ),
                ),
            };
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.managerName, required this.hasUnread});

  final String managerName;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning', style: theme.textTheme.bodySmall),
            Text(
              managerName,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
            if (hasUnread)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SprintProgressCard extends StatelessWidget {
  const _SprintProgressCard({required this.data});

  final EngineeringManagerHomeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = data.sprintProgress.clamp(0.0, 1.0);
    final progressPercent = (progress * 100).round();

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.sprintName} progress',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text('${data.sprintDaysLeft} days left', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.primaryContainer,
              valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${data.pointsCompleted} of ${data.pointsTotal} points',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '$progressPercent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamSnapshotCard extends StatelessWidget {
  const _TeamSnapshotCard({required this.team, required this.overflowCount});

  final List<TeamMemberSnapshot> team;
  final int overflowCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team snapshot', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              for (final member in team) ...[
                _TeamAvatar(member: member),
                const SizedBox(width: AppSpacing.md),
              ],
              if (overflowCount > 0)
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+$overflowCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text('More', style: theme.textTheme.labelSmall),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.member});

  final TeamMemberSnapshot member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: member.avatarColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                member.initials,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: member.avatarTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              bottom: -1,
              right: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: member.workload.dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.surface, width: 2),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(member.name, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _BugSummaryRow extends StatelessWidget {
  const _BugSummaryRow({required this.criticalCount, required this.openCount});

  final int criticalCount;
  final int openCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BugSummaryTile(
            label: 'Critical bugs',
            count: criticalCount,
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            textColor: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _BugSummaryTile(
            label: 'Open bugs',
            count: openCount,
            backgroundColor: const Color(0xFFFAEEDA),
            textColor: const Color(0xFF633806),
          ),
        ),
      ],
    );
  }
}

class _BugSummaryTile extends StatelessWidget {
  const _BugSummaryTile({
    required this.label,
    required this.count,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final int count;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: textColor)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$count',
            style: theme.textTheme.headlineSmall?.copyWith(color: textColor, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _PendingPrReviewsCard extends StatelessWidget {
  const _PendingPrReviewsCard({required this.reviews});

  final List<PendingPrReview> reviews;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending PR reviews', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < reviews.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: i == reviews.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.merge_type, size: 18, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reviews[i].title, style: theme.textTheme.bodyMedium),
                        Text(
                          '${reviews[i].author} · ${reviews[i].repo} · ${reviews[i].timeAgo}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
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

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: child,
    );
  }
}

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
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load your dashboard', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}