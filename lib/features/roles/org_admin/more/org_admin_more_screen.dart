import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_spacing.dart';
import 'org_admin_more_cubit.dart';

/// Org Admin · More
/// Reports, Blog & Insights, Profile, Preferences, Security, Log Out.
/// Wired to [OrgAdminMoreCubit].
class OrgAdminMoreScreen extends StatelessWidget {
  const OrgAdminMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgAdminMoreCubit()..loadProfile(),
      child: const _OrgAdminMoreView(),
    );
  }
}

class _OrgAdminMoreView extends StatelessWidget {
  const _OrgAdminMoreView();

  Future<void> _confirmLogOut(BuildContext context) async {
    final cubit = context.read<OrgAdminMoreCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of Org Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      cubit.logOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Admin · More')),
      body: SafeArea(
        child: BlocBuilder<OrgAdminMoreCubit, OrgAdminMoreState>(
          builder: (context, state) {
            if (state.status == OrgAdminMoreStatus.initial ||
                state.status == OrgAdminMoreStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == OrgAdminMoreStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Something went wrong.'));
            }
            final profile = state.profile!;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        child: Text(
                          profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: Theme.of(context).textTheme.titleMedium),
                            Text(profile.email, style: Theme.of(context).textTheme.bodySmall),
                            Text(profile.role, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bar_chart_outlined),
                        title: const Text('Reports'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.article_outlined),
                        title: const Text('Blog & insights'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.person_outline),
                        title: const Text('Profile'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.tune_outlined),
                        title: const Text('Preferences'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Security'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: ListTile(
                    leading: state.isLoggingOut
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Log out', style: TextStyle(color: Colors.red)),
                    onTap: state.isLoggingOut ? null : () => _confirmLogOut(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}