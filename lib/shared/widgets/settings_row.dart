import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';

import 'icon_badge.dart';
import 'scale_on_tap.dart';

/// A single tappable row: icon badge, title/subtitle, and a trailing
/// chevron (or "Coming soon" pill when [isComingSoon]).
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isComingSoon = false,
    this.isDestructive = false,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isComingSoon;
  final bool isDestructive;

  /// Optional custom trailing widget (e.g. a Switch). Overrides the
  /// default chevron/"Coming soon" pill when provided.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final titleColor = isDestructive
        ? colors.danger
        : (isComingSoon ? colors.textSecondary : colors.textPrimary);

    return ScaleOnTap(
      onTap: isComingSoon ? null : onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, color: isDestructive ? colors.danger : iconColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLarge(titleColor)
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption(colors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (isComingSoon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.textSecondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Coming soon', style: AppTypography.label(colors.textSecondary)),
                )
              else
                Icon(Icons.chevron_right, size: 20, color: colors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row with a trailing [Switch.adaptive] instead of navigation chevron.
/// Used for Dark Mode / notification toggles.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.isComingSoon = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SettingsRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      isComingSoon: isComingSoon,
      onTap: isComingSoon ? null : () => onChanged?.call(!value),
      trailing: Switch.adaptive(
        value: value,
        onChanged: isComingSoon ? null : onChanged,
        activeColor: colors.primary,
      ),
    );
  }
}

