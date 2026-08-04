import 'package:flutter/material.dart';

/// Counts up from 0 to [value] whenever it first appears / changes.
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final TextStyle? style;

  const AnimatedCounter({super.key, required this.value, this.prefix = '', this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('\$prefix\${v.toStringAsFixed(0)}', style: style),
    );
  }
}
