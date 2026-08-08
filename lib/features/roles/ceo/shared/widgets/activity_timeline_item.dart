import 'package:flutter/material.dart';
import 'package:runrate/features/roles/ceo/shared/models/activity_model.dart';
import 'package:runrate/core/utils/formatters.dart';

class ActivityTimelineItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isLast;
  const ActivityTimelineItem(
      {required this.activity, this.isLast = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(activity.icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.text,
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text(Formatters.relativeTime(activity.occurredAt),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
