import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import 'package:runrate/shared/widgets/grouped_card.dart';
import 'package:runrate/shared/widgets/settings_row.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Notifications
///
/// Grouped notification preference toggles, organized to match the
/// categories already implied on the More screen tile subtitle
/// ("Approvals, budget, AI usage and team alerts").
///
/// TODO: this currently persists to local widget state only. If the
/// project has a settings/preferences cubit already, swap the
/// `setState` calls below for calls into that cubit so preferences
/// survive app restarts and sync across devices.
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
        vsync: this, duration: const Duration(milliseconds: 500));
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
          Text(
            'Choose what you get notified about across approvals, budget, '
            'AI usage and your team.',
            style: TextStyle(color: colors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFade(
            index: 0,
            total: _blockCount,
            controller: _entrance,
            child: GroupedCard(
              title: 'Approvals',
              children: [
                SettingsSwitchRow(
                  icon: Icons.pending_actions_outlined,
                  iconColor: colors.primary,
                  title: 'New pending request',
                  subtitle: 'Notify me when an approval is assigned to me',
                  value: _approvalPending,
                  onChanged: (v) => setState(() => _approvalPending = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.alarm_outlined,
                  iconColor: colors.primary,
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
            child: GroupedCard(
              title: 'Budget',
              children: [
                SettingsSwitchRow(
                  icon: Icons.warning_amber_outlined,
                  iconColor: colors.warning,
                  title: 'Threshold warnings',
                  subtitle: 'Notify me when spend nears a budget limit',
                  value: _budgetThreshold,
                  onChanged: (v) => setState(() => _budgetThreshold = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.query_stats_outlined,
                  iconColor: colors.warning,
                  title: 'Forecast alerts',
                  subtitle: 'Notify me if the month-end forecast changes materially',
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
            child: GroupedCard(
              title: 'AI usage & adoption',
              children: [
                SettingsSwitchRow(
                  icon: Icons.key_off_outlined,
                  iconColor: colors.secondary,
                  title: 'License underuse alerts',
                  subtitle: 'Notify me about unused seats on paid AI tools',
                  value: _licenseUnderuse,
                  onChanged: (v) => setState(() => _licenseUnderuse = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.trending_down_outlined,
                  iconColor: colors.secondary,
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
            child: GroupedCard(
              title: 'Team',
              children: [
                SettingsSwitchRow(
                  icon: Icons.person_add_alt_outlined,
                  iconColor: colors.info,
                  title: 'New member joined',
                  value: _teamMemberJoined,
                  onChanged: (v) => setState(() => _teamMemberJoined = v),
                ),
                SettingsSwitchRow(
                  icon: Icons.sync_problem_outlined,
                  iconColor: colors.info,
                  title: 'Member status changes',
                  subtitle: 'Overloaded or blocked members',
                  value: _teamStatusChange,
                  onChanged: (v) => setState(() => _teamStatusChange = v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
