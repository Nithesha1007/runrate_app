import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runrate/features/roles/ceo/approvals/request_info_screen.dart';
import 'package:runrate/features/roles/ceo/shared/models/approval_model.dart';

import 'ceo_approvals_cubit.dart';
import 'ceo_approvals_state.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/reject_request_sheet.dart';
import '../../../../shared/widgets/toast.dart';

/// CEO · Approval Details (full screen) — same "view details" pattern as
/// EngineeringManagerApprovalDetailsScreen. Expects a `CeoApprovalsCubit`
/// to already be provided above it in the tree: the approvals list should
/// push this route with `BlocProvider.value(value: cubit, child: ...)` so
/// Approve/Reject here update the exact state the list is watching.
///
/// Auto-pops once the request leaves the pending list (approved/rejected),
/// same as the manager version, so the person lands back on the list with
/// the updated count/exit animation visible.
class CeoApprovalDetailsScreen extends StatelessWidget {
  const CeoApprovalDetailsScreen({super.key, required this.approvalId});

  final String approvalId;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('Request details',
            style: AppTypography.h3(colors.textPrimary)),
      ),
      body: SafeArea(
        child: BlocConsumer<CeoApprovalsCubit, CeoApprovalsState>(
          listener: (context, state) {
            final stillPending = state.pending.any((a) => a.id == approvalId);
            final stillExists = stillPending ||
                state.history.any((a) => a.id == approvalId);
            if (stillExists && !stillPending) {
              Future.delayed(const Duration(milliseconds: 180), () {
                if (context.mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            }
          },
          builder: (context, state) {
            final approval = _find(state, approvalId);
            if (approval == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }

            final priority = state.priorityOf(approval);
            final isPending = state.pending.any((a) => a.id == approvalId);
            final decidedAt = state.decisionTimes[approval.id];

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TitleBlock(approval: approval, priority: priority),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionCard(
                          title: 'Request overview',
                          child: _RequestInfoSection(approval: approval),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Why this needs your approval',
                          child: _ReasonsList(
                            reasons: _approvalReasons(approval, priority),
                          ),
                        ),
                        if (isPending) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () async {
                                final cubit = context.read<CeoApprovalsCubit>();
                                final message = await Navigator.of(context)
                                    .push<String>(MaterialPageRoute(
                                  builder: (_) => CeoRequestInfoScreen(
                                    approval: approval,
                                    priority: priority,
                                  ),
                                ));
                                if (message != null && context.mounted) {
                                  cubit.requestInfo(approval.id, message);
                                  showAppToast(context,
                                      'Requested more info from ${approval.requesterName}');
                                }
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.help_outline_rounded,
                                        size: 16, color: colors.primary),
                                    const SizedBox(width: 4),
                                    Text('Request Info',
                                        style: AppTypography.caption(
                                                colors.primary)
                                            .copyWith(
                                                fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Activity',
                          child: _ActivitySection(
                            isPending: isPending,
                            status: approval.status,
                            decidedAt: decidedAt,
                          ),
                        ),
                        if (!isPending &&
                            approval.status == ApprovalStatus.declined) ...[
                          const SizedBox(height: AppSpacing.md),
                          const _RejectedBanner(),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isPending) _DecisionBar(approval: approval),
              ],
            );
          },
        ),
      ),
    );
  }

  ApprovalModel? _find(CeoApprovalsState state, String id) {
    for (final a in state.pending) {
      if (a.id == id) return a;
    }
    for (final a in state.history) {
      if (a.id == id) return a;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// FORMATTING / REASONING HELPERS (kept local to this file, mirroring the
// helpers already used on the CEO approvals list screen).
// ---------------------------------------------------------------------------

final _amountFormat = NumberFormat('#,##0');
String _formatAmount(double value) => _amountFormat.format(value);

bool _isUrgent(ApprovalPriority p) =>
    p == ApprovalPriority.high || p == ApprovalPriority.critical;

List<String> _approvalReasons(ApprovalModel approval, ApprovalPriority priority) {
  final urgent = _isUrgent(priority);
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

// ---------------------------------------------------------------------------
// TITLE BLOCK
// ---------------------------------------------------------------------------

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.approval, required this.priority});
  final ApprovalModel approval;
  final ApprovalPriority priority;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final urgent = _isUrgent(priority);
    final pColor = urgent ? colors.danger : colors.info;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: pColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                  Text(urgent ? 'URGENT' : 'NORMAL',
                      style: AppTypography.caption(pColor)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                ],
              ),
            ),
            if (approval.category.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                child: Text(approval.category,
                    style: AppTypography.caption(colors.textSecondary)),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(approval.title, style: AppTypography.h2(colors.textPrimary)),
        const SizedBox(height: 2),
        Text('Requested by ${approval.requesterName}',
            style: AppTypography.body(colors.textSecondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// SECTION CARD SHELL
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: AppTypography.caption(colors.textSecondary)
                .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4),
          ),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child:
                Text(label, style: AppTypography.caption(colors.textSecondary)),
          ),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

Widget _plainValue(BuildContext context, String text) {
  final colors = AppColors.of(context);
  return Text(
    text,
    style: AppTypography.body(colors.textPrimary)
        .copyWith(fontWeight: FontWeight.w600),
    textAlign: TextAlign.right,
    overflow: TextOverflow.ellipsis,
  );
}

// ---------------------------------------------------------------------------
// REQUEST OVERVIEW
// ---------------------------------------------------------------------------

class _RequestInfoSection extends StatelessWidget {
  const _RequestInfoSection({required this.approval});
  final ApprovalModel approval;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        _KeyValueRow(
          label: 'Amount',
          value: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.currency_rupee_rounded,
                  size: 14, color: colors.textPrimary),
              Text(
                _formatAmount(approval.amount),
                style: AppTypography.body(colors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        _KeyValueRow(
            label: 'Requester',
            value: _plainValue(context, approval.requesterName)),
        if (approval.category.isNotEmpty)
          _KeyValueRow(
              label: 'Category', value: _plainValue(context, approval.category)),
      ],
    );
  }
}

class _ReasonsList extends StatelessWidget {
  const _ReasonsList({required this.reasons});
  final List<String> reasons;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < reasons.length; i++)
          Padding(
            padding: EdgeInsets.only(
                bottom: i == reasons.length - 1 ? 0 : AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration:
                      BoxDecoration(color: colors.primary, shape: BoxShape.circle),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(reasons[i],
                      style: AppTypography.body(colors.textSecondary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// ACTIVITY
// ---------------------------------------------------------------------------

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.isPending,
    required this.status,
    required this.decidedAt,
  });

  final bool isPending;
  final ApprovalStatus status;
  final DateTime? decidedAt;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        _ActivityRow(isLast: isPending, label: 'Request submitted'),
        if (!isPending)
          _ActivityRow(
            isLast: true,
            label: status == ApprovalStatus.approved
                ? 'Approved by you'
                : 'Rejected by you',
            at: decidedAt,
            color: status == ApprovalStatus.approved
                ? colors.success
                : colors.danger,
          ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.isLast,
    required this.label,
    this.at,
    this.color,
  });

  final bool isLast;
  final String label;
  final DateTime? at;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dotColor = color ?? colors.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            if (!isLast) Container(width: 2, height: 24, color: colors.border),
          ],
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Text(label,
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                if (at != null) ...[
                  const SizedBox(width: 6),
                  Text(_formatDate(at!),
                      style: AppTypography.caption(colors.textSecondary)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}

// ---------------------------------------------------------------------------
// REJECTED BANNER
// ---------------------------------------------------------------------------

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.close_rounded, size: 18, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('This request was rejected.',
                style: AppTypography.body(colors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DECISION BAR
// ---------------------------------------------------------------------------

class _DecisionBar extends StatefulWidget {
  const _DecisionBar({required this.approval});
  final ApprovalModel approval;

  @override
  State<_DecisionBar> createState() => _DecisionBarState();
}

class _DecisionBarState extends State<_DecisionBar> {
  // Local-only guard so a double tap can't fire approve/reject twice while
  // the cubit is updating and this screen is about to auto-pop. The CEO
  // cubit doesn't expose a per-item processing flag (unlike the manager
  // cubit), so this mirrors the list screen's existing button behavior
  // rather than inventing new cubit state.
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final approval = widget.approval;
    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.sm, AppSpacing.xl,
          AppSpacing.sm + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _submitting
                  ? null
                  : () async {
                      final message = await showRejectRequestSheet(context,
                          requesterName: approval.requesterName);
                      if (message != null && context.mounted) {
                        setState(() => _submitting = true);
                        context
                            .read<CeoApprovalsCubit>()
                            .reject(approval.id, message);
                        showAppToast(context,
                            'Rejected and notified ${approval.requesterName}');
                      }
                    },
              icon: Icon(Icons.close_rounded, size: 16, color: colors.danger),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.danger.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _submitting
                  ? null
                  : () {
                      setState(() => _submitting = true);
                      context.read<CeoApprovalsCubit>().approve(approval.id);
                      showAppToast(context, 'Approved "${approval.title}"');
                    },
              icon: _submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}