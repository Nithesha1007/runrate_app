import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import 'org_admin_home_cubit.dart';

/// Org Admin · Home
/// Dashboard with system health, user management summary, role management,
/// and recent activity. Wired to [OrgAdminHomeCubit].
class OrgAdminHomeScreen extends StatelessWidget {
  const OrgAdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgAdminHomeCubit()..fetchDashboard(),
      child: const _OrgAdminHomeView(),
    );
  }
}

class _OrgAdminHomeView extends StatelessWidget {
  const _OrgAdminHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Admin · Home')),
      body: SafeArea(
        child: BlocBuilder<OrgAdminHomeCubit, OrgAdminHomeState>(
          builder: (context, state) {
            switch (state.status) {
              case OrgAdminHomeStatus.initial:
              case OrgAdminHomeStatus.loading:
                return const Center(child: CircularProgressIndicator());
              case OrgAdminHomeStatus.error:
                return _ErrorState(
                  message: state.errorMessage ?? 'Something went wrong.',
                  onRetry: () => context.read<OrgAdminHomeCubit>().fetchDashboard(),
                );
              case OrgAdminHomeStatus.loaded:
                final data = state.data!;
                return RefreshIndicator(
                  onRefresh: () => context.read<OrgAdminHomeCubit>().fetchDashboard(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Header(adminName: data.adminName, orgName: data.orgName),
                        const SizedBox(height: AppSpacing.xl),
                        _SystemHealthCard(health: data.systemHealth),
                        const SizedBox(height: AppSpacing.xl),
                        _UserManagementSection(summary: data.userSummary),
                        const SizedBox(height: AppSpacing.xl),
                        _RoleManagementCard(roles: data.roles),
                        const SizedBox(height: AppSpacing.xl),
                        _ActivityLogCard(entries: data.activity),
                      ],
                    ),
                  ),
                );
            }
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.adminName, required this.orgName});

  final String adminName;
  final String orgName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            adminName.isNotEmpty ? adminName[0].toUpperCase() : '?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good morning, $adminName', style: theme.textTheme.titleMedium),
              Text('$orgName · Org Admin', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined),
          tooltip: 'Notifications',
        ),
      ],
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  const _SystemHealthCard({required this.health});

  final SystemHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('System health', style: theme.textTheme.titleSmall),
              const Spacer(),
              Icon(
                Icons.circle,
                size: 8,
                color: health.isOperational ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                health.isOperational ? 'Operational' : 'Degraded',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: health.isOperational ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Uptime',
                  value: '${health.uptimePercent.toStringAsFixed(2)}%',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricTile(
                  label: 'Active sessions',
                  value: health.activeSessions.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserManagementSection extends StatelessWidget {
  const _UserManagementSection({required this.summary});

  final UserManagementSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('User management', style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: AppCard(
                child: _MetricTile(
                  label: 'Total users',
                  value: summary.totalUsers.toString(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _MetricTile(
                  label: 'New signups',
                  value: '+${summary.newSignups}',
                  valueColor: Colors.green,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppCard(
                child: _MetricTile(
                  label: 'Pending approvals',
                  value: summary.pendingApprovals.toString(),
                  valueColor: Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(color: valueColor),
        ),
      ],
    );
  }
}

class _RoleManagementCard extends StatelessWidget {
  const _RoleManagementCard({required this.roles});

  final List<RoleSummary> roles;

  IconData _iconFor(AdminRoleType type) {
    switch (type) {
      case AdminRoleType.admin:
        return Icons.verified_user_outlined;
      case AdminRoleType.manager:
        return Icons.groups_outlined;
      case AdminRoleType.staff:
        return Icons.person_outline;
      case AdminRoleType.viewer:
        return Icons.visibility_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role management', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final role in roles)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(_iconFor(role.type), size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(role.label, style: theme.textTheme.bodyMedium)),
                  Text('${role.memberCount} members', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActivityLogCard extends StatelessWidget {
  const _ActivityLogCard({required this.entries});

  final List<ActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (entries.isEmpty) {
      return const AppCard(
        child: EmptyState(
          title: 'No recent activity',
          message: 'Activity from your organization will show up here.',
          icon: Icons.history_outlined,
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent activity', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(child: Text(entry.message, style: theme.textTheme.bodyMedium)),
                  const SizedBox(width: 8),
                  Text(
                    entry.timeAgo,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

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
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}