// chat_bubble.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/shared/models/chat_message_model.dart';

/// Chat bubble for both user + bot messages.
///
/// - User bubble: solid app-color gradient fill, static.
/// - Bot bubble: dark/tinted fill, wrapped in a continuously-animated
///   glowing border that "chases" around the pill/rounded-rect edge —
///   Dynamic-Island style — built entirely from AppColors.primary so it
///   always matches your theme, not a fixed purple.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: isUser
            ? _UserBubble(text: message.text)
            : _BotBubble(text: message.text),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
          height: 1.35,
        ),
      ),
    );
  }
}

/// Bot bubble — dark tinted fill with a glowing highlight that continuously
/// travels around the border, like Apple's Dynamic Island reveal glow.
class _BotBubble extends StatefulWidget {
  const _BotBubble({required this.text});
  final String text;

  @override
  State<_BotBubble> createState() => _BotBubbleState();
}

class _BotBubbleState extends State<_BotBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  static const double _radius = 18;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // extra room so the outer glow isn't clipped
      padding: const EdgeInsets.all(6),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _GlowBorderPainter(
              progress: _controller.value,
              color: AppColors.primary,
              radius: _radius,
            ),
            child: child,
          );
        },
        child: Container(
          margin: const EdgeInsets.all(6), // keeps content clear of glow ring
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? Colors.black.withValues(alpha: 0.55)
                : context.appColors.primaryLight,
            borderRadius: BorderRadius.circular(_radius),
          ),
          child: Text(
            widget.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? Colors.white
                  : theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a soft, blurred glow that continuously chases around a rounded
/// rectangle's border — same idea as the Dynamic Island reveal animation,
/// but color-driven by [color] (your app's primary) instead of a fixed hue.
class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress; // 0..1, drives rotation
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // Faint always-visible base outline so the shape reads even between
    // glow passes.
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = color.withValues(alpha: 0.22);
    canvas.drawRRect(rrect, basePaint);

    // The traveling glow: a bright arc that sweeps fully around, fading
    // in/out at its head and tail, blurred for a soft neon look.
    final sweep = SweepGradient(
      transform: GradientRotation(progress * 2 * math.pi),
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.95),
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.62, 0.72, 0.82, 1.0],
    );

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..shader = sweep.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawRRect(rrect, glowPaint);

    // A second, wider + softer pass behind it for extra bloom.
    final bloomPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..shader = sweep.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
      ..color = color.withValues(alpha: 0.5);
    canvas.drawRRect(rrect, bloomPaint);
  }

  @override
  bool shouldRepaint(covariant _GlowBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}