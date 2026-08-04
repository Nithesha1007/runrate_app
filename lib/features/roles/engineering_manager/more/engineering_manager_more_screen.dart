import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import 'engineering_manager_more_cubit.dart';

/// Engineering Manager · More
/// Reports, Blog & Insights, Profile, Preferences, Security, Log Out.
class EngineeringManagerMoreScreen extends StatelessWidget {
  const EngineeringManagerMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerMoreCubit()..loadProfile(),
      child: const _EngineeringManagerMoreView(),
    );
  }
}

class _EngineeringManagerMoreView extends StatelessWidget {
  const _EngineeringManagerMoreView();

  Future<void> _handleTap(BuildContext context, MoreMenuAction action) async {
    if (action == MoreMenuAction.logOut) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Log out'),
          content: const Text('You will need to sign in again to access your dashboard.'),
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
      if (confirmed == true && context.mounted) {
        // TODO: replace with the real sign-out call once auth wiring lands.
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
      return;
    }

    // TODO: align these with the project's actual named routes.
    final route = switch (action) {
      MoreMenuAction.reports => '/reports',
      MoreMenuAction.blogInsights => '/blog-insights',
      MoreMenuAction.profile => '/profile',
      MoreMenuAction.preferences => '/preferences',
      MoreMenuAction.security => '/security',
      MoreMenuAction.logOut => '/login',
    };
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerMoreCubit, EngineeringManagerMoreState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerMoreInitial() ||
              EngineeringManagerMoreLoading() =>
                const Center(child: CircularProgressIndicator()),
              EngineeringManagerMoreError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<EngineeringManagerMoreCubit>().loadProfile(),
                ),
              EngineeringManagerMoreLoaded(:final data) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  children: [
                    _ProfileHeader(data: data),
                    const SizedBox(height: AppSpacing.xl),
                    _MenuList(
                      items: data.menuItems,
                      onTap: (action) => _handleTap(context, action),
                    ),
                  ],
                ),
            };
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.data});

  final EngineeringManagerMoreData data;

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              data.initials,
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
                  data.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(data.role, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuList extends StatelessWidget {
  const _MenuList({required this.items, required this.onTap});

  final List<MoreMenuItem> items;
  final ValueChanged<MoreMenuAction> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuRow(item: items[i], onTap: () => onTap(items[i].action)),
            if (i != items.length - 1)
              Divider(height: 0.5, thickness: 0.5, color: theme.colorScheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.item, required this.onTap});

  final MoreMenuItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = item.isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(item.icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(item.label, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
            ),
            if (!item.isDestructive)
              Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
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
            Text('Couldn\'t load this screen', style: theme.textTheme.titleMedium),
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