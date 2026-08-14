import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/shared/widgets/grouped_card.dart';
import 'package:runrate/shared/widgets/settings_row.dart';



/// Security Settings — session/device visibility and sign-out controls.
/// Session list is intentionally left as a TODO fetch since it depends on
/// your real auth/session backend.
class EngineeringManagerSecuritySettingsScreen extends StatefulWidget {
  const EngineeringManagerSecuritySettingsScreen({super.key});

  @override
  State<EngineeringManagerSecuritySettingsScreen> createState() =>
      _EngineeringManagerSecuritySettingsScreenState();
}

class _EngineeringManagerSecuritySettingsScreenState
    extends State<EngineeringManagerSecuritySettingsScreen> {
  // TODO: replace with your real login-alerts preference source.
  bool _loginAlerts = true;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('Security Settings', style: AppTypography.h2(colors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            GroupedCard(
              title: 'Sign-in',
              children: [
                SettingsSwitchRow(
                  icon: Icons.notifications_active_outlined,
                  iconColor: colors.warning,
                  title: 'New sign-in alerts',
                  subtitle: 'Email me when a new device signs in',
                  value: _loginAlerts,
                  onChanged: (v) => setState(() => _loginAlerts = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            GroupedCard(
              title: 'Devices',
              children: [
                SettingsRow(
                  icon: Icons.devices_outlined,
                  iconColor: colors.info,
                  title: 'Active Sessions',
                  isComingSoon: true,
                ),
                SettingsRow(
                  icon: Icons.logout,
                  iconColor: colors.danger,
                  title: 'Sign out of all other devices',
                  onTap: () {
                    // TODO: wire to your real "revoke other sessions" endpoint.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out of all other devices.')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
