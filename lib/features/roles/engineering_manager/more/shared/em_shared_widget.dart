import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';

/// Small reusable building blocks shared by the EM · More destination
/// screens (Profile & Account, Notifications, Security & Privacy, Team
/// Reports, Budget & Forecast, AI Activity & Usage, Policies & Approval
/// Rules).
///

/// a currency-formatting helper under a different name/API, swap the
/// ones below for those instead — these exist so every screen compiles
/// and looks consistent even if your exact shared-widget names differ
/// from what was referenced in the build prompt.

/// Renders an amount with the rupee glyph as an [Icon] rather than a
/// literal "₹" string, which renders as tofu on this project's font.
class RupeeAmount extends StatelessWidget {
  const RupeeAmount({
    super.key,
    required this.amount,
    this.style,
    this.iconSize,
    this.iconColor,
    this.compact = false,
  });

  final num amount;
  final TextStyle? style;
  final double? iconSize;
  final Color? iconColor;

  /// e.g. 1.2K / 3.4L instead of the full digit run — useful in tight
  /// hero stat rows.
  final bool compact;

  static String _grouped(num value) {
    final isNegative = value < 0;
    final whole = value.abs().truncate().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final posFromEnd = whole.length - i;
      buffer.write(whole[i]);
      final shouldComma = posFromEnd > 1 &&
          (posFromEnd == 4 || (posFromEnd > 4 && (posFromEnd - 4) % 2 == 0));
      if (shouldComma) buffer.write(',');
    }
    return (isNegative ? '-' : '') + buffer.toString();
  }

  static String _compactValue(num value) {
    final abs = value.abs();
    if (abs >= 10000000) return '${(value / 10000000).toStringAsFixed(1)}Cr';
    if (abs >= 100000) return '${(value / 100000).toStringAsFixed(1)}L';
    if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.truncate().toString();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = style;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.currency_rupee_rounded,
          size: iconSize ?? (resolvedStyle?.fontSize ?? 14),
          color: iconColor ?? resolvedStyle?.color,
        ),
        Text(
          compact ? _compactValue(amount) : _grouped(amount),
          style: resolvedStyle,
        ),
      ],
    );
  }
}

enum StatusTone { positive, warning, critical, neutral }

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = switch (tone) {
      StatusTone.positive => colors.success,
      StatusTone.warning => colors.warning,
      StatusTone.critical => colors.danger,
      StatusTone.neutral => colors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style:
            AppTypography.caption(color).copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Minimal shimmer-free loading placeholder. Swap for your real
/// `SkeletonLoader` if the API differs from `height`/`width`/`radius`.
class EmSkeletonBox extends StatefulWidget {
  const EmSkeletonBox({
    super.key,
    this.height = 16,
    this.width = double.infinity,
    this.radius = 8,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<EmSkeletonBox> createState() => _EmSkeletonBoxState();
}

class _EmSkeletonBoxState extends State<EmSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color:
                colors.border.withValues(alpha: 0.2 + _controller.value * 0.15),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Minimal empty state. Swap for your real `EmptyState` widget if it
/// takes a different set of parameters.
class EmEmptyState extends StatelessWidget {
  const EmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(icon,
              size: 40, color: colors.textSecondary.withValues(alpha: 0.6)),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: AppTypography.bodyLarge(colors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body(colors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Consistent gradient hero container used by several destination
/// screens (Profile & Account, Team Reports, Budget & Forecast, AI
/// Activity & Usage) — same [primary, secondary] gradient language as
/// the existing More-screen profile hero, just parameterized.
class EmGradientHero extends StatelessWidget {
  const EmGradientHero({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.secondary],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}

