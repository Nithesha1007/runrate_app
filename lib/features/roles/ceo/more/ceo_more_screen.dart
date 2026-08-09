import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:runrate/features/roles/ceo/ceo_reports_screen.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../shared/widgets/toast.dart';

/// CEO · More — profile (with role/org + photo upload), theme + notification
/// preferences, account & security, reports, help & support, and logout.
///
/// NOTE ON ThemeCubit: this screen assumes `ThemeCubit extends
/// Cubit<ThemeMode>` exposing a `toggle()` method and is already provided
/// above this screen in the widget tree. If your actual ThemeCubit's API
/// differs, only `_ThemeToggleTile` below needs to change.
///
/// NOTE ON IMAGE UPLOAD: uses `image_picker` for gallery/camera selection.
/// Add `image_picker: ^1.0.0` to pubspec.yaml if not already present. The
/// picked file is only held in local state here — wire `_onImagePicked` in
/// `_ProfileHeroCard` to your upload/repository call when ready.
class CeoMoreScreen extends StatelessWidget {
  const CeoMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
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
                onEdit: () =>
                    Navigator.of(context).pushNamed(RouteNames.profile),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(
              index: 1,
              child: _SectionLabel('Preferences'),
            ),
            const SizedBox(height: AppSpacing.md),
            _Staggered(index: 1, child: const _ThemeToggleTile()),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(index: 2, child: _SectionLabel('Notifications')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(index: 2, child: const _NotificationSettingsCard()),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(index: 3, child: _SectionLabel('Account & Security')),
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
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.security),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(index: 4, child: _SectionLabel('Reports & Insights')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(
              index: 4,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report Center',
                  accent: colors.secondary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoReportsScreen())),
                ),
                _MoreTile(
                  icon: Icons.slideshow_rounded,
                  label: 'Board Reports',
                  accent: const Color(0xFF9B51E0),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CeoReportsScreen())),
                ),
                _MoreTile(
                  icon: Icons.shield_rounded,
                  label: 'AI Policy',
                  accent: colors.success,
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'AI Policy',
                    body:
                        'All AI-assisted spend recommendations are advisory. '
                        'Final approval always requires CEO or CFO sign-off, and every '
                        'AI-generated suggestion is logged for audit.',
                  ),
                ),
                _MoreTile(
                  icon: Icons.article_rounded,
                  label: 'Blog & Insights',
                  accent: colors.warning,
                  onTap: () =>
                      showAppToast(context, 'Opening Blog & Insights...'),
                ),
              ]),
            ),
            const SizedBox(height: AppSpacing.xxl),
            _Staggered(index: 5, child: _SectionLabel('Help & Support')),
            const SizedBox(height: AppSpacing.md),
            _Staggered(
              index: 5,
              child: _TileGroup(children: [
                _MoreTile(
                  icon: Icons.support_agent_rounded,
                  label: 'Contact Support',
                  accent: colors.primary,
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'Contact Support',
                    body:
                        'Reach the support team any time at support@acmecorp.com — '
                        'we typically respond within one business day.',
                  ),
                ),
                _MoreTile(
                  icon: Icons.help_outline_rounded,
                  label: 'FAQ',
                  accent: colors.info,
                  onTap: () => _showInfoDialog(
                    context,
                    title: 'FAQ',
                    body:
                        'Find answers to common questions about approvals, budgets, '
                        'and the AI Copilot in the Help Center.',
                  ),
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
            onPressed: () {
              Navigator.of(dialogContext).pop();
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
// PROFILE HERO — gradient card with avatar (tap to upload/change photo),
// name, role, and organization. Matches the Home/Teams/Approvals hero style.
// ---------------------------------------------------------------------------
class _ProfileHeroCard extends StatefulWidget {
  const _ProfileHeroCard({required this.onEdit});
  final VoidCallback onEdit;

  @override
  State<_ProfileHeroCard> createState() => _ProfileHeroCardState();
}

class _ProfileHeroCardState extends State<_ProfileHeroCard> {
  File? _pickedImage;
  bool _picking = false;

  Future<void> _openImageSourceSheet() async {
    final colors = AppColors.of(context);
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Text('Update profile photo',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.lg),
            _SheetOption(
              icon: Icons.photo_camera_rounded,
              label: 'Take a photo',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            const SizedBox(height: AppSpacing.sm),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'Choose from gallery',
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            if (_pickedImage != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                isDestructive: true,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  setState(() => _pickedImage = null);
                },
              ),
            ],
          ],
        ),
      ),
    );

    if (source == null) return;

    setState(() => _picking = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: source, imageQuality: 85);
      if (file != null && mounted) {
        setState(() => _pickedImage = File(file.path));
        // TODO: upload `_pickedImage` via your profile repository/API here.
        if (mounted) showAppToast(context, 'Profile photo updated');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    const name = 'Jordan Lee';
    const role = 'CEO';
    const organization = 'Acme Corp';

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
        ),
        child: Row(
          children: [
            _ScaleOnTap(
              onTap: _picking ? () {} : _openImageSourceSheet,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2),
                      color: Colors.white.withValues(alpha: 0.16),
                      image: _pickedImage != null
                          ? DecorationImage(
                              image: FileImage(_pickedImage!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: _picking
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : (_pickedImage == null
                            ? Text(
                                name
                                    .split(' ')
                                    .map((e) => e.isNotEmpty ? e[0] : '')
                                    .take(2)
                                    .join()
                                    .toUpperCase(),
                                style: AppTypography.h2(Colors.white),
                              )
                            : null),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.background,
                        border: Border.all(color: colors.primary, width: 1.6),
                      ),
                      child: Icon(Icons.camera_alt_rounded,
                          size: 13, color: colors.primary),
                    ),
                  ),
                ],
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
              onTap: widget.onEdit,
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

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = isDestructive ? colors.danger : colors.textPrimary;
    return _ScaleOnTap(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: AppSpacing.md),
            Text(label,
                style: AppTypography.body(color)
                    .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
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
// SHARED SHELL + TILE — every settings row now has a colored icon badge
// (from the app's accent palette) instead of a flat default-color icon.
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
        border: Border.all(color: colors.border),
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
        border: Border.all(color: colors.border),
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
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
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