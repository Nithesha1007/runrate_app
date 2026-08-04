import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Animated ring that grows from 0 to [value] (0..1) on first build.
class ProgressRing extends StatelessWidget {
  final double value;
  final Color color;
  final double size;

  const ProgressRing(
      {super.key,
      required this.value,
      this.color = AppColors.primary,
      this.size = 56});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
                value: v,
                strokeWidth: 6,
                color: color,
                backgroundColor: context.appColors.border),
            Text('\${(v * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }
}
