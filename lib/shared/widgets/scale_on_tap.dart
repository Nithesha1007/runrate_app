import 'package:flutter/material.dart';

/// STAND-IN — replace with your real shared `_ScaleOnTap` widget if it
/// lives elsewhere. Kept public (`ScaleOnTap`) so it can be imported by
/// any tappable tile instead of being redefined per-file.
class ScaleOnTap extends StatefulWidget {
  const ScaleOnTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final BorderRadius? borderRadius;

  @override
  State<ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<ScaleOnTap> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0.0,
    upperBound: 1.0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapEnd([_]) {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: (d) {
        _onTapEnd();
        widget.onTap?.call();
      },
      onTapCancel: _onTapEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1 - (_controller.value * (1 - widget.scale));
          return Transform.scale(scale: scale, child: child);
        },
        child: widget.child,
      ),
    );
  }
}

