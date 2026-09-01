import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/theme_cubit.dart';

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

/// Employee · More
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

void _showThemeSelector(BuildContext context) {
  final themeCubit = context.read<ThemeCubit>();
  final currentThemeMode = themeCubit.state;
  final colors = context.appColors;

  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      color: colors.background,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Appearance',
            style: appFontStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _ThemeOption(
            icon: Icons.brightness_7_outlined,
            title: 'Light',
            isSelected: currentThemeMode == ThemeMode.light,
            onTap: () {
              themeCubit.setMode(ThemeMode.light);
              Navigator.pop(context);
            },
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _ThemeOption(
            icon: Icons.brightness_4_outlined,
            title: 'Dark',
            isSelected: currentThemeMode == ThemeMode.dark,
            onTap: () {
              themeCubit.setMode(ThemeMode.dark);
              Navigator.pop(context);
            },
            colors: colors,
          ),
          const SizedBox(height: AppSpacing.md),
          _ThemeOption(
            icon: Icons.brightness_auto_outlined,
            title: 'System',
            isSelected: currentThemeMode == ThemeMode.system,
            onTap: () {
              themeCubit.setMode(ThemeMode.system);
              Navigator.pop(context);
            },
            colors: colors,
          ),
        ],
      ),
    ),
  );
}

class _EmployeeMoreView extends StatelessWidget {
  const _EmployeeMoreView();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.background,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(colors: colors),
                  const SizedBox(height: AppSpacing.lg),
                  _ProfileHero(state: state, colors: colors),
                  const SizedBox(height: AppSpacing.xl),
                  _MenuSectionLabel(label: 'Account', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  _MenuGroup(
                    colors: colors,
                    items: const [
                      _MenuEntry(icon: Icons.person_outline, label: 'Personal Info'),
                      _MenuEntry(icon: Icons.lock_outline, label: 'Security'),
                      _MenuEntry(icon: Icons.link_outlined, label: 'Linked Accounts'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _MenuSectionLabel(label: 'Preferences', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  _MenuGroup(
                    colors: colors,
                    items: [
                      const _MenuEntry(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                      ),
                      _MenuEntry(
                        icon: Icons.brightness_4_outlined,
                        label: 'Appearance',
                        onTap: () => _showThemeSelector(context),
                      ),
                      const _MenuEntry(
                        icon: Icons.language_outlined,
                        label: 'Language',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _MenuSectionLabel(label: 'Support', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  _MenuGroup(
                    colors: colors,
                    items: [
                      _MenuEntry(icon: Icons.help_outline, label: 'Help Center'),
                      _MenuEntry(icon: Icons.mail_outline, label: 'Contact Us'),
                      _MenuEntry(icon: Icons.feedback_outlined, label: 'Give Feedback'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _MenuSectionLabel(label: 'About', colors: colors),
                  const SizedBox(height: AppSpacing.md),
                  _MenuGroup(
                    colors: colors,
                    items: [
                      _MenuEntry(icon: Icons.info_outline, label: 'Company Info'),
                      _MenuEntry(icon: Icons.description_outlined, label: 'Privacy Policy'),
                      _MenuEntry(icon: Icons.article_outlined, label: 'Terms of Service'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _LogOutButton(
                    isBusy: state.isLoggingOut,
                    onTap: state.isLoggingOut
                        ? null
                        : () => context.read<EmployeeMoreCubit>().logOut(),
                    colors: colors,
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

class _Header extends StatelessWidget {
  const _Header({required this.colors});

  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: appFontStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Profile, preferences & settings',
          style: appFontStyle(fontSize: 13.5, color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.state, required this.colors});

  final EmployeeMoreState state;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primary, colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
            ),
            padding: const EdgeInsets.all(3),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.white.withOpacity(0.18),
              child: Text(
                state.employeeInitials,
                style: appFontStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.employeeName,
                  overflow: TextOverflow.ellipsis,
                  style: appFontStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    state.role,
                    overflow: TextOverflow.ellipsis,
                    style: appFontStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Edit',
              style: appFontStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
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
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
}

class _MenuSectionLabel extends StatelessWidget {
  const _MenuSectionLabel({required this.label, required this.colors});

  final String label;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: appFontStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items, required this.colors});

  final List<_MenuEntry> items;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _MenuTile(entry: items[i], colors: colors),
            if (i != items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Divider(height: 1, color: colors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.entry, required this.colors});

  final _MenuEntry entry;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: entry.onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 20, color: colors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                entry.label,
                style: appFontStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _LogOutButton extends StatelessWidget {
  const _LogOutButton({
    required this.isBusy,
    required this.onTap,
    required this.colors,
  });

  final bool isBusy;
  final VoidCallback? onTap;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: colors.danger.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: isBusy
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.danger,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded, color: colors.danger, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Log Out',
                      style: appFontStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.danger,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colors.primaryLight : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: appFontStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? colors.primary : colors.textPrimary,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 24, color: colors.primary)
            else
              Icon(Icons.circle_outlined, size: 24, color: colors.border),
          ],
        ),
      ),
    );
  }
}
