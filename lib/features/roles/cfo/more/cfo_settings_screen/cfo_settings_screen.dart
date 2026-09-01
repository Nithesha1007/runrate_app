import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kPrimaryLight = Color(0xFFEDE9FE);
const _kBackground = Color(0xFFF1F0F4);
const _kCardRadius = 20.0;
const _kBorderColor = Color(0xFFECEAF1);

/// ---------------------------------------------------------------------
/// Accent palette (drives icon-square color + toggle "on" color per row)
/// ---------------------------------------------------------------------

class _Accent {
  const _Accent({
    required this.bg,
    required this.fg,
    required this.trackOn,
    required this.thumbOn,
  });

  final Color bg;
  final Color fg;
  final Color trackOn;
  final Color thumbOn;
}

const _accentPurple = _Accent(
  bg: Color(0xFFEDE9FE),
  fg: Color(0xFF6C5CE7),
  trackOn: Color(0xFFDDD6FE),
  thumbOn: Color(0xFF6C5CE7),
);

const _accentBlue = _Accent(
  bg: Color(0xFFDCEAFE),
  fg: Color(0xFF2563EB),
  trackOn: Color(0xFFBFDBFE),
  thumbOn: Color(0xFF2563EB),
);

const _accentOrange = _Accent(
  bg: Color(0xFFFFE8CC),
  fg: Color(0xFFD97706),
  trackOn: Color(0xFFFDE0B0),
  thumbOn: Color(0xFFD97706),
);

const _accentGreen = _Accent(
  bg: Color(0xFFD9F2E6),
  fg: Color(0xFF10B981),
  trackOn: Color(0xFFBBEFD9),
  thumbOn: Color(0xFF10B981),
);

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

class SettingsRowData {
  const SettingsRowData({
    required this.title,
    required this.subtitle,
    this.icon,
    this.isToggle = false,
    this.toggleValue = false,
    this.onTap,
    this.onToggleChanged,
    this.accent = _accentPurple,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final bool isToggle;
  final bool toggleValue;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggleChanged;
  final _Accent accent;
}

class SettingsSectionData {
  const SettingsSectionData({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<SettingsRowData> rows;
}

/// ---------------------------------------------------------------------
/// Screen
/// ---------------------------------------------------------------------

class CfoSettingsScreen extends StatefulWidget {
  const CfoSettingsScreen({super.key});

  @override
  State<CfoSettingsScreen> createState() => _CfoSettingsScreenState();
}

class _CfoSettingsScreenState extends State<CfoSettingsScreen> {
  bool _darkMode = false;

  List<SettingsSectionData> get _sections => [
        SettingsSectionData(
          title: 'Organization',
          icon: Icons.grid_view_rounded,
          rows: [
            SettingsRowData(
              title: 'Organization Profile',
              subtitle: 'Edit name, logo, and tax ID',
              icon: Icons.edit_outlined,
              accent: _accentPurple,
              onTap: () {},
            ),
            SettingsRowData(
              title: 'Currency & Localization',
              subtitle: 'USD Default, UTC-5',
              icon: Icons.public,
              accent: _accentBlue,
              onTap: () {},
            ),
          ],
        ),
        SettingsSectionData(
          title: 'Financial Controls',
          icon: Icons.account_balance_outlined,
          rows: [
            SettingsRowData(
              title: 'Budget Thresholds',
              subtitle: 'Configure percentage warnings for team budgets',
              icon: Icons.tune,
              accent: _accentGreen,
              onTap: () {},
            ),
            SettingsRowData(
              title: 'Approval Workflows',
              subtitle: 'Multi-tier routing and auto-approval limits',
              icon: Icons.fact_check_outlined,
              accent: _accentPurple,
              onTap: () {},
            ),
          ],
        ),
        SettingsSectionData(
          title: 'App Preferences',
          icon: Icons.settings_outlined,
          rows: [
            SettingsRowData(
              title: 'Dark Mode',
              subtitle: _darkMode ? 'On' : 'Off',
              icon: Icons.brightness_6_outlined,
              isToggle: true,
              toggleValue: _darkMode,
              accent: _accentPurple,
              onToggleChanged: (value) => setState(() => _darkMode = value),
            ),
            SettingsRowData(
              title: 'Language',
              subtitle: 'English (US)',
              icon: Icons.language,
              accent: _accentBlue,
              onTap: () {},
            ),
          ],
        ),
        SettingsSectionData(
          title: 'Security & Compliance',
          icon: Icons.shield_outlined,
          rows: [
            SettingsRowData(
              title: 'Single Sign-On (SSO)',
              subtitle: 'Manage Okta, Google Workspace',
              icon: Icons.vpn_key_outlined,
              accent: _accentPurple,
              onTap: () {},
            ),
            SettingsRowData(
              title: 'Audit Logs',
              subtitle: 'View system-wide activity',
              icon: Icons.receipt_long_outlined,
              accent: _accentOrange,
              onTap: () {},
            ),
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 30,
                color: Color(0xFF16151A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manage organizational preferences, financial controls, and security.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < _sections.length; i++) ...[
              _SettingsSection(data: _sections[i]),
              if (i != _sections.length - 1) const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBackground,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person_outline, color: Colors.grey.shade700, size: 18),
        ),
      ),
      titleSpacing: 0,
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Runrate',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: _kPrimaryLight, borderRadius: BorderRadius.circular(20)),
            child: const Text(
              'CFO VIEW',
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700, fontSize: 10, letterSpacing: 0.3),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(Icons.notifications_none_rounded, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Section + row widgets
/// ---------------------------------------------------------------------

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.data});

  final SettingsSectionData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 19,
            color: Color(0xFF16151A),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
            border: Border.all(color: _kBorderColor, width: 1),
          ),
          child: Column(
            children: [
              for (int i = 0; i < data.rows.length; i++) ...[
                _SettingsRow(data: data.rows[i]),
                if (i != data.rows.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Divider(color: Colors.grey.shade200, height: 1),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final SettingsRowData data;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(_kCardRadius),
      onTap: data.isToggle ? null : data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _IconSquare(icon: data.icon, accent: data.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (data.isToggle)
              _StyledToggle(
                value: data.toggleValue,
                accent: data.accent,
                onChanged: data.onToggleChanged,
              )
            else
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 24),
          ],
        ),
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  const _IconSquare({required this.icon, required this.accent});

  final IconData? icon;
  final _Accent accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: accent.bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon ?? Icons.circle_outlined, size: 20, color: accent.fg),
    );
  }
}

/// ---------------------------------------------------------------------
/// Custom pill toggle: white + black outline when off, tinted + solid
/// thumb when on — matches the reference screenshot styling.
/// ---------------------------------------------------------------------

class _StyledToggle extends StatelessWidget {
  const _StyledToggle({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final bool value;
  final _Accent accent;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 52,
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: value ? accent.trackOn : Colors.white,
          border: Border.all(
            color: value ? Colors.transparent : Colors.black87,
            width: 1.4,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? accent.thumbOn : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Bottom navigation bar
/// ---------------------------------------------------------------------