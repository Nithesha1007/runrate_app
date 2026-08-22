import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/grouped_card.dart';
import 'package:runrate/shared/widgets/scale_on_tap.dart';
import 'package:runrate/shared/widgets/settings_row.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Security & Privacy
///
/// v2: the previous version deliberately desaturated every icon to
/// black/gray monochrome ("was colors.primary", "was colors.info" per the
/// old comments). That broke consistency with every other screen in the
/// app, which uses colored accent badges (primary/info/success/warning) —
/// this version restores that language here: Change Password gets the
/// primary accent, Active Sessions gets primary, the Privacy note gets
/// info, and the "coming soon" 2FA row stays intentionally muted (that
/// part was a reasonable call — a disabled feature reading as inactive is
/// correct, not a color-language violation).
///

/// your auth/session backend and wire "Log out" per session to your real
/// "revoke session" endpoint.
class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _Session {
  _Session({
    required this.device,
    required this.location,
    required this.lastActive,
    this.isCurrent = false,
  });

  final String device;
  final String location;
  final String lastActive;
  final bool isCurrent;
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 4;

  final bool _twoFactorEnabled = false;

  final List<_Session> _sessions = [
    _Session(
        device: 'This iPhone',
        location: 'Chennai, IN',
        lastActive: 'Active now',
        isCurrent: true),
    _Session(
        device: 'MacBook Pro',
        location: 'Chennai, IN',
        lastActive: 'Active 2h ago'),
    _Session(
        device: 'Windows PC',
        location: 'Bengaluru, IN',
        lastActive: 'Active 3d ago'),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    final colors = AppColors.of(context);
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: colors.surfaceElevated,
          title: Text('Change Password',
              style: AppTypography.h3(colors.textPrimary)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Current password'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) => (v == null || v.length < 8)
                      ? 'At least 8 characters'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Confirm new password'),
                  validator: (v) =>
                      v != newController.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.primary),
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
               
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated.')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _logOutSession(_Session session) {
    setState(() => _sessions.remove(session));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed out of ${session.device}.')),
    );

  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return EmScreenScaffold(
      title: 'Security & Privacy',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaggeredFade(
            index: 0,
            total: _blockCount,
            controller: _entrance,
            child: _SecurityOverviewHero(twoFactorEnabled: _twoFactorEnabled),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 1,
            total: _blockCount,
            controller: _entrance,
            child: GroupedCard(
              title: 'Sign-in security',
              children: [
                SettingsRow(
                  icon: Icons.lock_outline,
                  // Restored to the app's accent palette — an active,
                  // tappable security action reads as primary everywhere
                  // else in the app, so it does here too.
                  iconColor: colors.primary,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                SettingsSwitchRow(
                  icon: Icons.verified_user_outlined,
                  // Intentionally muted — this specific row is disabled
                  // ("Coming soon"), so textSecondary correctly signals
                  // "not active yet" rather than being a color-language
                  // violation like the rest of the screen was.
                  iconColor: colors.textSecondary,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Coming soon',
                  value: _twoFactorEnabled,
                  onChanged: null,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 2,
            total: _blockCount,
            controller: _entrance,
            child: _ActiveSessionsCard(
                sessions: _sessions, onLogOut: _logOutSession),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 3,
            total: _blockCount,
            controller: _entrance,
            child: const _PrivacyNoteCard(),
          ),
        ],
      ),
    );
  }
}

class _SecurityOverviewHero extends StatelessWidget {
  const _SecurityOverviewHero({required this.twoFactorEnabled});
  final bool twoFactorEnabled;

  @override
  Widget build(BuildContext context) {
    AppColors.of(context);
    return EmGradientHero(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account Protected',
                        style: AppTypography.h3(Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      twoFactorEnabled
                          ? 'Password + two-factor authentication active'
                          : 'Password protected · two-factor coming soon',
                      style: AppTypography.caption(
                          Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                    twoFactorEnabled
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    size: 13,
                    color: Colors.white),
                const SizedBox(width: 5),
                Text(
                  twoFactorEnabled ? '2 factors active' : '1 factor active',
                  style: AppTypography.caption(Colors.white)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shared card shell — colored icon badge (accent-tinted circle, not solid
/// black) matching the accent-badge pattern used across the rest of the
/// app, plus a soft neutral shadow and hairline top "chrome" edge.
class _PolishedCard extends StatelessWidget {
  const _PolishedCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            spreadRadius: -8,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.border,
                      accent.withValues(alpha: 0.35),
                      colors.border,
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.14),
                          ),
                          child: Icon(icon, size: 17, color: accent),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
                                  style: AppTypography.h3(colors.textPrimary)),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: AppTypography.caption(
                                      colors.textSecondary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    child,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSessionsCard extends StatelessWidget {
  const _ActiveSessionsCard({required this.sessions, required this.onLogOut});
  final List<_Session> sessions;
  final void Function(_Session) onLogOut;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _PolishedCard(
      title: 'Active Sessions',
      subtitle: '${sessions.length} device${sessions.length == 1 ? '' : 's'} signed in',
      icon: Icons.devices_rounded,
      accent: colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final session in sessions) ...[
            _SessionRow(session: session, onLogOut: () => onLogOut(session)),
            if (session != sessions.last)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1, color: colors.border),
              ),
          ],
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onLogOut});
  final _Session session;
  final VoidCallback onLogOut;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = session.isCurrent ? colors.success : colors.textSecondary;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            session.device.toLowerCase().contains('iphone')
                ? Icons.phone_iphone_rounded
                : session.device.toLowerCase().contains('mac')
                    ? Icons.laptop_mac_rounded
                    : Icons.desktop_windows_rounded,
            size: 17,
            color: accent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      session.device,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyLarge(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (session.isCurrent) ...[
                    const SizedBox(width: 6),
                    const StatusPill(
                        label: 'This device', tone: StatusTone.positive),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '${session.location} · ${session.lastActive}',
                style: AppTypography.caption(colors.textSecondary),
              ),
            ],
          ),
        ),
        if (!session.isCurrent)
          ScaleOnTap(
            onTap: onLogOut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Log out',
                  style: AppTypography.caption(colors.danger)
                      .copyWith(fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }
}

class _PrivacyNoteCard extends StatelessWidget {
  const _PrivacyNoteCard();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return _PolishedCard(
      title: 'What CEO & HR can see',
      icon: Icons.privacy_tip_rounded,
      accent: colors.info,
      child: Text(
        'Your reporting manager and company admins can see your team\'s '
        'AI spend, adoption, and approval activity. They cannot see '
        'your password, individual chat content, or personal messages '
        'sent to AI tools.',
        style: AppTypography.body(colors.textSecondary).copyWith(height: 1.5),
      ),
    );
  }
}