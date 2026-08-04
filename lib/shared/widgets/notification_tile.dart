import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../../core/theme/app_colors.dart';

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const NotificationTile({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: context.appColors.primaryLight,
        child: Icon(
            notification.read
                ? Icons.notifications_none
                : Icons.notifications_active,
            color: AppColors.primary),
      ),
      title: Text(notification.title, style: theme.textTheme.bodyLarge),
      subtitle: Text(notification.message, style: theme.textTheme.bodyMedium),
      trailing: notification.read
          ? null
          : const CircleAvatar(radius: 4, backgroundColor: AppColors.danger),
    );
  }
}
