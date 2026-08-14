import 'package:flutter/material.dart';
import '../../core/theme/theme_utils.dart';
import '../../core/constants/app_radius.dart';

/// Premium "Ask anything..." input bar with glassmorphism + glow.
/// Drop this in place of your existing bottom chat input widget.
class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMicTap;
  final VoidCallback? onFileTap;
  final VoidCallback? onToolsTap;
  final bool isListening;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onMicTap,
    this.onFileTap,
    this.onToolsTap,
    this.isListening = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(top: BorderSide(color: context.borderColor, width: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Glass input field ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.cardColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppRadius.card + 6),
              border: Border.all(
                color: _hasText
                    ? primary.withOpacity(0.6)
                    : context.borderColor.withOpacity(0.8),
                width: 1.2,
              ),
              boxShadow: _hasText
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.25),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: TextField(
              controller: widget.controller,
              minLines: 1,
              maxLines: 5,
              style: TextStyle(color: context.textPrimary, fontSize: 15.5),
              cursorColor: primary,
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Ask anything...',
                hintStyle: TextStyle(color: context.textSecondary, fontSize: 15.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- Action row: File / Tools chips + Mic + Send ---
          Row(
            children: [
              _PillButton(
                icon: Icons.attach_file_rounded,
                label: 'File',
                onTap: widget.onFileTap,
              ),
              const SizedBox(width: 8),
              _PillButton(
                icon: Icons.tune_rounded,
                label: 'Tools',
                onTap: widget.onToolsTap,
              ),
              const Spacer(),
              _CircleIconButton(
                icon: widget.isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                onTap: widget.onMicTap,
                glowing: widget.isListening,
                glowColor: primary,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.arrow_upward_rounded,
                onTap: _hasText ? widget.onSend : null,
                filled: _hasText,
                fillColor: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _PillButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: context.textSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool filled;
  final bool glowing;
  final Color? fillColor;
  final Color? glowColor;

  const _CircleIconButton({
    required this.icon,
    this.onTap,
    this.filled = false,
    this.glowing = false,
    this.fillColor,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    final bg = filled
        ? (fillColor ?? Theme.of(context).primaryColor)
        : context.cardColor.withOpacity(0.6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bg,
          border: filled ? null : Border.all(color: context.borderColor),
          boxShadow: glowing
              ? [
                  BoxShadow(
                    color: (glowColor ?? Theme.of(context).primaryColor)
                        .withOpacity(0.5),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: filled
              ? Colors.white
              : (active ? context.textPrimary : context.textSecondary.withOpacity(0.5)),
        ),
      ),
    );
  }
}