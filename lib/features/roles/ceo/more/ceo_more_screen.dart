import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/ceo/more/ceo_blog_insight_screen.dart';

import 'package:runrate/features/roles/ceo/more/ceo_helpsupport_screen.dart';
import 'package:runrate/features/roles/ceo/more/ceo_report_centre_screen.dart';
import 'package:runrate/features/roles/ceo/more/ceo_security_screen.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/toast.dart';
import 'ceo_board_reports_screen.dart';

import 'ceo_profile_edit_screen.dart';

import 'profile_cubit.dart';

/// CEO · More — profile (with role/org + photo upload, now backed by the
/// shared ProfileCubit), theme + notification preferences, account &
/// security, reports, help & support, and logout.
///
/// VISUAL UPDATE: screen background is now a soft tinted off-white
/// (`colors.background`, e.g. 0xFFF6F7FB) instead of pure white, cards sit
/// on elevated white surfaces with soft shadows instead of flat borders,
/// and every `_IconBadge` uses a subtle gradient + colored drop-shadow so
/// icons read with more depth instead of flat low-alpha tint chips.
///
/// NOTE ON ThemeCubit: this screen assumes `ThemeCubit extends
/// Cubit<ThemeMode>` exposing a `toggle()` method and is already provided
/// above this screen in the widget tree. If your actual ThemeCubit's API
/// differs, only `_ThemeToggleTile` below needs to change.
///
/// NOTE ON ProfileCubit: assumed provided above this screen in the widget
/// tree (same level as ThemeCubit), hydrated on app start and populated on
/// login. See profile_cubit.dart.
///
/// NOTE ON IMAGE UPLOAD: uses `image_picker` for gallery/camera selection.
/// The picked file is only held in local state here for the hero preview —
/// the actual profile photo edit flow now lives in CeoProfileEditScreen,
/// which is the source of truth that persists via ProfileCubit.
class CeoMoreScreen extends StatelessWidget {
  const CeoMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      // Soft tinted background instead of pure white — this is what makes
      // the elevated white cards below actually read as "elevated".
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 100),
          children: [
            Text('More', style: AppTypography.h1(colors.textPrimary)),
            const SizedBox(height: 2),
            Text('Profile, preferences & settings',
                style: AppTypography.caption(colors.textSecondary)),
            const SizedBox(height: AppSpacing.xl),
            _Staggered(
              index: 0,
              child: _ProfileHeroCard(
                onEdit: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const CeoProfileEditScreen())),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
           const _Staggered(
              index: 1,
              child: _SectionLabel('Preferences'),
            ),
            const SizedBox(height: AppSpacing.md),
          const _Staggered(index: 1, child:  _ThemeToggleTile()),
            const SizedBox(height: AppSpacing.xxl),
         const   _Staggered(index: 2, child: _SectionLabel('Notifications')),
            const SizedBox(height: AppSpacing.md),
          const  _Staggered(index: 2, child:  _NotificationSettingsCard()),
            const SizedBox(height: AppSpacing.xxl),
         const   _Staggered(index: 3, child: _SectionLabel('Account & Security')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(
              index: 3,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.password_rounded,
                  label: 'Change Password',
                  accent: colors.primary,
                  onTap: () => _showChangePasswordDialog(context),
                ),
                const _TwoFactorTile(),
                _MoreTile(
                  icon: Icons.lock_rounded,
                  label: 'Security Settings',
                  accent: colors.info,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoSecuritySettingsScreen())),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
       const     _Staggered(index: 4, child: _SectionLabel('Reports & Insights')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(
              index: 4,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report Center',
                  accent: colors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoReportCenterScreen())),
                ),
                _MoreTile(
                  icon: Icons.slideshow_rounded,
                  label: 'Board Reports',
                  accent: const Color(0xFF9B51E0),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoBoardReportsScreen())),
                ),
                _MoreTile(
                  icon: Icons.shield_rounded,
                  label: 'AI Policy',
                  accent: colors.success,
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'AI Policy',
                    body: 'All AI-assisted spend recommendations are advisory. '
                        'Final approval always requires CEO or CFO sign-off, and every '
                        'AI-generated suggestion is logged for audit.',
                  ),
                ),
                _MoreTile(
                  icon: Icons.article_rounded,
                  label: 'Blog & Insights',
                  accent: colors.warning,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoBlogInsightsScreen())),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
         const   _Staggered(index: 5, child: _SectionLabel('Help & Support')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(
              index: 5,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Contact Support',
                  accent: colors.primary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoHelpSupportScreen())),
                ),
                _MoreTile(
                  icon: Icons.help_outline_rounded,
                  label: 'FAQ',
                  accent: colors.info,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoHelpSupportScreen())),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(
              index: 6,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.logout_rounded,
                  label: 'Log Out',
                  accent: colors.danger,
                  isDestructive: true,
                  onTap: () => _confirmLogout(context),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static void _showInfoDialog(BuildContext context,
      {required String title, required String body}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  static void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: newController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              showAppToast(context, 'Password updated');
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  static void _confirmLogout(BuildContext context) {
    final colors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content:
            const Text("You'll need to sign back in to access the dashboard."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.danger),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await context.read<ProfileCubit>().clear();
              if (!context.mounted) return;
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

/// Slide-up + fade stagger wrapper, indexed by section order.
class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60).clamp(0, 480)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Subtle scale-down-on-tap wrapper for tactile tiles/buttons.
class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        child: widget.child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Text(label, style: AppTypography.h3(colors.textPrimary));
  }
}

// ---------------------------------------------------------------------------
// PROFILE HERO — gradient card with avatar, name, role, and organization.
// Reads from the shared ProfileCubit instead of hardcoded constants, so it
// reflects login data and any edits made in CeoProfileEditScreen without a
// full app reload. Kept as a rich gradient card since it's the visual
// anchor of the screen (unchanged in intent from before).
// ---------------------------------------------------------------------------
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final profile = context.watch<ProfileCubit>().state;
    final name = profile.name.isEmpty ? 'Your Name' : profile.name;
    final role = profile.role.isEmpty ? 'CEO' : profile.role;
    final organization = profile.organization.isEmpty
        ? 'Your Organization'
        : profile.organization;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary,
              colors.secondary,
              colors.primary.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.28),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
                color: Colors.white.withValues(alpha: 0.16),
              ),
              alignment: Alignment.center,
              child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                  ? Text(profile.initials.isEmpty ? '?' : profile.initials,
                      style: AppTypography.h2(Colors.white))
                  : ClipOval(
                      child: profile.avatarUrl!.startsWith('http')
                          ? Image.network(
                              profile.avatarUrl!,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                  profile.initials.isEmpty
                                      ? '?'
                                      : profile.initials,
                                  style: AppTypography.h2(Colors.white)),
                            )
                          : Image.file(
                              File(profile.avatarUrl!),
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Text(
                                  profile.initials.isEmpty
                                      ? '?'
                                      : profile.initials,
                                  style: AppTypography.h2(Colors.white)),
                            ),
                    ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: AppTypography.h3(Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 6,
                    children: [
                      _RolePill(label: role),
                      _RolePill(label: organization),
                    ],
                  ),
                ],
              ),
            ),
            _ScaleOnTap(
              onTap: onEdit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.35)),
                ),
                child: Text('Edit',
                    style: AppTypography.caption(Colors.white)
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: AppTypography.caption(Colors.white)
              .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ---------------------------------------------------------------------------
// THEME TOGGLE — colored icon badge that morphs between sun/moon, animated
// switch track using accent color instead of default Material switch.
// ---------------------------------------------------------------------------
class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeCubit = context.watch<ThemeCubit>();
    final isDark = themeCubit.state == ThemeMode.dark;

    return _CardShell(
      child: Row(
        children: [
          _IconBadge(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: colors.primary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dark Mode',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(isDark ? 'On' : 'Off',
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: isDark,
            // ignore: deprecated_member_use
            activeColor: colors.primary,
            onChanged: (_) => context.read<ThemeCubit>().toggle(),
          ),
        ],
      ),
    );
  }
}

class _NotificationSettingsCard extends StatefulWidget {
  const _NotificationSettingsCard();

  @override
  State<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<_NotificationSettingsCard> {
  bool _email = true;
  bool _push = true;
  bool _alerts = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _CardShell(
      child: Column(
        children: [
          _SwitchRow(
            icon: Icons.mail_outline_rounded,
            accent: colors.info,
            label: 'Email notifications',
            value: _email,
            onChanged: (v) => setState(() => _email = v),
          ),
          Divider(height: AppSpacing.xl, color: colors.border),
          _SwitchRow(
            icon: Icons.notifications_active_rounded,
            accent: colors.primary,
            label: 'Push notifications',
            value: _push,
            onChanged: (v) => setState(() => _push = v),
          ),
          Divider(height: AppSpacing.xl, color: colors.border),
          _SwitchRow(
            icon: Icons.warning_amber_rounded,
            accent: colors.warning,
            label: 'Critical spend alerts',
            value: _alerts,
            onChanged: (v) => setState(() => _alerts = v),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        _IconBadge(icon: icon, color: accent, size: 34),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(label,
              style: AppTypography.body(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Switch.adaptive(
          value: value,
          // ignore: deprecated_member_use
          activeColor: accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _TwoFactorTile extends StatefulWidget {
  const _TwoFactorTile();

  @override
  State<_TwoFactorTile> createState() => _TwoFactorTileState();
}

class _TwoFactorTileState extends State<_TwoFactorTile> {
  bool _enabled = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _IconBadge(icon: Icons.verified_user_rounded, color: colors.success),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Two-Factor Authentication',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Coming soon',
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _enabled,
            // ignore: deprecated_member_use
            activeColor: colors.success,
            onChanged: (v) {
              showAppToast(context, 'Two-factor authentication is coming soon');
              setState(() => _enabled = false);
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SHARED SHELL + TILE
//
// VISUAL UPDATE: both _CardShell and _TileGroup now sit on a plain white
// (`colors.surfaceElevated`) surface with a soft drop shadow instead of a
// flat 1px border on a white-on-white background — this is what gives the
// "premium" elevated look against the tinted screen background above.
// ---------------------------------------------------------------------------
class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _TileGroup extends StatelessWidget {
  const _TileGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: colors.border),
          ],
        ],
      ),
    );
  }
}

/// VISUAL UPDATE: instead of a flat single-alpha tint chip, each badge now
/// uses a subtle diagonal gradient (darker → lighter tint of the accent
/// color) plus a matching soft colored drop-shadow. This is what gives
/// icons visible depth instead of looking like flat pastel squares.
class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color, this.size = 38});
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.24),
            color.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.20),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final textColor = isDestructive ? colors.danger : colors.textPrimary;
    return _ScaleOnTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: AppTypography.body(textColor)
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
