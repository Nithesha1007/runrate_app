import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_teams_cubit.dart';

/// CFO · Teams
/// Simple scannable list: name + spend + trend, wired to [CfoTeamsCubit].
class CfoTeamsScreen extends StatelessWidget {
  const CfoTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoTeamsCubit(),
      child: const _CfoTeamsView(),
    );
  }
}

class _CfoTeamsView extends StatelessWidget {
  const _CfoTeamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teams')),
      body: SafeArea(
        child: BlocBuilder<CfoTeamsCubit, CfoTeamsState>(
          builder: (context, state) {
            if (state is CfoTeamsLoading || state is CfoTeamsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoTeamsError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoTeamsCubit>().load(),
              );
            }

            final teams = (state as CfoTeamsLoaded).teams;
            final totalSpend = teams.fold<double>(0, (sum, t) => sum + t.spend);

            return RefreshIndicator(
              onRefresh: () => context.read<CfoTeamsCubit>().refresh(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: teams.length + 1,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        'Total spend across teams: ${formatInr(totalSpend)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return _TeamRow(team: teams[index - 1]);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.team});

  final TeamSpend team;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUp = team.trendPercent >= 0;
    final trendColor = isUp ? Colors.green.shade600 : theme.colorScheme.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              team.name.substring(0, 1),
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(team.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text('${team.memberCount} members', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatInr(team.spend), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: trendColor),
                  const SizedBox(width: 2),
                  Text(
                    '${team.trendPercent.abs().toStringAsFixed(1)}%',
                    style: theme.textTheme.bodySmall?.copyWith(color: trendColor),
                  ),
                ],
              ),
            ],
          ),
        ],
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
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — Indian currency (Cr / L)
/// ---------------------------------------------------------------------

String formatInr(double value) {
  if (value >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  }
  if (value >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  }
  return '₹${value.toStringAsFixed(0)}';
}