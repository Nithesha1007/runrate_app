import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_more_cubit.dart';

/// CFO · More
/// Reports, Blog & Insights, Profile, Preferences, Security, Log Out,
/// wired to [CfoMoreCubit].
class CfoMoreScreen extends StatelessWidget {
  const CfoMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoMoreCubit(),
      child: const _CfoMoreView(),
    );
  }
}

class _CfoMoreView extends StatelessWidget {
  const _CfoMoreView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        child: BlocConsumer<CfoMoreCubit, CfoMoreState>(
          listener: (context, state) {
            if (state is CfoMoreLoggedOut) {
              // TODO: replace with real navigation to the login/auth flow.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out.')),
              );
            }
          },
          builder: (context, state) {
            if (state is CfoMoreLoading || state is CfoMoreInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoMoreError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoMoreCubit>().load(),
              );
            }

            if (state is CfoMoreLoggedOut) {
              return const Center(child: Text('You have been logged out.'));
            }

            final loaded = state as CfoMoreLoaded;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                AppCard(child: _ProfileHeader(profile: loaded.profile)),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel('Insights'),
                AppCard(
                  child: Column(
                    children: [
                      _MoreListTile(
                        icon: Icons.summarize_outlined,
                        title: 'Reports',
                        subtitle: 'Export financial reports and statements',
                        onTap: () {
                          // TODO: navigate to reports.
                        },
                      ),
                      const Divider(height: 1),
                      _MoreListTile(
                        icon: Icons.article_outlined,
                        title: 'Blog & insights',
                        subtitle: 'Guides and updates for finance teams',
                        onTap: () {
                          // TODO: navigate to blog & insights.
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionLabel('Account'),
                AppCard(
                  child: Column(
                    children: [
                      _MoreListTile(
                        icon: Icons.person_outline,
                        title: 'Profile',
                        subtitle: 'Name, email, and role',
                        onTap: () {
                          // TODO: navigate to profile.
                        },
                      ),
                      const Divider(height: 1),
                      _MoreListTile(
                        icon: Icons.tune_outlined,
                        title: 'Preferences',
                        subtitle: 'Notifications, currency, and language',
                        onTap: () {
                          // TODO: navigate to preferences.
                        },
                      ),
                      const Divider(height: 1),
                      _MoreListTile(
                        icon: Icons.lock_outline,
                        title: 'Security',
                        subtitle: 'Password, 2FA, and active sessions',
                        onTap: () {
                          // TODO: navigate to security.
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  child: _MoreListTile(
                    icon: Icons.logout,
                    title: 'Log out',
                    isDestructive: true,
                    isBusy: loaded.isLoggingOut,
                    onTap: loaded.isLoggingOut ? null : () => _confirmLogOut(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final cubit = context.read<CfoMoreCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log out?'),
          content: const Text('You\'ll need to sign in again to access the dashboard.'),
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
        );
      },
    );

    if (confirmed ?? false) {
      cubit.logOut();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final CfoProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            profile.initials,
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              Text(profile.role, style: theme.textTheme.bodySmall),
              Text(profile.email, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, 0, 0, AppSpacing.sm),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _MoreListTile extends StatelessWidget {
  const _MoreListTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
    this.isBusy = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: theme.textTheme.bodySmall) : null,
      trailing: isBusy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : (onTap != null && !isDestructive ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
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