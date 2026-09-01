import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';

import 'employee_approvals_cubit.dart';

// Status priority colors
const _urgentBg = Color(0xFFFEE2E2);
const _urgentFg = Color(0xFFB91C1C);
const _normalBg = Color(0xFFE1E9FB);
const _normalFg = Color(0xFF2563EB);

// Approval status colors
const _approvedBg = Color(0xFFDCFCE7);
const _approvedFg = Color(0xFF15803D);
const _needsInfoBg = Color(0xFFE0E3FC);
const _needsInfoFg = Color(0xFF4338CA);
const _rejectedBg = Color(0xFFFEE2E2);
const _rejectedFg = Color(0xFFB91C1C);

// Gradients
const _gradientStart = Color(0xFF6C5CE7);
const _gradientEnd = Color(0xFF4C6EF5);

// AI Note color
const _aiNotePurple = Color(0xFF7C3AED);

TextStyle appFontStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color? color,
  double? height,
}) {
  return TextStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

String _formatRupees(double amount) {
  return '\u20b9${NumberFormat('#,##0').format(amount)}';
}

String _formatCompact(double amount) {
  if (amount >= 100000) {
    final lakhs = amount / 100000;
    return '${lakhs % 1 == 0 ? lakhs.toStringAsFixed(0) : lakhs.toStringAsFixed(1)}L';
  }
  if (amount >= 1000) {
    final thousands = amount / 1000;
    return '${thousands % 1 == 0 ? thousands.toStringAsFixed(0) : thousands.toStringAsFixed(1)}K';
  }
  return amount.toStringAsFixed(0);
}

/// Top-level tab: requests still awaiting a decision, or ones already
/// decided (approved / needs info / rejected).
enum _TopTab { pending, history }

/// Sub-filter within the Pending tab.
enum _UrgencyFilter { all, urgent, normal }

/// Sub-filter within the History tab.
enum _HistoryFilter { all, approved, flagged }

/// Employee · Approvals ("My Requests")
///
/// Shows the status of requests *this employee submitted*, plus a form
/// to submit a new one. The employee never approves, rejects, or asks
/// for info here — that's the reviewer's job, done elsewhere. The only
/// actions available are submitting a new request and withdrawing one
/// that's still pending.
class EmployeeApprovalsScreen extends StatelessWidget {
  const EmployeeApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EmployeeApprovalsCubit(),
      child: const _EmployeeApprovalsView(),
    );
  }
}

class _EmployeeApprovalsView extends StatefulWidget {
  const _EmployeeApprovalsView();

  @override
  State<_EmployeeApprovalsView> createState() => _EmployeeApprovalsViewState();
}

class _EmployeeApprovalsViewState extends State<_EmployeeApprovalsView> {
  _TopTab _topTab = _TopTab.pending;
  _UrgencyFilter _urgencyFilter = _UrgencyFilter.all;
  _HistoryFilter _historyFilter = _HistoryFilter.all;

  bool _isFlagged(ApprovalRequest r) =>
      r.decision == ApprovalDecision.needsInfo || r.decision == ApprovalDecision.rejected;

  List<ApprovalRequest> _visiblePending(List<ApprovalRequest> pending) {
    switch (_urgencyFilter) {
      case _UrgencyFilter.all:
        return pending;
      case _UrgencyFilter.urgent:
        return pending.where((r) => r.urgency == ApprovalUrgency.urgent).toList();
      case _UrgencyFilter.normal:
        return pending.where((r) => r.urgency == ApprovalUrgency.normal).toList();
    }
  }

  List<ApprovalRequest> _visibleHistory(List<ApprovalRequest> history) {
    switch (_historyFilter) {
      case _HistoryFilter.all:
        return history;
      case _HistoryFilter.approved:
        return history.where((r) => r.decision == ApprovalDecision.approved).toList();
      case _HistoryFilter.flagged:
        return history.where(_isFlagged).toList();
    }
  }

  Future<void> _openNewRequestSheet(BuildContext context) async {
    final cubit = context.read<EmployeeApprovalsCubit>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewRequestSheet(
        onSubmit: (itemName, type, amount, approverName, urgency) {
          cubit.submitRequest(
            itemName: itemName,
            type: type,
            amount: amount,
            approverName: approverName,
            urgency: urgency,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewRequestSheet(context),
        backgroundColor: colors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New request',
          style: appFontStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<EmployeeApprovalsCubit, EmployeeApprovalsState>(
          listener: (context, state) {
            if (state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.requests.isEmpty) {
              return Center(
                child: CircularProgressIndicator(color: colors.primary),
              );
            }
            if (state.hasError && state.requests.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            final pending = state.pending;
            final history = state.history;
            final urgentCount =
                pending.where((r) => r.urgency == ApprovalUrgency.urgent).length;
            final normalCount = pending.length - urgentCount;
            final approvedCount =
                history.where((r) => r.decision == ApprovalDecision.approved).length;
            final flaggedCount = history.where(_isFlagged).length;

            final visible = _topTab == _TopTab.pending
                ? _visiblePending(pending)
                : _visibleHistory(history);

            return Column(
              children: [
               const  Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.md,
                  ),
                  child: _ApprovalsHeader(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _HeroSummaryCard(
                    pendingCount: pending.length,
                    urgentCount: urgentCount,
                    pendingValue: state.pendingValue,
                    approvedThisMonth: state.approvedThisMonthCount,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _TopTabsRow(
                    selected: _topTab,
                    onSelected: (t) => setState(() => _topTab = t),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: _topTab == _TopTab.pending
                      ? _UrgencyFilterRow(
                          selected: _urgencyFilter,
                          allCount: pending.length,
                          urgentCount: urgentCount,
                          normalCount: normalCount,
                          onSelected: (f) => setState(() => _urgencyFilter = f),
                        )
                      : _HistoryFilterRow(
                          selected: _historyFilter,
                          allCount: history.length,
                          approvedCount: approvedCount,
                          flaggedCount: flaggedCount,
                          onSelected: (f) => setState(() => _historyFilter = f),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: visible.isEmpty
                      ? EmptyState(
                          title: 'Nothing here',
                          message: _topTab == _TopTab.pending
                              ? 'No pending requests match this filter.'
                              : 'No past requests match this filter.',
                          icon: Icons.task_alt_outlined,
                        )
                      : RefreshIndicator(
                          color: colors.primary,
                          onRefresh: () =>
                              context.read<EmployeeApprovalsCubit>().loadRequests(),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              0,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final request = visible[index];
                              return _ApprovalCard(
                                request: request,
                                isProcessing:
                                    state.processingIds.contains(request.id),
                              );
                            },
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ApprovalsHeader extends StatelessWidget {
  const _ApprovalsHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).maybePop(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(Icons.arrow_back, color: colors.textPrimary),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Requests',
              style: appFontStyle(fontSize: 26, fontWeight: FontWeight.w800, color: colors.textPrimary),
            ),
            Text(
              'Track requests you\'ve submitted',
              style: appFontStyle(fontSize: 13, color: colors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({
    required this.pendingCount,
    required this.urgentCount,
    required this.pendingValue,
    required this.approvedThisMonth,
  });

  final int pendingCount;
  final int urgentCount;
  final double pendingValue;
  final int approvedThisMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gradientStart, _gradientEnd],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Awaiting a decision',
                  style: appFontStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              if (urgentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFFFF6B6B)),
                      const SizedBox(width: 6),
                      Text(
                        '$urgentCount urgent',
                        style: appFontStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$pendingCount',
                    style: appFontStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'pending requests',
                    style: appFontStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _HeroStatChip(text: 'Value: ${_formatCompact(pendingValue)}'),
                  const SizedBox(height: 8),
                  _HeroStatChip(text: 'Approved this month: $approvedThisMonth'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: appFontStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }
}

class _TopTabsRow extends StatelessWidget {
  const _TopTabsRow({required this.selected, required this.onSelected});

  final _TopTab selected;
  final ValueChanged<_TopTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelected(_TopTab.pending),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: BoxDecoration(
              color: selected == _TopTab.pending ? colors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Pending',
              style: appFontStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected == _TopTab.pending ? Colors.white : colors.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => onSelected(_TopTab.history),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              'History',
              style: appFontStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected == _TopTab.history ? colors.textPrimary : colors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DotFilterPill extends StatelessWidget {
  const _DotFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.dotColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? colors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Icon(Icons.circle, size: 8, color: dotColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: appFontStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? colors.primary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UrgencyFilterRow extends StatelessWidget {
  const _UrgencyFilterRow({
    required this.selected,
    required this.allCount,
    required this.urgentCount,
    required this.normalCount,
    required this.onSelected,
  });

  final _UrgencyFilter selected;
  final int allCount;
  final int urgentCount;
  final int normalCount;
  final ValueChanged<_UrgencyFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DotFilterPill(
            label: 'All ($allCount)',
            selected: selected == _UrgencyFilter.all,
            onTap: () => onSelected(_UrgencyFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DotFilterPill(
            label: 'Urgent ($urgentCount)',
            selected: selected == _UrgencyFilter.urgent,
            dotColor: _urgentFg,
            onTap: () => onSelected(_UrgencyFilter.urgent),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DotFilterPill(
            label: 'Normal ($normalCount)',
            selected: selected == _UrgencyFilter.normal,
            dotColor: _normalFg,
            onTap: () => onSelected(_UrgencyFilter.normal),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterRow extends StatelessWidget {
  const _HistoryFilterRow({
    required this.selected,
    required this.allCount,
    required this.approvedCount,
    required this.flaggedCount,
    required this.onSelected,
  });

  final _HistoryFilter selected;
  final int allCount;
  final int approvedCount;
  final int flaggedCount;
  final ValueChanged<_HistoryFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _DotFilterPill(
            label: 'All ($allCount)',
            selected: selected == _HistoryFilter.all,
            onTap: () => onSelected(_HistoryFilter.all),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DotFilterPill(
            label: 'Approved ($approvedCount)',
            selected: selected == _HistoryFilter.approved,
            dotColor: _approvedFg,
            onTap: () => onSelected(_HistoryFilter.approved),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DotFilterPill(
            label: 'Flagged ($flaggedCount)',
            selected: selected == _HistoryFilter.flagged,
            dotColor: _needsInfoFg,
            onTap: () => onSelected(_HistoryFilter.flagged),
          ),
        ],
      ),
    );
  }
}

IconData _iconForType(ApprovalRequestType type) {
  switch (type) {
    case ApprovalRequestType.subscription:
      return Icons.code_rounded;
    case ApprovalRequestType.infrastructure:
      return Icons.dns_outlined;
    case ApprovalRequestType.creativeTool:
      return Icons.edit_outlined;
    case ApprovalRequestType.travel:
      return Icons.flight_outlined;
    case ApprovalRequestType.other:
      return Icons.shopping_bag_outlined;
  }
}

class _DecisionStyle {
  const _DecisionStyle(this.label, this.background, this.foreground);
  final String label;
  final Color background;
  final Color foreground;
}

_DecisionStyle _styleForDecision(ApprovalDecision decision) {
  switch (decision) {
    case ApprovalDecision.pending:
      return const _DecisionStyle('Pending', _normalBg, _normalFg);
    case ApprovalDecision.approved:
      return const _DecisionStyle('Approved', _approvedBg, _approvedFg);
    case ApprovalDecision.needsInfo:
      return const _DecisionStyle('Needs Info', _needsInfoBg, _needsInfoFg);
    case ApprovalDecision.rejected:
      return const _DecisionStyle('Rejected', _rejectedBg, _rejectedFg);
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.request, required this.isProcessing});

  final ApprovalRequest request;
  final bool isProcessing;

  Future<void> _confirmWithdraw(BuildContext context) async {
    final cubit = context.read<EmployeeApprovalsCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Withdraw request?'),
          content: Text(
            'This will cancel your request for "${request.itemName}". You can resubmit it later if needed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep request'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Withdraw'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await cubit.withdraw(request.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isPending = request.decision == ApprovalDecision.pending;
    final isNeedsInfo = request.decision == ApprovalDecision.needsInfo;
    final showNote = (isPending || isNeedsInfo) && (request.note?.isNotEmpty ?? false);
    final isUrgent = request.urgency == ApprovalUrgency.urgent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isUrgent ? _urgentBg : _normalBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          size: 7,
                          color: isUrgent ? _urgentFg : _normalFg),
                      const SizedBox(width: 6),
                      Text(
                        isUrgent ? 'URGENT' : 'NORMAL',
                        style: appFontStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isUrgent ? _urgentFg : _normalFg,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Builder(builder: (context) {
                  final style = _styleForDecision(request.decision);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: style.background,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      style.label.toUpperCase(),
                      style: appFontStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: style.foreground,
                      ),
                    ),
                  );
                }),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_iconForType(request.type), size: 14, color: colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      typeLabel(request.type),
                      style: appFontStyle(fontSize: 12, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            request.itemName,
            style: appFontStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline, size: 14, color: colors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isPending
                      ? 'Awaiting approval from ${request.approverName}'
                      : 'Reviewed by ${request.approverName}',
                  style: appFontStyle(fontSize: 12, color: colors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _formatRupees(request.amount),
            style: appFontStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          if (showNote) ...[
            const SizedBox(height: AppSpacing.sm),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isPending ? Icons.auto_awesome : Icons.info_outline,
                  size: 16,
                  color: isPending ? _aiNotePurple : colors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    request.note!,
                    style: appFontStyle(fontSize: 12, height: 1.4, color: colors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
          if (isPending) ...[
            const SizedBox(height: AppSpacing.md),
            if (isProcessing)
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                ),
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _confirmWithdraw(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(
                    'Withdraw request',
                    style: appFontStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet form for submitting a brand-new request.
class _NewRequestSheet extends StatefulWidget {
  const _NewRequestSheet({required this.onSubmit});

  final void Function(
    String itemName,
    ApprovalRequestType type,
    double amount,
    String approverName,
    ApprovalUrgency urgency,
  ) onSubmit;

  @override
  State<_NewRequestSheet> createState() => _NewRequestSheetState();
}

class _NewRequestSheetState extends State<_NewRequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _amountController = TextEditingController();
  final _approverController = TextEditingController();
  ApprovalRequestType _type = ApprovalRequestType.subscription;
  ApprovalUrgency _urgency = ApprovalUrgency.normal;

  @override
  void dispose() {
    _itemController.dispose();
    _amountController.dispose();
    _approverController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSubmit(
      _itemController.text.trim(),
      _type,
      double.parse(_amountController.text.trim()),
      _approverController.text.trim(),
      _urgency,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('New request', style: appFontStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: AppSpacing.lg),
                TextFormField(
                  controller: _itemController,
                  decoration: const InputDecoration(labelText: 'What are you requesting?'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ApprovalRequestType>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ApprovalRequestType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(typeLabel(t))))
                      .toList(),
                  onChanged: (t) => setState(() => _type = t ?? _type),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Amount (\u20b9)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _approverController,
                  decoration: const InputDecoration(labelText: 'Who should review this?'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: AppSpacing.md),
                Text('Urgency', style: appFontStyle(fontSize: 13, color: colors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: _DotFilterPill(
                        label: 'Urgent',
                        selected: _urgency == ApprovalUrgency.urgent,
                        dotColor: _urgentFg,
                        onTap: () => setState(() => _urgency = ApprovalUrgency.urgent),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _DotFilterPill(
                        label: 'Normal',
                        selected: _urgency == ApprovalUrgency.normal,
                        dotColor: _normalFg,
                        onTap: () => setState(() => _urgency = ApprovalUrgency.normal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Submit request',
                      style: appFontStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}