import 'package:flutter/material.dart';
import 'app_card.dart';
import '../models/insight_model.dart';
import '../../core/theme/app_colors.dart';

class InsightCard extends StatelessWidget {
  final InsightModel insight;
  const InsightCard({super.key, required this.insight});

  Color _color() {
    switch (insight.severity) {
      case InsightSeverity.positive:
        return AppColors.success;
      case InsightSeverity.info:
        return AppColors.info;
      case InsightSeverity.warning:
        return AppColors.warning;
      case InsightSeverity.danger:
        return AppColors.danger;
    }
  }

  IconData _icon() {
    switch (insight.severity) {
      case InsightSeverity.positive:
        return Icons.trending_up;
      case InsightSeverity.info:
        return Icons.lightbulb_outline;
      case InsightSeverity.warning:
        return Icons.warning_amber_rounded;
      case InsightSeverity.danger:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(_icon(), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(insight.description, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
