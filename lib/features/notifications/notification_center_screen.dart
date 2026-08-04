import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/widgets/notification_tile.dart';
import '../../shared/widgets/empty_state.dart';
import 'notifications_cubit.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: BlocBuilder<NotificationsCubit, List>(
        builder: (context, notifications) {
          if (notifications.isEmpty) {
            return const EmptyState(title: 'You\'re all caught up', message: 'New notifications will show up here.', icon: Icons.notifications_none);
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (_, i) => NotificationTile(notification: notifications[i]),
          );
        },
      ),
    );
  }
}
