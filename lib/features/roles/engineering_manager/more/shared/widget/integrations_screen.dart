import 'package:flutter/material.dart';

import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';

/// More → Approval Preferences
///
/// New dedicated screen per spec: approval notification preferences,
/// threshold visibility, escalation preferences, delegation/backup
/// approver, reminder preferences. Scoped to manager-level preferences
/// only — intentionally does NOT duplicate the full Approvals workflow
/// screen elsewhere in the app.
class ApprovalPreferencesScreen extends StatelessWidget {
  const ApprovalPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmScreenScaffold(
      title: 'Approval Preferences',
      body: EmScreenInProgress(
        icon: Icons.rule_outlined,
        description:
            'Approval notification, escalation, delegation/backup '
            'approver and reminder preferences land here next.',
      ),
    );
  }
}
