import 'package:flutter/material.dart';

/// STAND-IN — replace with your real shared `_Staggered` widget if it
/// lives elsewhere. Kept public (`StaggeredFade`) so it can be imported
/// by any screen instead of being redefined per-file.
///
/// Wrap each section/block with this, passing its [index] and the [total]
/// block count for the screen. Call [controller].forward(from: 0) once
/// data has loaded to trigger the staggered fade+slide-up.
class StaggeredFade extends StatelessWidget {
  const StaggeredFade({
    super.key,
    required this.index,
    required this.total,
    required this.controller,
    required this.child,
  });

  final int index;
  final int total;
  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final start = (index / (total + 2)).clamp(0.0, 1.0);
    final end = ((index + 2) / (total + 2)).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

