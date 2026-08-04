import 'package:flutter_bloc/flutter_bloc.dart';
import '../../shared/models/notification_model.dart';

/// Holds the in-app Notification Center feed. Approvals' reject flow calls
/// [push] to deliver the approver's rejection message to this feed so the
/// requester sees exactly why their request was declined.
class NotificationsCubit extends Cubit<List<NotificationModel>> {
  NotificationsCubit()
      : super([
          NotificationModel(
            id: 'n2',
            title: 'Monthly report ready',
            message: 'The July spend report is ready to view.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
            read: true,
          ),
        ]);

  void push(NotificationModel notification) {
    emit([notification, ...state]);
  }

  void markRead(String id) {
    emit([
      for (final n in state)
        if (n.id == id) (n..read = true) else n
    ]);
  }
}
