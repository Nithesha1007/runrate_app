import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runrate/features/roles/ceo/shared/models/approval_model.dart';

import 'ceo_approvals_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// CEO · Request Info — full page for asking the requester for more
/// information before deciding. Shows the same "why this needs your
/// approval" context (amount, requester, category, rationale) plus a note
/// field, then pops with the typed message so the caller can hand it to
/// the cubit.
///
/// Pulled out of `ceo_approvals_screen.dart` (was a private
/// `_RequestInfoScreen`) so it can be reached both from the pending card's
/// "Request Info" link and from `CeoApprovalDetailsScreen`'s "View
/// details" page, without those two files needing to import each other.
class CeoRequestInfoScreen extends StatefulWidget {
  const CeoRequestInfoScreen(
      {super.key, required this.approval, required this.priority});

  final ApprovalModel approval;
  final ApprovalPriority priority;

  @override
  State<CeoRequestInfoScreen> createState() => _CeoRequestInfoScreenState();
}

class _CeoRequestInfoScreenState extends State<CeoRequestInfoScreen> {
  final _controller = TextEditingController();
  static const _suggestions = [
    'Need a vendor quote breakdown',
    'Please share the ROI justification',
    'Confirm if this was budgeted',
    'Need sign-off from department head',
  ];

  static final _amountFormat = NumberFormat('#,##0');
  static String _formatAmount(double value) => _amountFormat.format(value);

  bool get _isUrgent =>
      widget.priority == ApprovalPriority.high ||
      widget.priority == ApprovalPriority.critical;

  List<String> _reasons(ApprovalModel approval) {
    final urgent = _isUrgent;
    final reasons = <String>[];
    if (urgent) {
      reasons.add(
          'Flagged as urgent priority — needs a faster turnaround than routine requests.');
    }
    if (approval.amount >= 50000) {
      reasons.add(
          'Amount of ₹${_formatAmount(approval.amount)} is above standard department sign-off limits.');
    } else {
      reasons.add(
          'Amount of ₹${_formatAmount(approval.amount)} falls under strategic spend that routes to the CEO.');
    }
    if (approval.category.isNotEmpty) {
      reasons.add(
          'Category "${approval.category}" is on the list of spend types that require executive review.');
    }
    reasons.add(
        '${approval.requesterName} does not hold sign-off authority for this amount, so it escalates to you.');
    return reasons;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applySuggestion(String text) {
    setState(() {
      _controller.text = text;
      _controller.selection =
          TextSelection.collapsed(offset: _controller.text.length);
    });
  }

  void _submit() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    Navigator.of(context).pop(message);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final approval = widget.approval;
    final priorityColor = _isUrgent ? colors.danger : colors.info;
    final reasons = _reasons(approval);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title:
            Text('Request info', style: AppTypography.h3(colors.textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.xl),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: priorityColor, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(_isUrgent ? 'URGENT' : 'NORMAL',
                                style: AppTypography.caption(priorityColor)
                                    .copyWith(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (approval.category.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(approval.category,
                              style:
                                  AppTypography.caption(colors.textSecondary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(approval.title,
                      style: AppTypography.h2(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 16, color: colors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text('Requested by ${approval.requesterName}',
                            style: AppTypography.body(colors.textSecondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Icon(Icons.currency_rupee_rounded,
                            color: Colors.white, size: 26),
                        Text(_formatAmount(approval.amount),
                            style: AppTypography.display(Colors.white)),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text('requested',
                              style: AppTypography.caption(
                                  Colors.white.withValues(alpha: 0.85))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text('Why this needs your approval',
                          style: AppTypography.h3(colors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < reasons.length; i++) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: colors.primary,
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(reasons[i],
                                    style: AppTypography.body(
                                        colors.textSecondary)),
                              ),
                            ],
                          ),
                          if (i != reasons.length - 1)
                            const SizedBox(height: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('What do you need from ${approval.requesterName}?',
                      style: AppTypography.h3(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _suggestions
                        .map((s) => GestureDetector(
                              onTap: () => _applySuggestion(s),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: colors.surfaceElevated,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: colors.border),
                                ),
                                child: Text(s,
                                    style: AppTypography.caption(
                                            colors.textPrimary)
                                        .copyWith(fontWeight: FontWeight.w600)),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: colors.border),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: TextField(
                      controller: _controller,
                      maxLines: 5,
                      minLines: 4,
                      style: AppTypography.body(colors.textPrimary),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText:
                            'Type what you need before deciding on this request…',
                        hintStyle: AppTypography.body(colors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.background,
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: SafeArea(
                top: false,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final enabled = value.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: enabled ? _submit : null,
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: enabled
                              ? LinearGradient(
                                  colors: [colors.primary, colors.secondary])
                              : null,
                          color: enabled ? null : colors.border,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded,
                                size: 18,
                                color: enabled
                                    ? Colors.white
                                    : colors.textSecondary),
                            const SizedBox(width: 8),
                            Text('Send Request',
                                style: AppTypography.body(enabled
                                        ? Colors.white
                                        : colors.textSecondary)
                                    .copyWith(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}