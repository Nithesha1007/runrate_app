import 'package:flutter/material.dart';
import 'app_card.dart';
import 'progress_ring.dart';
import '../../core/theme/app_colors.dart';

class BudgetProgressCard extends StatelessWidget {
  final String title;
  final double percentUsed;

  const BudgetProgressCard({super.key, required this.title, required this.percentUsed});

  @override
  Widget build(BuildContext context) {
    final over = percentUsed > 100;
    return AppCard(
      child: Row(
        children: [
          ProgressRing(value: (percentUsed / 100).clamp(0, 1), color: over ? AppColors.danger : AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('\${percentUsed.toStringAsFixed(0)}% of budget used', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
