class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.read = false,
  });
}
