import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'engineering_manager_teams_cubit.dart';

/// Engineering Manager · Teams
/// Simple scannable list: name + spend + trend.
class EngineeringManagerTeamsScreen extends StatelessWidget {
  const EngineeringManagerTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerTeamsCubit()..loadTeams(),
      child: const _EngineeringManagerTeamsView(),
    );
  }
}

class _EngineeringManagerTeamsView extends StatelessWidget {
  const _EngineeringManagerTeamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerTeamsCubit, EngineeringManagerTeamsState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerTeamsInitial() ||
              EngineeringManagerTeamsLoading() =>
                const Center(child: CircularProgressIndicator()),
              EngineeringManagerTeamsError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<EngineeringManagerTeamsCubit>().loadTeams(),
                ),
              EngineeringManagerTeamsLoaded(:final data) => data.teams.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      onRefresh: () => context.read<EngineeringManagerTeamsCubit>().refresh(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        itemCount: data.teams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => _TeamRow(team: data.teams[index]),
                      ),
                    ),
            };
          },
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team});

  final TeamSummary team;

  static const _currencyFormatLocale = 'en_IN';

  String get _formattedSpend {
    return '\u20B9${team.monthlySpend.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = team.trendIsUp ? const Color(0xFF3B6D11) : const Color(0xFFA32D2D);
    final trendBg = team.trendIsUp ? const Color(0xFFEAF3DE) : const Color(0xFFFCEBEB);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              team.name.isEmpty ? '?' : team.name[0].toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${team.memberCount} members',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formattedSpend,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: trendBg, borderRadius: BorderRadius.circular(999)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      team.trendIsUp ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: trendColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${team.trendPercent.toStringAsFixed(1)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text('No teams yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Teams you manage will show up here.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load teams', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}