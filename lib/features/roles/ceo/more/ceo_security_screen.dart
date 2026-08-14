// ceo_security_settings_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/toast.dart';

class _SessionData {
  _SessionData({
    required this.device,
    required this.location,
    required this.lastActive,
    required this.isCurrent,
    required this.icon,
  });

  final String device;
  final String location;
  final String lastActive;
  final bool isCurrent;
  final IconData icon;
}

class CeoSecuritySettingsScreen extends StatefulWidget {
  const CeoSecuritySettingsScreen({super.key});

  @override
  State<CeoSecuritySettingsScreen> createState() =>
      _CeoSecuritySettingsScreenState();
}

class _CeoSecuritySettingsScreenState extends State<CeoSecuritySettingsScreen> {
  bool _twoFactor = false;
  bool _biometric = true;
  bool _loginAlerts = true;

  final List<_SessionData> _sessions = [
    _SessionData(
      device: 'iPhone 15 Pro — Runrate app',
      location: 'Coimbatore, IN',
      lastActive: 'Active now',
      isCurrent: true,
      icon: Icons.phone_iphone_rounded,
    ),
    _SessionData(
      device: 'MacBook Pro — Chrome',
      location: 'Coimbatore, IN',
      lastActive: '2 hours ago',
      isCurrent: false,
      icon: Icons.laptop_mac_rounded,
    ),
    _SessionData(
      device: 'Windows PC — Edge',
      location: 'Bengaluru, IN',
      lastActive: '3 days ago',
      isCurrent: false,
      icon: Icons.desktop_windows_rounded,
    ),
  ];

  void _revoke(_SessionData session) {
    setState(() => _sessions.remove(session));
    showAppToast(context, 'Signed out on ${session.device}');
  }

  void _showChangePasswordDialog() {
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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Security Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
        children: [
          Text('Authentication', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _CardShell(
            child: Column(
              children: [
                _ActionRow(
                  icon: Icons.password_rounded,
                  accent: colors.primary,
                  label: 'Change Password',
                  subtitle: 'Last changed 3 months ago',
                  onTap: _showChangePasswordDialog,
                ),
                Divider(height: AppSpacing.xl, color: colors.border),
                _SwitchRow(
                  icon: Icons.verified_user_rounded,
                  accent: colors.success,
                  label: 'Two-Factor Authentication',
                  subtitle: _twoFactor
                      ? 'Enabled via authenticator app'
                      : 'Add an extra layer of login security',
                  value: _twoFactor,
                  onChanged: (v) {
                    setState(() => _twoFactor = v);
                    showAppToast(context,
                        v ? 'Two-factor enabled' : 'Two-factor disabled');
                  },
                ),
                Divider(height: AppSpacing.xl, color: colors.border),
                _SwitchRow(
                  icon: Icons.fingerprint_rounded,
                  accent: colors.info,
                  label: 'Biometric Login',
                  subtitle: 'Use Face ID / fingerprint to sign in',
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Alerts', style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _CardShell(
            child: _SwitchRow(
              icon: Icons.notifications_active_rounded,
              accent: colors.warning,
              label: 'New Login Alerts',
              subtitle: 'Email me when a new device signs in',
              value: _loginAlerts,
              onChanged: (v) => setState(() => _loginAlerts = v),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: [
              Expanded(
                  child: Text('Active Sessions',
                      style: AppTypography.h3(colors.textPrimary))),
              Text('${_sessions.length} devices',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_sessions.isEmpty)
            _CardShell(
              child: Text('No active sessions',
                  style: AppTypography.body(colors.textSecondary)),
            )
          else
            _CardShell(
              child: Column(
                children: [
                  for (var i = 0; i < _sessions.length; i++) ...[
                    _SessionRow(
                      session: _sessions[i],
                      onRevoke: () => _revoke(_sessions[i]),
                    ),
                    if (i != _sessions.length - 1)
                      Divider(height: AppSpacing.xl, color: colors.border),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

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

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const size = 38.0;
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

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          _IconBadge(icon: icon, color: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: colors.textSecondary, size: 20),
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
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        _IconBadge(icon: icon, color: accent),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
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

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session, required this.onRevoke});

  final _SessionData session;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      children: [
        _IconBadge(
          icon: session.icon,
          color: session.isCurrent ? colors.success : colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(session.device,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (session.isCurrent) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: colors.success.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text('This device',
                          style: AppTypography.caption(colors.success)
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ],
              ),
              Text('${session.location} · ${session.lastActive}',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
        ),
        if (!session.isCurrent)
          TextButton(
            onPressed: onRevoke,
            style: TextButton.styleFrom(foregroundColor: colors.danger),
            child: const Text('Sign out'),
          ),
      ],
    );
  }
}
