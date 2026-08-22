import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';

import 'employee_more_cubit.dart';

TextStyle appFontStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

extension _EmployeeMoreThemeExtensions on BuildContext {
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get mutedTextColor =>
      Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
  Color get cardColor => Theme.of(this).cardColor;
  Color get borderColor => Theme.of(this).dividerColor;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
}

/// Employee · More
/// Reports, Blog & Insights, Profile, Preferences, Security, Log Out.
class EmployeeMoreScreen extends StatelessWidget {
  const EmployeeMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeMoreCubit(),
      child: const _EmployeeMoreView(),
    );
  }
}

class _EmployeeMoreView extends StatelessWidget {
  const _EmployeeMoreView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldColor,
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        child: BlocBuilder<EmployeeMoreCubit, EmployeeMoreState>(
          builder: (context, state) {
            if (state.isLoading && state.employeeName.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.hasError && state.employeeName.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(state: state),
                  const SizedBox(height: AppSpacing.xl),
                  const _MenuGroup(
                    items: [
                      _MenuEntry(
                          icon: Icons.bar_chart_outlined, label: 'Reports'),
                      _MenuEntry(
                        icon: Icons.auto_stories_outlined,
                        label: 'Blog & insights',
                      ),
                      _MenuEntry(icon: Icons.person_outline, label: 'Profile'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _MenuGroup(
                    items: [
                      _MenuEntry(
                          icon: Icons.tune_outlined, label: 'Preferences'),
                      _MenuEntry(
                        icon: Icons.lock_outline,
                        label: 'Security',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _MenuGroup(
                    items: [
                      _MenuEntry(
                        icon: Icons.logout,
                        label: 'Log out',
                        destructive: true,
                        isLoading: state.isLoggingOut,
                        onTap: () => context.read<EmployeeMoreCubit>().logOut(),
                      ),
                    ],
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

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state});

  final EmployeeMoreState state;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: context.primaryColor.withValues(alpha: 0.12),
            child: Text(
              state.employeeInitials,
              style: appFontStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: context.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.employeeName,
                  style:
                      appFontStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  state.role,
                  style:
                      appFontStyle(fontSize: 12, color: context.mutedTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuEntry {
  const _MenuEntry({
    required this.icon,
    required this.label,
    this.destructive = false,
    this.isLoading = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool destructive;
  final bool isLoading;
  final VoidCallback? onTap;
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<_MenuEntry> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuTile(entry: items[i]),
            if (i != items.length - 1)
              Divider(height: 1, color: context.borderColor),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry});

  final _MenuEntry entry;

  @override
  Widget build(BuildContext context) {
    final color =
        entry.destructive ? const Color(0xFFA32D2D) : context.onSurfaceColor;

    return InkWell(
      onTap: entry.isLoading ? null : (entry.onTap ?? () {}),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(entry.icon, size: 20, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                entry.label,
                style: appFontStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            if (entry.isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.mutedTextColor,
                ),
              )
            else if (entry.onTap != null || !entry.destructive)
              Icon(Icons.chevron_right,
                  size: 18, color: context.mutedTextColor),
          ],
        ),
      ),
    );
  }
}
