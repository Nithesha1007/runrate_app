import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_radius.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    final theme = Theme.of(context);
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : theme.cardColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.card),
            topRight: const Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(isUser ? AppRadius.card : 4),
            bottomRight: Radius.circular(isUser ? 4 : AppRadius.card),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyLarge?.copyWith(color: isUser ? Colors.white : theme.textTheme.bodyLarge?.color),
        ),
      ),
    );
  }
}
