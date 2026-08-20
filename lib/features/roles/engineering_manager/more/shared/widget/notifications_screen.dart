import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Notifications
///
/// Fully self-contained — does NOT depend on `GroupedCard` /
/// `SettingsSwitchRow`. Everything below (icon badge, section card,
/// toggle) is local to this file so it doesn't change the look of any
/// other screen.
///
/// Style: flat, neutral, professional. No neon glow, no gradient badges —
/// icon circles use a plain flat tint of the section accent, cards use a
/// solid surface + hairline border, and the toggle is a standard flat
/// switch. Accent color still differentiates each section (Approvals,
/// Budget, AI usage, Team) so scanning stays easy.
///
/// TODO: still persists to local widget state only — swap `setState`
/// for your settings/preferences cubit when it's ready.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 4;

  bool _approvalPending = true;
  bool _approvalReminders = true;

  bool _budgetThreshold = true;
  bool _budgetForecast = true;

  bool _licenseUnderuse = true;
  bool _adoptionDrop = false;

  bool _teamMemberJoined = true;
  bool _teamStatusChange = true;

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

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return EmScreenScaffold(
      title: 'Notifications',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderBlurb(colors: colors),
          const SizedBox(height: AppSpacing.xl),
          StaggeredFade(
            index: 0,
            total: _blockCount,
            controller: _entrance,
            child: _Section(
              colors: colors,
              title: 'Approvals',
              accent: colors.primary,
              children: [
                _NotificationRow(
                  colors: colors,
                  accent: colors.primary,
                  icon: Icons.pending_actions_outlined,
                  title: 'New pending request',
                  subtitle: 'Notify me when an approval is assigned to me',
                  value: _approvalPending,
                  onChanged: (v) => setState(() => _approvalPending = v),
                ),
                _divider(colors),
                _NotificationRow(
                  colors: colors,
                  accent: colors.primary,
                  icon: Icons.timer_outlined,
                  title: 'Approval reminders',
                  subtitle: 'Remind me before an approval SLA expires',
                  value: _approvalReminders,
                  onChanged: (v) => setState(() => _approvalReminders = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 1,
            total: _blockCount,
            controller: _entrance,
            child: _Section(
              colors: colors,
              title: 'Budget',
              accent: colors.warning,
              children: [
                _NotificationRow(
                  colors: colors,
                  accent: colors.warning,
                  icon: Icons.local_fire_department_outlined,
                  title: 'Threshold warnings',
                  subtitle: 'Notify me when spend nears a budget limit',
                  value: _budgetThreshold,
                  onChanged: (v) => setState(() => _budgetThreshold = v),
                ),
                _divider(colors),
                _NotificationRow(
                  colors: colors,
                  accent: colors.warning,
                  icon: Icons.insights_outlined,
                  title: 'Forecast alerts',
                  subtitle:
                      'Notify me if the month-end forecast changes materially',
                  value: _budgetForecast,
                  onChanged: (v) => setState(() => _budgetForecast = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 2,
            total: _blockCount,
            controller: _entrance,
            child: _Section(
              colors: colors,
              title: 'AI usage & adoption',
              accent: colors.secondary,
              children: [
                _NotificationRow(
                  colors: colors,
                  accent: colors.secondary,
                  icon: Icons.token_outlined,
                  title: 'License underuse alerts',
                  subtitle: 'Notify me about unused seats on paid AI tools',
                  value: _licenseUnderuse,
                  onChanged: (v) => setState(() => _licenseUnderuse = v),
                ),
                _divider(colors),
                _NotificationRow(
                  colors: colors,
                  accent: colors.secondary,
                  icon: Icons.trending_down_outlined,
                  title: 'Adoption drop alerts',
                  subtitle: 'Notify me if team AI adoption drops significantly',
                  value: _adoptionDrop,
                  onChanged: (v) => setState(() => _adoptionDrop = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 3,
            total: _blockCount,
            controller: _entrance,
            child: _Section(
              colors: colors,
              title: 'Team',
              accent: colors.info,
              children: [
                _NotificationRow(
                  colors: colors,
                  accent: colors.info,
                  icon: Icons.person_add_alt_outlined,
                  title: 'New member joined',
                  value: _teamMemberJoined,
                  onChanged: (v) => setState(() => _teamMemberJoined = v),
                ),
                _divider(colors),
                _NotificationRow(
                  colors: colors,
                  accent: colors.info,
                  icon: Icons.error_outline_rounded,
                  title: 'Member status changes',
                  subtitle: 'Overloaded or blocked members',
                  value: _teamStatusChange,
                  onChanged: (v) => setState(() => _teamStatusChange = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _divider(AppColorsData colors) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Divider(
          height: 1,
          thickness: 1,
          color: colors.border,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────

class _HeaderBlurb extends StatelessWidget {
  const _HeaderBlurb({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 3),
          width: 3,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: colors.primary,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Choose what you get notified about across approvals, budget, '
            'AI usage and your team.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Section card — flat surface, hairline border, no glow
// ─────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.colors,
    required this.title,
    required this.accent,
    required this.children,
  });

  final AppColorsData colors;
  final String title;
  final Color accent;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: colors.surfaceElevated,
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Row: icon badge + text + toggle
// ─────────────────────────────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.colors,
    required this.accent,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AppColorsData colors;
  final Color accent;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        child: Row(
          children: [
            _IconBadge(icon: icon, accent: accent),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _FlatToggle(value: value, accent: accent, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Icon badge — flat tinted circle, no gradient, no glow.
// Same look whether on or off; the toggle alone carries the on/off state.
// ─────────────────────────────────────────────────────────────────────────

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.10),
      ),
      child: Icon(
        icon,
        size: 18,
        color: accent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Flat toggle switch — standard track + thumb, no glow/neon.
// ─────────────────────────────────────────────────────────────────────────

class _FlatToggle extends StatelessWidget {
  const _FlatToggle({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;

  static const double _w = 46;
  static const double _h = 26;
  static const double _thumb = 20;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: _w,
        height: _h,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_h / 2),
          color: value ? accent : colors.border,
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: _thumb,
            height: _thumb,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}