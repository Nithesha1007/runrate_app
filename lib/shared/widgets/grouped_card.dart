import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';


/// Rounded container that groups related rows with dividers between them,
/// used for every settings section instead of loose ListTiles.
class GroupedCard extends StatelessWidget {
  const GroupedCard({
    super.key,
    required this.children,
    this.title,
  });

  final List<Widget> children;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: AppSpacing.xs),
            child: Text(
              title!,
              style: AppTypography.label(colors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border, width: 1),
          ),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, thickness: 1, color: colors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

