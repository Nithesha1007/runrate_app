import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runrate/features/roles/cfo/approvals/cfo_approval_detail/cfo_approval_detail_screen.dart';
import 'cfo_approval_state.dart';
import 'cfo_approvals_cubit.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kPrimaryDark = Color(0xFF4C6FEF);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 18.0;
const _kUrgent = Color(0xFFE5484D);
const _kNormal = Color(0xFF4C6FEF);

class CfoApprovalsScreen extends StatelessWidget {
  const CfoApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoApprovalsCubit(),
      child: const _CfoApprovalsView(),
    );
  }
}

class _CfoApprovalsView extends StatelessWidget {
  const _CfoApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        child: BlocBuilder<CfoApprovalsCubit, CfoApprovalsState>(
          builder: (context, state) {
            if (state is CfoApprovalsLoading || state is CfoApprovalsInitial) {
              return const Center(child: CircularProgressIndicator(color: _kPrimary));
            }

            if (state is CfoApprovalsError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoApprovalsCubit>().load(),
              );
            }

            final loaded = state as CfoApprovalsLoaded;
            final results = loaded.filteredRequests;

            return RefreshIndicator(
              color: _kPrimary,
              onRefresh: () => context.read<CfoApprovalsCubit>().refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                children: [
                  const Text(
                    'Approvals',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 28),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Strategic sign-offs only',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                  const SizedBox(height: 18),
                  _SummaryCard(state: loaded),
                  const SizedBox(height: 18),
                  _TabToggle(
                    activeTab: loaded.activeTab,
                    onChanged: (tab) => context.read<CfoApprovalsCubit>().setTab(tab),
                  ),
                  const SizedBox(height: 16),
                  if (loaded.activeTab == ApprovalTab.pending) ...[
                    _FilterChips(
                      selected: loaded.filter,
                      allCount: loaded.pendingRequests.length,
                      urgentCount: loaded.urgentPendingCount,
                      normalCount: loaded.normalPendingCount,
                      onSelected: (filter) =>
                          context.read<CfoApprovalsCubit>().setFilter(filter),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: _EmptyApprovals(),
                    )
                  else
                    ...results.map(
                      (request) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _ApprovalCard(
                          request: request,
                          isHistory: loaded.activeTab == ApprovalTab.history,
                          busy: loaded.actionInFlightId == request.id,
                          onTap: () => _openDetail(context, request.id),
                          onApprove: () =>
                              context.read<CfoApprovalsCubit>().approve(request.id),
                          onReject: () => _showRejectSheet(context, request.id),
                          onRequestInfo: () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Info requested from ${request.requesterName}')),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, String requestId) {
    final cubit = context.read<CfoApprovalsCubit>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: CfoApprovalDetailScreen(requestId: requestId),
        ),
      ),
    );
  }

  Future<void> _showRejectSheet(BuildContext context, String requestId) async {
    final cubit = context.read<CfoApprovalsCubit>();
    final controller = TextEditingController();
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Reason for rejection',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a short note...',
                  filled: true,
                  fillColor: _kBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: _kUrgent),
                  onPressed: () => Navigator.of(sheetContext).pop(controller.text),
                  child: const Text('Confirm rejection'),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (reason != null) {
      cubit.reject(requestId, reason);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.state});

  final CfoApprovalsLoaded state;

  @override
  Widget build(BuildContext context) {
    final pendingCount = state.pendingRequests.length;
    final urgentCount = state.urgentPendingCount;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPrimary, _kPrimaryDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Awaiting your sign-off',
                  style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18,
                  ),
                ),
              ),
              if (urgentCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text('$urgentCount urgent',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '$pendingCount',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 44),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill('Value: ${_shortValue(state.totalPendingValue)}'),
                    _pill('Approved this month: ${state.approvedThisMonthCount}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('pending items',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  String _shortValue(double value) {
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.activeTab, required this.onChanged});

  final ApprovalTab activeTab;
  final ValueChanged<ApprovalTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton(context, 'Pending', ApprovalTab.pending)),
          Expanded(child: _tabButton(context, 'History', ApprovalTab.history)),
        ],
      ),
    );
  }

  Widget _tabButton(BuildContext context, String label, ApprovalTab tab) {
    final isSelected = tab == activeTab;
    return GestureDetector(
      onTap: () => onChanged(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.allCount,
    required this.urgentCount,
    required this.normalCount,
    required this.onSelected,
  });

  final ApprovalFilter selected;
  final int allCount;
  final int urgentCount;
  final int normalCount;
  final ValueChanged<ApprovalFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final entries = <(ApprovalFilter, String, Color?)>[
      (ApprovalFilter.all, 'All ($allCount)', null),
      (ApprovalFilter.urgent, 'Urgent ($urgentCount)', _kUrgent),
      (ApprovalFilter.normal, 'Normal ($normalCount)', _kNormal),
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label, dotColor) = entries[index];
          final isSelected = filter == selected;
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dotColor != null) ...[
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : dotColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(label),
              ],
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(filter),
            showCheckmark: false,
            selectedColor: _kPrimary,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(color: isSelected ? _kPrimary : Colors.grey.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.request,
    required this.isHistory,
    required this.busy,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
    required this.onRequestInfo,
  });

  final ApprovalRequest request;
  final bool isHistory;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestInfo;

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius: BorderRadius.circular(_kCardRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_kCardRadius),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isHistory)
                  _StatusBadge(status: request.status)
                else
                  _PriorityBadge(priority: request.priority),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    request.categoryLabel,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Requested by ${request.requesterName} (${request.requesterRole})',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formatInr(request.amount),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
            ),
            const SizedBox(height: 14),
            if (!isHistory) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: busy ? null : onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kUrgent,
                        backgroundColor: const Color(0xFFFDEBEC),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(colors: [_kPrimary, _kPrimaryDark]),
                      ),
                      child: FilledButton(
                        onPressed: busy ? null : onApprove,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: busy
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Approve', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRequestInfo,
                  icon: const Icon(Icons.help_outline, size: 16, color: _kPrimary),
                  label: const Text('Request Info',
                      style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
                ),
              ),
            ] else
              Text(
                formatShortDate(request.decidedDate ?? request.requestedDate),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final ApprovalPriority priority;

  @override
  Widget build(BuildContext context) {
    final isUrgent = priority == ApprovalPriority.urgent;
    final color = isUrgent ? _kUrgent : _kNormal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(priority.label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ApprovalStatus status;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;
    late final IconData icon;
    late final String label;

    switch (status) {
      case ApprovalStatus.pending:
        bg = const Color(0xFFFFF4DE);
        fg = const Color(0xFFF5A623);
        icon = Icons.radio_button_unchecked;
        label = 'Pending';
        break; 
      case ApprovalStatus.approved:
        bg = const Color(0xFFF1F1F5);
        fg = const Color(0xFF6B7280);
        icon = Icons.check_circle_outline;
        label = 'Approved';
        break;
      case ApprovalStatus.rejected:
        bg = const Color(0xFFFDEBEC);
        fg = const Color(0xFFE5484D);
        icon = Icons.cancel_outlined;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  const _EmptyApprovals();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.task_alt_outlined, size: 40, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        const Text('Nothing here', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        const SizedBox(height: 6),
        Text(
          'You\'re all caught up.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _kPrimary),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}