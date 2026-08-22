import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/core/theme/theme_cubit.dart';
import 'package:runrate/features/roles/ceo/more/profile_cubit.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/about_runrate_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/ai_activity_usage_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/budget_forecast_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/integrations_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/notifications_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/policies_approval_rules_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/profile_account_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/security_privacy_screen.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/team_reports_screen.dart';


import 'package:runrate/shared/widgets/grouped_card.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/settings_row.dart';
import 'package:runrate/shared/widgets/staggered.dart';
import 'engineering_manager_profile_edit_screen.dart';

/// Engineering Manager · More
///
/// Only touches the EM tab content. Does not rebuild bottom navigation,
/// does not touch other roles, does not touch the theme system beyond
/// calling the existing `ThemeCubit`.
///
/// Menu structure is now locked to the spec:
///   ACCOUNT      → Profile & Account, Notifications, Security & Privacy
///   MANAGEMENT   → Team Reports, Budget & Forecast, AI Activity & Usage
///   SETTINGS     → Policies & Approval Rules, Integrations,
///                  Approval Preferences
///   SUPPORT      → Help & Support
///   ABOUT        → About Runrate
///
/// "Team Performance" has been fully removed — it does not exist
/// anywhere in this file or its section builders.
///
/// The existing profile card and the existing Dark Mode toggle
/// (ThemeCubit) are preserved exactly as they were; the toggle is kept
/// as its own compact row (not one of the 11 navigable items) so the
/// five sections above stay exactly as specified.
class EngineeringManagerMoreScreen extends StatefulWidget {
  const EngineeringManagerMoreScreen({super.key});

  @override
  State<EngineeringManagerMoreScreen> createState() =>
      _EngineeringManagerMoreScreenState();
}

class _EngineeringManagerMoreScreenState
    extends State<EngineeringManagerMoreScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  static const _blockCount = 7;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(BuildContext context) async {
    final colors = AppColors.of(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.md),
              ListTile(
                leading:
                    Icon(Icons.photo_camera_outlined, color: colors.primary),
                title: Text('Take photo',
                    style: AppTypography.bodyLarge(colors.textPrimary)),
                onTap: () => Navigator.of(sheetContext).pop('camera'),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: colors.primary),
                title: Text('Choose from gallery',
                    style: AppTypography.bodyLarge(colors.textPrimary)),
                onTap: () => Navigator.of(sheetContext).pop('gallery'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: colors.danger),
                title: Text('Remove photo',
                    style: AppTypography.bodyLarge(colors.danger)),
                onTap: () => Navigator.of(sheetContext).pop('remove'),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    );

    if (choice == null || !context.mounted) return;

    if (choice == 'remove') {
      await context.read<ProfileCubit>().updateProfile(clearAvatar: true);
      return;
    }

    final picker = ImagePicker();
    final source =
        choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !context.mounted) return;

   
    // the resulting remote URL here instead of the local file path.
    await context.read<ProfileCubit>().updateProfile(avatarUrl: picked.path);
  }

  Future<void> _confirmLogOut(BuildContext context) async {
    final colors = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        title: Text('Log out of Runrate?',
            style: AppTypography.h3(colors.textPrimary)),
        content: Text(
          'You will need to sign in again to access your workspace.',
          style: AppTypography.body(colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      
      // repository before navigating.
      await context.read<ProfileCubit>().clear();
      if (context.mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('More', style: AppTypography.h2(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            StaggeredFade(
              index: 0,
              total: _blockCount,
              controller: _entrance,
              child: _ProfileHero(onEditAvatar: () => _pickAvatar(context)),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 1,
              total: _blockCount,
              controller: _entrance,
              child: _buildAppearanceRow(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 2,
              total: _blockCount,
              controller: _entrance,
              child: _buildAccountSection(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 3,
              total: _blockCount,
              controller: _entrance,
              child: _buildManagementSection(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 4,
              total: _blockCount,
              controller: _entrance,
              child: _buildSettingsSection(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 5,
              total: _blockCount,
              controller: _entrance,
              child: _buildSupportSection(context),
            ),
            const SizedBox(height: AppSpacing.lg),
            StaggeredFade(
              index: 6,
              total: _blockCount,
              controller: _entrance,
              child: _buildAboutSection(context),
            ),
            const SizedBox(height: AppSpacing.xl),
            _LogOutTile(onTap: () => _confirmLogOut(context)),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  /// Existing Dark Mode / Light Mode preference — untouched functionally
  /// (still driven by the existing `ThemeCubit`), just kept as its own
  /// compact row rather than a full "Preferences" section so it doesn't
  /// get miscounted as one of the 11 spec'd menu items.
  Widget _buildAppearanceRow(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final isDark = mode == ThemeMode.dark;
        return GroupedCard(
          title: 'Appearance',
          children: [
            SettingsSwitchRow(
              icon:
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              iconColor: isDark ? colors.info : colors.warning,
              title: 'Dark Mode',
              subtitle: isDark ? 'On' : 'Off',
              value: isDark,
              onChanged: (_) => context.read<ThemeCubit>().toggle(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final colors = AppColors.of(context);
    return GroupedCard(
      title: 'ACCOUNT',
      children: [
        SettingsRow(
          icon: Icons.person_outline,
          iconColor: colors.primary,
          title: 'Profile & Account',
          subtitle: 'Personal info, department, role, reporting manager',
          onTap: () => _push(context, const ProfileAccountScreen()),
        ),
        SettingsRow(
          icon: Icons.notifications_outlined,
          iconColor: colors.secondary,
          title: 'Notifications',
          subtitle: 'Approvals, budget, AI usage and team alerts',
          onTap: () => _push(context, const NotificationsScreen()),
        ),
        SettingsRow(
          icon: Icons.shield_outlined,
          iconColor: colors.info,
          title: 'Security & Privacy',
          subtitle: 'Password, two-factor auth, active sessions',
          onTap: () => _push(context, const SecurityPrivacyScreen()),
        ),
      ],
    );
  }

  Widget _buildManagementSection(BuildContext context) {
    final colors = AppColors.of(context);
    return GroupedCard(
      title: 'MANAGEMENT',
      children: [
        SettingsRow(
          icon: Icons.insights_outlined,
          iconColor: colors.primary,
          title: 'Team Reports',
          subtitle: 'Spend, budget and AI adoption trends',
          onTap: () => _push(context, const TeamReportsScreen()),
        ),
        SettingsRow(
          icon: Icons.pie_chart_outline,
          iconColor: colors.warning,
          title: 'Budget & Forecast',
          subtitle: 'Burn rate, month-end and quarter forecasts',
          onTap: () => _push(context, const BudgetForecastScreen()),
        ),
        SettingsRow(
          icon: Icons.auto_awesome_outlined,
          iconColor: colors.secondary,
          title: 'AI Activity & Usage',
          subtitle: 'Monitor AI spend, adoption and tool usage',
          onTap: () => _push(context, const AiActivityUsageScreen()),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    final colors = AppColors.of(context);
    return GroupedCard(
      title: 'SETTINGS',
      children: [
        SettingsRow(
          icon: Icons.gavel_outlined,
          iconColor: colors.primary,
          title: 'Policies & Approval Rules',
          subtitle: 'AI tool, budget and purchase policies',
          onTap: () => _push(context, const PoliciesApprovalRulesScreen()),
        ),
        SettingsRow(
          icon: Icons.hub_outlined,
          iconColor: colors.info,
          title: 'Integrations',
          subtitle: 'AI tools, dev, PM and communication apps',
          onTap: () => _push(context, const ApprovalPreferencesScreen()),
        ),
        SettingsRow(
          icon: Icons.rule_outlined,
          iconColor: colors.secondary,
          title: 'Approval Preferences',
          subtitle: 'Notifications, escalation, delegation',
          onTap: () => _push(context, const ApprovalPreferencesScreen()),
        ),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final colors = AppColors.of(context);
    return GroupedCard(
      title: 'SUPPORT',
      children: [
        SettingsRow(
          icon: Icons.support_agent_outlined,
          iconColor: colors.primary,
          title: 'Help & Support',
          subtitle: 'FAQs, contact support, report a problem',
          // onTap: () => _push(
          //   context,
          //   HelpSupportScreen(config: HelpSupportConfig.engineeringManager()),
          // ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final colors = AppColors.of(context);
    return GroupedCard(
      title: 'ABOUT',
      children: [
        SettingsRow(
          icon: Icons.info_outline,
          iconColor: colors.textSecondary,
          title: 'About Runrate',
          subtitle: 'Version, release notes, terms & privacy',
          onTap: () => _push(context, const AboutRunrateScreen()),
        ),
      ],
    );
  }
}

/// `ProfileState.avatarUrl` is either a remote URL (after your upload
/// endpoint is wired up) or, until then, a local file path fresh from
/// `image_picker`. Resolve the right [ImageProvider] for either case.
ImageProvider? _avatarImage(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty) return null;
  final isRemote =
      avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://');
  return isRemote
      ? NetworkImage(avatarUrl)
      : FileImage(File(avatarUrl)) as ImageProvider;
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.onEditAvatar});

  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profile) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.secondary],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        backgroundImage: _avatarImage(profile.avatarUrl),
                        child: profile.avatarUrl == null
                            ? Text(
                                profile.initials,
                                style: AppTypography.h2(Colors.white),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: ScaleOnTap(
                          onTap: onEditAvatar,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: colors.primary, width: 1.5),
                            ),
                            child: Icon(Icons.camera_alt,
                                size: 14, color: colors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name.isEmpty ? ' ' : profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h2(Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _Pill(
                                label: profile.role.isEmpty
                                    ? 'Engineering Manager'
                                    : profile.role),
                            if (profile.organization.isNotEmpty)
                              _Pill(label: profile.organization),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const EngineeringManagerProfileEditScreen(),
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: AppTypography.caption(Colors.white)),
    );
  }
}

class _LogOutTile extends StatelessWidget {
  const _LogOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.danger.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 18, color: colors.danger),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Log Out',
                style: AppTypography.bodyLarge(colors.danger)
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}