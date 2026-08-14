// --- Replace the existing _RejectResult + _RejectReasonSheet classes in
// --- ceo_home_screen.dart with everything below.

import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'scale_on_tap.dart';

class _RejectResult {
  const _RejectResult(this.reason, this.note);
  final String reason;
  final String? note;
}

class _RejectReasonOption {
  const _RejectReasonOption(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _rejectReasonOptions = [
  _RejectReasonOption(
      Icons.account_balance_wallet_rounded, 'Over department budget'),
  _RejectReasonOption(Icons.copy_all_rounded, 'Duplicate or overlapping tool'),
  _RejectReasonOption(Icons.flag_rounded, 'Not aligned with strategy'),
  _RejectReasonOption(Icons.gpp_maybe_rounded, 'Vendor / security concern'),
  _RejectReasonOption(Icons.more_horiz_rounded, 'Other'),
];

class _RejectReasonSheet extends StatefulWidget {
  const _RejectReasonSheet({required this.toolName});
  final String toolName;

  @override
  State<_RejectReasonSheet> createState() => _RejectReasonSheetState();
}

class _RejectReasonSheetState extends State<_RejectReasonSheet> {
  String? _selectedReason;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final accent = colors.danger;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * 24),
              child: child,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),

                // ---- Gradient icon badge + title -----------------------
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            accent,
                            accent.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reject request',
                              style: AppTypography.h3(colors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(widget.toolName,
                              style:
                                  AppTypography.caption(colors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                Text('Why are you rejecting this?',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),

                // ---- Animated icon reason cards -------------------------
                ...List.generate(_rejectReasonOptions.length, (i) {
                  final option = _rejectReasonOptions[i];
                  final selected = _selectedReason == option.label;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ReasonOptionCard(
                      icon: option.icon,
                      label: option.label,
                      selected: selected,
                      accent: accent,
                      delayMs: i * 40,
                      onTap: () =>
                          setState(() => _selectedReason = option.label),
                    ),
                  );
                }),

                const SizedBox(height: AppSpacing.md),
                Text('Add more detail (optional)',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: AppTypography.body(colors.textPrimary),
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Switch to the shared Claude Team plan instead',
                      hintStyle: AppTypography.caption(colors.textSecondary),
                      filled: false,
                      contentPadding: const EdgeInsets.all(AppSpacing.md),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: accent, width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: colors.border),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel',
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      flex: 2,
                      child: ScaleOnTap(
                        onTap: _selectedReason == null
                            ? () {}
                            : () => Navigator.of(context).pop(
                                  _RejectResult(
                                    _selectedReason!,
                                    _noteController.text.trim().isEmpty
                                        ? null
                                        : _noteController.text.trim(),
                                  ),
                                ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(
                              colors: _selectedReason == null
                                  ? [
                                      colors.border,
                                      colors.border,
                                    ]
                                  : [
                                      accent,
                                      accent.withValues(alpha: 0.75),
                                    ],
                            ),
                            boxShadow: _selectedReason == null
                                ? null
                                : [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Text(
                            'Reject request',
                            style: TextStyle(
                              color: _selectedReason == null
                                  ? colors.textSecondary
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single selectable reason card — icon badge, label, and an animated
/// check-in-circle that scales/fades in when selected, with a soft
/// accent-colored glow around the whole card while active.
class _ReasonOptionCard extends StatelessWidget {
  const _ReasonOptionCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.delayMs = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (context, entrance, child) => Opacity(
        opacity: entrance,
        child: Transform.translate(
          offset: Offset((1 - entrance) * 16, 0),
          child: child,
        ),
      ),
      child: ScaleOnTap(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.08)
                : colors.surfaceElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : colors.border,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.18),
                      blurRadius: 14,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? accent.withValues(alpha: 0.16)
                      : colors.border.withValues(alpha: 0.4),
                ),
                child: Icon(icon,
                    size: 17, color: selected ? accent : colors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body(colors.textPrimary).copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.75)],
                    ),
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Public function to show the reject reason sheet and return the result
Future<String?> showRejectRequestSheet(
  BuildContext context, {
  required String requesterName,
}) async {
  final result = await showModalBottomSheet<_RejectResult>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _RejectReasonSheet(toolName: requesterName),
  );
  return result?.reason;
}
