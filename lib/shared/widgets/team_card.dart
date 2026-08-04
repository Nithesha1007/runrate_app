import 'package:flutter/material.dart';
import '../models/team_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

/// Simple, glanceable row: name on the left, spend + trend arrow on the right.
class TeamCard extends StatelessWidget {
  final TeamModel team;
  final VoidCallback? onTap;

  const TeamCard({super.key, required this.team, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final up = team.trendPercent >= 0;
    return ListTile(
      onTap: onTap,
      title: Text(team.name, style: theme.textTheme.bodyLarge),
      subtitle: team.memberCount > 0 ? Text('\${team.memberCount} members', style: theme.textTheme.bodyMedium) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Formatters.currency(team.spend), style: theme.textTheme.headlineSmall),
          const SizedBox(width: 4),
          Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: up ? AppColors.danger : AppColors.success),
        ],
      ),
    );
  }
}
