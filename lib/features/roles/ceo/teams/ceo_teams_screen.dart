import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_teams_cubit.dart';
import 'ceo_teams_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/team_model.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../../../shared/widgets/team_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/reveal.dart';
import '../../../../core/utils/formatters.dart';

/// CEO · Teams — simple scannable department list: name, spend, trend.
/// Tapping a row opens a detail sheet with a bit more context.
///
/// Fixes vs. original:
///  - The detail-sheet Text widgets used `\${...}` (an escaped dollar sign
///    followed by literal braces), which in Dart does NOT interpolate — it
///    printed the literal text "${Formatters.currency(dept.spend)}" on
///    screen instead of the actual number. Changed to proper `${...}`
///    interpolation below.
///  - Added maxLines/ellipsis on the department name so a long name can't
///    overflow the bottom sheet.
///  - Added a staggered fade/slide-in on each row via the shared `Reveal`
///    widget, matching Home's polish.
class CeoTeamsScreen extends StatelessWidget {
  const CeoTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoTeamsCubit(CeoMockRepository()),
      child: const _CeoTeamsView(),
    );
  }
}

class _CeoTeamsView extends StatelessWidget {
  const _CeoTeamsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Departments')),
      body: BlocBuilder<CeoTeamsCubit, CeoTeamsState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchBar(
                  hint: 'Search departments',
                  onChanged: (q) => context.read<CeoTeamsCubit>().search(q),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: _buildList(context, state)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, CeoTeamsState state) {
    if (state.loading) {
      return ListView.separated(
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const SkeletonLoader(height: 56),
      );
    }
    if (state.filtered.isEmpty) {
      return const EmptyState(
        title: 'No departments found',
        message: 'Try a different search term.',
        icon: Icons.search_off,
      );
    }
    return ListView.separated(
      itemCount: state.filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final dept = state.filtered[i];
        return Reveal(
          delayMs: i * 40,
          child: TeamCard(team: dept, onTap: () => _showDetail(context, dept)),
        );
      },
    );
  }

  void _showDetail(BuildContext context, TeamModel dept) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dept.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Total spend: ${Formatters.currency(dept.spend)}'),
            Text('Members: ${dept.memberCount}'),
            Text(
                'Trend: ${dept.trendPercent >= 0 ? '+' : ''}${dept.trendPercent.toStringAsFixed(0)}% vs last month'),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}