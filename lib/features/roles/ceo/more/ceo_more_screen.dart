import 'package:flutter/material.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../shared/widgets/avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../more/ceo_reports_screen.dart';

/// CEO · More — Reports, Board Reports, AI Policy, Blog & Insights, plus
/// shortcuts to Profile / Preferences / Security, and Log Out.
class CeoMoreScreen extends StatelessWidget {
  const CeoMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppCard(
            child: Row(
              children: const [
                Avatar(name: 'Jordan Lee'),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jordan Lee', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('CEO · Acme Corp'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('Reports & Insights', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _MoreTile(
            icon: Icons.bar_chart,
            label: 'Report Center',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CeoReportsScreen())),
          ),
          _MoreTile(
            icon: Icons.slideshow,
            label: 'Board Reports',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CeoReportsScreen())),
          ),
          _MoreTile(icon: Icons.shield, label: 'AI Policy', onTap: () {}),
          _MoreTile(icon: Icons.article, label: 'Blog & Insights', onTap: () {}),
          const SizedBox(height: AppSpacing.xxl),
          Text('Account', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          _MoreTile(icon: Icons.person, label: 'My Profile', onTap: () => Navigator.of(context).pushNamed(RouteNames.profile)),
          _MoreTile(icon: Icons.settings, label: 'Preferences', onTap: () => Navigator.of(context).pushNamed(RouteNames.preferences)),
          _MoreTile(icon: Icons.lock, label: 'Security', onTap: () => Navigator.of(context).pushNamed(RouteNames.security)),
          const SizedBox(height: AppSpacing.xxl),
          _MoreTile(
            icon: Icons.logout,
            label: 'Log Out',
            isDestructive: true,
            onTap: () => Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false),
          ),
        ],
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  const _MoreTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Theme.of(context).colorScheme.error : null),
      title: Text(label, style: TextStyle(color: isDestructive ? Theme.of(context).colorScheme.error : null)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
