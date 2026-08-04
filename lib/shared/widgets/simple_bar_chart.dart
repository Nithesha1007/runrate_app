import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class BarChartPoint {
  final String label;
  final double value;
  const BarChartPoint({required this.label, required this.value});
}

/// Lightweight custom bar chart (no charting package). Bars animate their
/// height in via AnimatedContainer. Used for every "chart" surface in the app.
class SimpleBarChart extends StatelessWidget {
  final List<BarChartPoint> points;
  final double height;

  const SimpleBarChart({super.key, required this.points, this.height = 160});

  @override
  Widget build(BuildContext context) {
    final maxVal = points.map((p) => p.value).fold<double>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final ratio = maxVal == 0 ? 0.0 : p.value / maxVal;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: (height - 32) * ratio,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(p.label, style: Theme.of(context).textTheme.labelSmall, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
