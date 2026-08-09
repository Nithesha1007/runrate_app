import 'package:flutter/material.dart';
import 'package:runrate/features/roles/ceo/shared/models/home_models.dart';
import '../data/ceo_mock_repository.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/search_bar.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/reveal.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../core/utils/formatters.dart';

/// CEO · Teams → Department drill-down. Shows the roster for one
/// department, reached by tapping a department card on CeoTeamsScreen.
class CeoTeamMembersScreen extends StatefulWidget {
  final DepartmentSummary department;
  const CeoTeamMembersScreen({super.key, required this.department});

  @override
  State<CeoTeamMembersScreen> createState() => _CeoTeamMembersScreenState();
}

class _CeoTeamMembersScreenState extends State<CeoTeamMembersScreen> {
  final _repo = CeoMockRepository();
  late Future<List<TeamMember>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.fetchDepartmentMembers(widget.department.team.name);
  }

  @override
  Widget build(BuildContext context) {
    final dept = widget.department.team;
    return Scaffold(
      appBar: AppBar(title: Text(dept.name)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${dept.memberCount} members · Led by ${widget.department.leadName}',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 2),
                        Text('Spend: ${Formatters.currency(dept.spend)}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSearchBar(
              hint: 'Search by name or role',
              onChanged: (q) => setState(() => _query = q.toLowerCase()),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: FutureBuilder<List<TeamMember>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return ListView.separated(
                      itemCount: 4,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, __) => const SkeletonLoader(height: 64),
                    );
                  }
                  final members = snapshot.data!
                      .where((m) =>
                          _query.isEmpty ||
                          m.name.toLowerCase().contains(_query) ||
                          m.role.toLowerCase().contains(_query))
                      .toList();
                  if (members.isEmpty) {
                    return const EmptyState(
                      title: 'No members found',
                      message: 'Try a different search term.',
                      icon: Icons.search_off,
                    );
                  }
                  return ListView.separated(
                    itemCount: members.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final m = members[i];
                      return Reveal(
                        delayMs: i * 30,
                        child: AppCard(
                          child: Row(
                            children: [
                              Avatar(name: m.name),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    Text(m.role,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
