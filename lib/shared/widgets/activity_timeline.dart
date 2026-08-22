import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ActivityTimelineItem {
  final String title;
  final String time;
  const ActivityTimelineItem({required this.title, required this.time});
}


class ActivityTimeline extends StatelessWidget {
  final List<ActivityTimelineItem> items;
  const ActivityTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((i) => ListTile(
                leading: const Icon(Icons.circle, size: 10, color: AppColors.primary),
                title: Text(i.title),
                trailing: Text(i.time, style: Theme.of(context).textTheme.bodyMedium),
              ))
          .toList(),
    );
  }
}
