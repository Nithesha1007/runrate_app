import 'package:flutter/material.dart';
import 'app_card.dart';
import 'animated_counter.dart';
import '../../core/theme/app_colors.dart';

class KpiCard extends StatelessWidget {
  final String label;
  final double value;
  final String prefix;
  final Color? accentColor;
  final IconData? icon;

  const KpiCard({super.key, required this.label, required this.value, this.prefix = '', this.accentColor, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 18, color: accentColor ?? AppColors.primary),
              if (icon != null) const SizedBox(width: 6),
              Text(label, style: theme.textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedCounter(value: value, prefix: prefix, style: theme.textTheme.headlineLarge),
        ],
      ),
    );
  }
}
