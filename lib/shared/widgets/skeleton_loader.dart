import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Simple shimmering placeholder block shown while mock data "loads".
class SkeletonLoader extends StatefulWidget {
  final double height;
  final double width;
  const SkeletonLoader(
      {super.key, this.height = 16, this.width = double.infinity});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))
    ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: 0.4 + 0.3 * (1 - (_controller.value - 0.5).abs() * 2),
        child: Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
              color: context.appColors.border,
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
