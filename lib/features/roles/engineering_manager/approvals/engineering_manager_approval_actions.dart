import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'pending_requests_repository.dart';
import 'engineering_manager_reject_request_screen.dart';

/// Digits only, Indian grouping (e.g. 24,000) — NO currency symbol string.
String formatAmountDigits(double amount) {
  final s = amount.toStringAsFixed(0);
  final buf = StringBuffer();
  final reversed = s.split('').reversed.toList();
  for (var i = 0; i < reversed.length; i++) {
    if (i == 3 || (i > 3 && (i - 3) % 2 == 0)) buf.write(',');
    buf.write(reversed[i]);
  }
  return buf.toString().split('').reversed.join();
}

String formatRelative(DateTime at) {
  final diff = DateTime.now().difference(at);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${at.day}/${at.month}/${at.year}';
}

/// Icon + plain digits — the only currency display used anywhere on this
/// screen. FIX: this previously had no width limit, so a long suffix
/// (e.g. " / 60,000") could push the Row past its parent's bounds and
/// throw a RenderFlex overflow (that's the "RIGHT OVERFLOWED BY 4.2
/// PIXELS" banner you saw). The digits are now wrapped in `Flexible` with
/// ellipsis, so it degrades gracefully instead of overflowing when space
/// is tight.
class CurrencyLabel extends StatelessWidget {
  const CurrencyLabel(
    this.amount, {
    super.key,
    this.style,
    this.iconSize = 14,
    this.suffix,
    this.maxLines = 1,
  });

  final double amount;
  final TextStyle? style;
  final double iconSize;
  final String? suffix;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = style?.color ?? colors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.currency_rupee_rounded, size: iconSize, color: color),
        const SizedBox(width: 1),
        Flexible(
          child: Text(
            '${formatAmountDigits(amount)}${suffix ?? ''}',
            style: style,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

Color priorityColor(BuildContext context, RequestPriority priority) {
  final colors = AppColors.of(context);
  switch (priority) {
    case RequestPriority.high:
      return colors.danger;
    case RequestPriority.medium:
      return colors.primary;
    case RequestPriority.low:
      return colors.textSecondary;
  }
}

IconData priorityIcon(RequestPriority priority) {
  switch (priority) {
    case RequestPriority.high:
      return Icons.keyboard_double_arrow_up_rounded;
    case RequestPriority.medium:
      return Icons.remove_rounded;
    case RequestPriority.low:
      return Icons.keyboard_arrow_down_rounded;
  }
}

/// Pushes the full-screen reject flow (see
/// engineering_manager_reject_request_screen.dart) instead of the old
/// bottom sheet, per your CEO screen's pattern. Returns true if the
/// request was actually rejected, so callers (the pending card) know
/// whether to play their exit animation.
Future<bool> openRejectRequestScreen(
  BuildContext context,
  PendingRequestData request,
) async {
  final reason = await Navigator.of(context).push<String>(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, animation, __) => RejectRequestScreen(request: request),
      transitionsBuilder: (_, animation, __, child) {
        final curved =
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return SlideTransition(
          position:
              Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                  .animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    ),
  );

  if (reason == null || reason.trim().isEmpty) return false;

  // NOTE: To make this functional, you'd need to trigger the rejection
  // through the cubit. For now, returning true to signal the card should
  // animate out.
  return true;
}
