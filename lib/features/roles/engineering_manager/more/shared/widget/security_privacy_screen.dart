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
/// New dedicated screen, separate from the existing
/// `engineering_manager_security_settings_screen.dart` (left untouched).
///
/// TODO: `_sessions` below is mock data. Replace with a real fetch from
/// your auth/session backend and wire "Log out" per session to your
/// real "revoke session" endpoint.
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

  bool _twoFactorEnabled = false;

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
                // TODO: wire to your real change-password endpoint.
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
    // TODO: call your real "revoke session" endpoint here.
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
                  iconColor: colors.primary,
                  title: 'Change Password',
                  onTap: _showChangePasswordDialog,
                ),
                SettingsSwitchRow(
                  icon: Icons.verified_user_outlined,
                  iconColor: colors.info,
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
            child: _PrivacyNoteCard(),
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
    return EmGradientHero(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Active Sessions', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          for (final session in sessions) ...[
            _SessionRow(session: session, onLogOut: () => onLogOut(session)),
            if (session != sessions.last) const Divider(height: AppSpacing.lg),
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
    return Row(
      children: [
        Icon(Icons.devices_outlined, size: 20, color: colors.textSecondary),
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
                      style: AppTypography.bodyLarge(colors.textPrimary),
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
            child: Text('Log out', style: AppTypography.caption(colors.danger)),
          ),
      ],
    );
  }
}

class _PrivacyNoteCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.privacy_tip_outlined,
                  size: 18, color: colors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text('What CEO & HR can see',
                  style: AppTypography.h3(colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your reporting manager and company admins can see your team\'s '
            'AI spend, adoption, and approval activity. They cannot see '
            'your password, individual chat content, or personal messages '
            'sent to AI tools.',
            style:
                AppTypography.body(colors.textSecondary).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}

