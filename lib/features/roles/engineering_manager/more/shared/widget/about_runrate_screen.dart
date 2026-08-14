import 'package:flutter/material.dart';

import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';

/// More → About Runrate
///
/// New dedicated screen per spec: Runrate logo, "AI Spend Copilot"
/// tagline, app version, build number, What's New / release notes,
/// Privacy, Terms, Security, open-source licenses, contact Runrate.
/// Kept intentionally minimal per spec.
class AboutRunrateScreen extends StatelessWidget {
  const AboutRunrateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmScreenScaffold(
      title: 'About Runrate',
      body: EmScreenInProgress(
        icon: Icons.info_outline,
        description:
            'Logo, tagline, version/build, What\'s New, Privacy, Terms, '
            'Security, open-source licenses and contact details land '
            'here next.',
      ),
    );
  }
}
