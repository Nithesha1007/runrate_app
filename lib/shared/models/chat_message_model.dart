/// A single message in an AI Copilot conversation.
class ChatMessageModel {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime sentAt;

  const ChatMessageModel({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.sentAt,
  });
}
