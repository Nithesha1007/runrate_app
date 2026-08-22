import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Subtle ambient glow orbs used behind Home / AI screens for a premium,
/// "alive" feel. Kept intentionally faint and slow so it never distracts
/// from foreground content. Uses only Primary/Secondary brand colors.
class GlowBackground extends StatefulWidget {
  final Widget child;
  const GlowBackground({super.key, required this.child});

  @override
  State<GlowBackground> createState() => _GlowBackgroundState();
}

class _GlowBackgroundState extends State<GlowBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final t = _controller.value;
                return Stack(
                  children: [
                    Positioned(
                      top: -60 + (t * 20),
                      right: -60,
                      child: _orb(AppColors.primary.withValues(alpha: 0.10), 220),
                    ),
                    Positioned(
                      bottom: -80 - (t * 15),
                      left: -70,
                      child: _orb(AppColors.secondary.withValues(alpha: 0.08), 260),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }

  Widget _orb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}
