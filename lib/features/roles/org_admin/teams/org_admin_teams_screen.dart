import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import 'org_admin_teams_cubit.dart';

/// Org Admin · Teams
/// Simple scannable list: name + spend + trend. Wired to
/// [OrgAdminTeamsCubit].
class OrgAdminTeamsScreen extends StatelessWidget {
  const OrgAdminTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgAdminTeamsCubit()..loadTeams(),
      child: const _OrgAdminTeamsView(),
    );
  }
}

class _OrgAdminTeamsView extends StatelessWidget {
  const _OrgAdminTeamsView();

  String _formatSpend(double spend) {
    return '₹${spend.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        )}';
  }

  IconData _trendIcon(SpendTrend trend) {
    switch (trend) {
      case SpendTrend.up:
        return Icons.trending_up;
      case SpendTrend.down:
        return Icons.trending_down;
      case SpendTrend.flat:
        return Icons.trending_flat;
    }
  }

  Color _trendColor(SpendTrend trend) {
    switch (trend) {
      case SpendTrend.up:
        return Colors.green;
      case SpendTrend.down:
        return Colors.red;
      case SpendTrend.flat:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Admin · Teams')),
      body: SafeArea(
        child: BlocBuilder<OrgAdminTeamsCubit, OrgAdminTeamsState>(
          builder: (context, state) {
            if (state.status == OrgAdminTeamsStatus.initial ||
                state.status == OrgAdminTeamsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == OrgAdminTeamsStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Something went wrong.'));
            }
            if (state.teams.isEmpty) {
              return const EmptyState(
                title: 'No teams yet',
                message: 'Teams you create will show up here with spend and trend.',
                icon: Icons.groups_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<OrgAdminTeamsCubit>().loadTeams(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        for (final team in state.teams) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    team.name,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                                Text(
                                  _formatSpend(team.spend),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Icon(
                                  _trendIcon(team.trend),
                                  size: 18,
                                  color: _trendColor(team.trend),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${team.trendPercent.toStringAsFixed(1)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: _trendColor(team.trend),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (team != state.teams.last) const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}