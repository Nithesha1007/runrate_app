import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_approval_actions.dart';
import 'engineering_manager_approvals_cubit.dart';
import 'pending_requests_repository.dart';

/// Engineering Manager · Approval Details (team-tier).
/// Expects an `EngineeringManagerApprovalsCubit` to already be provided
/// above it in the tree — the list screen pushes this route with
/// `BlocProvider.value`.
class EngineeringManagerApprovalDetailsScreen extends StatelessWidget {
  const EngineeringManagerApprovalDetailsScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

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
        child: BlocConsumer<EngineeringManagerApprovalsCubit,
            EngineeringManagerApprovalsState>(
          listener: (context, state) {
            // Auto-pop once this request resolves (approved/rejected) so
            // the person lands back on the list where the updated pending
            // count and exit animation are visible.
            if (state is EngineeringManagerApprovalsLoaded) {
              final match = _findRequest(state.data, requestId);
              if (match != null && match.decision != RequestDecision.pending) {
                Future.delayed(const Duration(milliseconds: 180), () {
                  if (context.mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                });
              }
            }
          },
          builder: (context, state) {
            if (state is! EngineeringManagerApprovalsLoaded) {
              return const SizedBox.shrink();
            }

            final request = _findRequest(state.data, requestId);
            if (request == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              });
              return const SizedBox.shrink();
            }

            final busy = state.isProcessing;
            final isPending = request.decision == RequestDecision.pending;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TitleBlock(request: request),
                        const SizedBox(height: AppSpacing.lg),
                        _SectionCard(
                          title: 'Request overview',
                          child: _RequestInfoSection(request: request),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Justification',
                          child: Text(request.justification,
                              style: AppTypography.body(colors.textPrimary)),
                        ),
                        if (request.duplicateTeammateCount > 0) ...[
                          const SizedBox(height: AppSpacing.md),
                          _DuplicateToolBanner(request: request),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        _SectionCard(
                          title: 'Activity',
                          child: _ActivitySection(request: request),
                        ),
                        if (!isPending &&
                            request.decision == RequestDecision.rejected) ...[
                          const SizedBox(height: AppSpacing.md),
                          _RejectedBanner(
                              reason: request.rejectionReason ?? '—'),
                        ],
                      ],
                    ),
                  ),
                ),
                if (isPending) _DecisionBar(request: request, busy: busy),
              ],
            );
          },
        ),
      ),
    );
  }

  PendingRequestData? _findRequest(
      EngineeringManagerApprovalsData data, String id) {
    // NOTE: This is attempting to cast ApprovalRequest to PendingRequestData,
    // which will fail at runtime since ApprovalRequest lacks many fields
    // (decision, justification, etc.). This details screen currently uses
    // PendingRequestData but the cubit provides ApprovalRequest.
    // Consider either: (1) enriching ApprovalRequest or (2) converting
    // ApprovalRequest to PendingRequestData when navigating here.
    for (final r in data.pending) {
      if (r.id == id) return r as PendingRequestData?;
    }
    return null;
  }
}

// ---------------------------------------------------------------------------
// TITLE BLOCK
// ---------------------------------------------------------------------------

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.request});
  final PendingRequestData request;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pColor = priorityColor(context, request.priority);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      size: 12, color: colors.primary),
                  const SizedBox(width: 4),
                  Text('AI TOOL REQUEST',
                      style: AppTypography.caption(colors.primary)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(priorityIcon(request.priority), size: 11, color: pColor),
                  const SizedBox(width: 3),
                  Text(request.priority.label.toUpperCase(),
                      style: AppTypography.caption(pColor)
                          .copyWith(fontWeight: FontWeight.w700, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(request.requestedTool,
            style: AppTypography.h2(colors.textPrimary)),
        const SizedBox(height: 2),
        Text(
          request.employeeRole.isNotEmpty
              ? '${request.employeeName} · ${request.employeeRole}'
              : request.employeeName,
          style: AppTypography.body(colors.textSecondary),
        ),
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
  const _RequestInfoSection({required this.request});
  final PendingRequestData request;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        _KeyValueRow(
          label: 'Cost',
          value: CurrencyLabel(
            request.monthlyCost,
            suffix: '/mo',
            style: AppTypography.body(colors.textPrimary)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        _KeyValueRow(
            label: 'Requester',
            value: _plainValue(context, request.employeeName)),
        if (request.employeeRole.isNotEmpty)
          _KeyValueRow(
              label: 'Role', value: _plainValue(context, request.employeeRole)),
        _KeyValueRow(
            label: 'Requested',
            value: _plainValue(context, formatRelative(request.requestDate))),
        _KeyValueRow(
            label: 'Priority',
            value: _plainValue(context, request.priority.label)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DUPLICATE TOOL BANNER
// ---------------------------------------------------------------------------

class _DuplicateToolBanner extends StatelessWidget {
  const _DuplicateToolBanner({required this.request});
  final PendingRequestData request;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final count = request.duplicateTeammateCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.content_copy_rounded, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$count teammate${count == 1 ? '' : 's'} on your team already use ${request.requestedTool}.',
              style: AppTypography.caption(colors.textPrimary)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ACTIVITY
// ---------------------------------------------------------------------------

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.request});
  final PendingRequestData request;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final decided = request.decision != RequestDecision.pending;

    return Column(
      children: [
        _ActivityRow(
          isLast: !decided,
          label: 'Request submitted',
          at: request.requestDate,
        ),
        if (decided)
          _ActivityRow(
            isLast: true,
            label: request.decision == RequestDecision.approved
                ? 'Approved by you'
                : 'Rejected by you',
            at: request.decidedAt ?? request.requestDate,
            color: request.decision == RequestDecision.approved
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
    required this.at,
    this.color,
  });

  final bool isLast;
  final String label;
  final DateTime at;
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
                const SizedBox(width: 6),
                Text(formatRelative(at),
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// REJECTED BANNER
// ---------------------------------------------------------------------------

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({required this.reason});
  final String reason;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.close_rounded, size: 18, color: colors.danger),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rejection reason',
                    style: AppTypography.body(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(reason,
                    style: AppTypography.caption(colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DECISION BAR
// FIX: Reject now pushes the full-screen reject flow via
// openRejectRequestScreen (same as the list screen) instead of the old
// bottom sheet, so both entry points behave identically.
// ---------------------------------------------------------------------------

class _DecisionBar extends StatelessWidget {
  const _DecisionBar({required this.request, required this.busy});
  final PendingRequestData request;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
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
              onPressed:
                  busy ? null : () => openRejectRequestScreen(context, request),
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
              onPressed: busy
                  ? null
                  : () => context
                      .read<EngineeringManagerApprovalsCubit>()
                      .approve(request.id),
              icon: busy
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
