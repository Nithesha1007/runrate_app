import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../data/ceo_mock_repository.dart';

import 'ceo_approvals_cubit.dart';
import 'ceo_approvals_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:runrate/features/roles/ceo/shared/models/approval_model.dart';
import '../../../../features/notifications/notifications_cubit.dart';

import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/reject_request_sheet.dart';
import '../../../../shared/widgets/reveal.dart';
import '../../../../shared/widgets/toast.dart';

/// CEO · Approvals — strategic sign-offs only (large budgets, vendor
/// contracts, leadership hires, partnerships). Approve/Reject/Request Info
/// act on the pending list; a History tab shows past decisions with date.
///
/// NOTE: no longer uses the shared `ApprovalCard` widget — it was rendering
/// raw unresolved template text (`${approval.requesterName}`) and a
/// currency-symbol glyph that shows as a black tofu box on this font. This
/// screen now builds its own `_ApprovalListCard` with plain, correctly
/// interpolated text and an icon-based currency display instead.
///
/// v2 — the shared `SegmentedToggle` for Pending/History is replaced with
/// an in-file `_SegmentedTabs` control (icons, live counts, gradient
/// active state) for full design control, and each pending card now has a
/// "Why this needs your approval" row that opens a detail sheet explaining
/// the approval rationale, with Approve/Reject available right there too.
///
/// v3 — "Request Info" no longer opens the shared reject-style bottom
/// sheet. It now pushes a dedicated `_RequestInfoScreen`: a full page that
/// shows the same "why this needs your approval" context (amount,
/// requester, category, rationale) plus a note field, so the CEO can see
/// the full picture before deciding what to ask the requester for.
class CeoApprovalsScreen extends StatelessWidget {
  const CeoApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CeoApprovalsCubit(
          CeoMockRepository(), context.read<NotificationsCubit>()),
      child: const _CeoApprovalsView(),
    );
  }
}

enum _PriorityFilter { all, urgent, normal }

class _CeoApprovalsView extends StatefulWidget {
  const _CeoApprovalsView();

  @override
  State<_CeoApprovalsView> createState() => _CeoApprovalsViewState();
}

class _CeoApprovalsViewState extends State<_CeoApprovalsView> {
  /// Ids currently animating out of the pending list after an action.
  final Set<String> _animatingOut = {};
  _PriorityFilter _filter = _PriorityFilter.all;

  void _actOnItem(BuildContext context, String id, VoidCallback commitAction) {
    setState(() => _animatingOut.add(id));
    Future.delayed(const Duration(milliseconds: 220), () {
      commitAction();
      if (mounted) setState(() => _animatingOut.remove(id));
    });
  }

  List<ApprovalModel> _applyPriorityFilter(
      List<ApprovalModel> pending, CeoApprovalsState state) {
    switch (_filter) {
      case _PriorityFilter.all:
        return pending;
      case _PriorityFilter.urgent:
        return pending
            .where((a) =>
                state.priorityOf(a) == ApprovalPriority.high ||
                state.priorityOf(a) == ApprovalPriority.critical)
            .toList();
      case _PriorityFilter.normal:
        return pending
            .where((a) =>
                state.priorityOf(a) != ApprovalPriority.high &&
                state.priorityOf(a) != ApprovalPriority.critical)
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<CeoApprovalsCubit, CeoApprovalsState>(
          builder: (context, state) {
            if (state.loading) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: const [
                  SkeletonLoader(height: 180),
                  SizedBox(height: AppSpacing.lg),
                  SkeletonLoader(height: 150),
                  SizedBox(height: AppSpacing.md),
                  SkeletonLoader(height: 150),
                  SizedBox(height: AppSpacing.md),
                  SkeletonLoader(height: 150),
                ],
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScreenHeader(colors: colors),
                      const SizedBox(height: AppSpacing.lg),
                      _Staggered(
                        index: 0,
                        child: _ApprovalsHeroCard(state: state),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _Staggered(
                        index: 1,
                        child: _SegmentedTabs(
                          selectedIndex: state.viewIndex,
                          onChanged: (i) =>
                              context.read<CeoApprovalsCubit>().setView(i),
                          pendingCount: state.pending.length,
                          historyCount: state.history.length,
                        ),
                      ),
                      if (state.viewIndex == 0) ...[
                        const SizedBox(height: AppSpacing.md),
                        _Staggered(
                          index: 2,
                          child: _PriorityFilterRow(
                            pending: state.pending,
                            state: state,
                            selected: _filter,
                            onSelect: (f) => setState(() => _filter = f),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: state.viewIndex == 0
                      ? _buildPending(context, state)
                      : _buildHistory(context, state),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPending(BuildContext context, CeoApprovalsState state) {
    final colors = AppColors.of(context);
    final pending = _applyPriorityFilter(state.pending, state);
    if (pending.isEmpty) {
      return EmptyState(
        title: state.pending.isEmpty ? 'All caught up' : 'Nothing in this filter',
        message: state.pending.isEmpty
            ? 'No pending approvals right now.'
            : 'Try a different priority filter.',
        icon: Icons.check_circle_outline,
      );
    }
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => context.read<CeoApprovalsCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 100),
        itemCount: pending.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final approval = pending[i];
          final hiding = _animatingOut.contains(approval.id);
          return Reveal(
            delayMs: i * 50,
            child: AnimatedOpacity(
              opacity: hiding ? 0 : 1,
              duration: const Duration(milliseconds: 200),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: hiding
                    ? const SizedBox.shrink()
                    : _ApprovalListCard(
                        approval: approval,
                        priority: state.priorityOf(approval),
                        onApprove: () => _actOnItem(context, approval.id, () {
                          context
                              .read<CeoApprovalsCubit>()
                              .approve(approval.id);
                          showAppToast(
                              context, 'Approved "${approval.title}"');
                        }),
                        onReject: () async {
                          final message = await showRejectRequestSheet(
                              context,
                              requesterName: approval.requesterName);
                          if (message != null && context.mounted) {
                            _actOnItem(context, approval.id, () {
                              context
                                  .read<CeoApprovalsCubit>()
                                  .reject(approval.id, message);
                              showAppToast(context,
                                  'Rejected and notified ${approval.requesterName}');
                            });
                          }
                        },
                        onRequestInfo: () async {
                          final message = await Navigator.of(context)
                              .push<String>(MaterialPageRoute(
                            builder: (_) => _RequestInfoScreen(
                              approval: approval,
                              priority: state.priorityOf(approval),
                            ),
                          ));
                          if (message != null && context.mounted) {
                            context
                                .read<CeoApprovalsCubit>()
                                .requestInfo(approval.id, message);
                            showAppToast(context,
                                'Requested more info from ${approval.requesterName}');
                          }
                        },
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistory(BuildContext context, CeoApprovalsState state) {
    final colors = AppColors.of(context);
    final history = state.history;
    if (history.isEmpty) {
      return const EmptyState(
        title: 'No history yet',
        message: 'Decisions you make will show up here.',
        icon: Icons.history,
      );
    }
    return RefreshIndicator(
      color: colors.primary,
      onRefresh: () => context.read<CeoApprovalsCubit>().load(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, 100),
        itemCount: history.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          final approval = history[i];
          final decidedAt = state.decisionTimes[approval.id];
          return Reveal(
            delayMs: i * 40,
            child: _HistoryTile(approval: approval, decidedAt: decidedAt),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Screen header
// ---------------------------------------------------------------------------
class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Approvals', style: AppTypography.h1(colors.textPrimary)),
              const SizedBox(height: 2),
              Text('Strategic sign-offs only',
                  style: AppTypography.caption(colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Slide-up + fade stagger wrapper, indexed by section order.
class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 16),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Subtle scale-down-on-tap wrapper for tactile chips/buttons.
class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

final _amountFormat = NumberFormat('#,##0');
String _formatAmount(double value) => _amountFormat.format(value);
String _compact(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return _formatAmount(value);
}

/// Shared "why this needs your approval" rationale, derived from the
/// fields `ApprovalModel` actually carries (category, amount, computed
/// priority, requester) rather than a dedicated justification field, since
/// the model doesn't expose one today. Used by both the quick detail sheet
/// and the full Request Info screen so the reasoning stays consistent.
List<String> _approvalReasons(ApprovalModel approval, bool isUrgent) {
  final reasons = <String>[];
  if (isUrgent) {
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
// SEGMENTED TABS — Pending / History, with live counts and a gradient
// active state. Replaces the shared `SegmentedToggle` so the tab bar can
// match the rest of this screen's visual language (icons, count badges,
// soft shadow on the active tab) instead of a generic pill toggle.
// ---------------------------------------------------------------------------
class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({
    required this.selectedIndex,
    required this.onChanged,
    required this.pendingCount,
    required this.historyCount,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final int pendingCount;
  final int historyCount;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final tabs = [
      (label: 'Pending', icon: Icons.pending_actions_rounded, count: pendingCount),
      (label: 'History', icon: Icons.history_rounded, count: historyCount),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final tab = tabs[i];
          final selected = i == selectedIndex;
          return Expanded(
            child: _ScaleOnTap(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [colors.primary, colors.secondary])
                      : null,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tab.icon,
                        size: 16,
                        color: selected ? Colors.white : colors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: AppTypography.body(
                              selected ? Colors.white : colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (tab.count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withValues(alpha: 0.22)
                              : colors.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${tab.count}',
                          style: AppTypography.caption(
                                  selected ? Colors.white : colors.textSecondary)
                              .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO CARD
// ---------------------------------------------------------------------------
class _ApprovalsHeroCard extends StatelessWidget {
  const _ApprovalsHeroCard({required this.state});
  final CeoApprovalsState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final pending = state.pending;
    final totalValue =
        pending.fold<double>(0, (sum, a) => sum + a.amount);
    final urgentCount = pending
        .where((a) =>
            state.priorityOf(a) == ApprovalPriority.high ||
            state.priorityOf(a) == ApprovalPriority.critical)
        .length;
    final approvedCount =
        state.history.where((a) => a.status == ApprovalStatus.approved).length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.primary,
                colors.secondary,
                colors.primary.withValues(alpha: 0.85),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Awaiting your sign-off',
                        style: AppTypography.h3(Colors.white)),
                  ),
                  _StatusPill(
                    label: pending.isEmpty
                        ? 'All clear'
                        : urgentCount > 0
                            ? '$urgentCount urgent'
                            : 'Normal',
                    color: pending.isEmpty
                        ? colors.success
                        : urgentCount > 0
                            ? colors.danger
                            : colors.info,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AnimatedCounterText(
                        target: pending.length,
                        style: AppTypography.display(Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text('pending items',
                          style: AppTypography.caption(
                              Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StatChip(
                            label: 'Value', value: _compact(totalValue)),
                        const SizedBox(height: AppSpacing.sm),
                        _StatChip(
                            label: 'Approved this month',
                            value: '$approvedCount'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.caption(Colors.white)),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  const _AnimatedCounterText({
    required this.target,
    required this.style,
  }) : suffix = '';

  final int target;
  final TextStyle style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Text('$value$suffix', style: style),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style:
                  AppTypography.caption(Colors.white.withValues(alpha: 0.8))),
          Text(value,
              style: AppTypography.caption(Colors.white)
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRIORITY FILTER ROW
// ---------------------------------------------------------------------------
class _PriorityFilterRow extends StatelessWidget {
  const _PriorityFilterRow({
    required this.pending,
    required this.state,
    required this.selected,
    required this.onSelect,
  });

  final List<ApprovalModel> pending;
  final CeoApprovalsState state;
  final _PriorityFilter selected;
  final ValueChanged<_PriorityFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final urgent = pending
        .where((a) =>
            state.priorityOf(a) == ApprovalPriority.high ||
            state.priorityOf(a) == ApprovalPriority.critical)
        .length;
    final normal = pending.length - urgent;

    final chips = <(_PriorityFilter, String, Color?)>[
      (_PriorityFilter.all, 'All (${pending.length})', null),
      (_PriorityFilter.urgent, 'Urgent ($urgent)', colors.danger),
      (_PriorityFilter.normal, 'Normal ($normal)', colors.info),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final (filter, label, dotColor) = chips[i];
          final isSelected = filter == selected;
          return _ScaleOnTap(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isSelected ? colors.primary : colors.surfaceElevated,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: isSelected ? colors.primary : colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dotColor != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: dotColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: AppTypography.caption(
                            isSelected ? Colors.white : colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// APPROVAL LIST CARD — replaces the broken shared `ApprovalCard`. Plain,
// correctly interpolated text, icon-based currency (no tofu glyph), a
// priority ribbon, a "Why this needs your approval" row that opens the
// detail sheet, and Approve / Reject / Request Info actions.
// ---------------------------------------------------------------------------
class _ApprovalListCard extends StatelessWidget {
  const _ApprovalListCard({
    required this.approval,
    required this.priority,
    required this.onApprove,
    required this.onReject,
    required this.onRequestInfo,
  });

  final ApprovalModel approval;
  final ApprovalPriority priority;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onRequestInfo;

  bool get _isUrgent =>
      priority == ApprovalPriority.high || priority == ApprovalPriority.critical;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final priorityColor = _isUrgent ? colors.danger : colors.info;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                        style: AppTypography.caption(priorityColor).copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                  ],
                ),
              ),
              const Spacer(),
              if (approval.category.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(approval.category,
                      style: AppTypography.caption(colors.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(approval.title,
              style: AppTypography.h3(colors.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.person_outline_rounded,
                  size: 14, color: colors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text('Requested by ${approval.requesterName}',
                    style: AppTypography.caption(colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.currency_rupee_rounded,
                  size: 18, color: colors.textPrimary),
              Text(_formatAmount(approval.amount),
                  style: AppTypography.h3(colors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScaleOnTap(
            onTap: () => _showApprovalDetailsSheet(
              context,
              approval: approval,
              priority: priority,
              onApprove: onApprove,
              onReject: onReject,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xs + 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Why this needs your approval',
                        style: AppTypography.caption(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: colors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ScaleOnTap(
                  onTap: onReject,
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: colors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Text('Reject',
                        style: AppTypography.body(colors.danger)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: _ScaleOnTap(
                  onTap: onApprove,
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                          colors: [colors.primary, colors.secondary]),
                      boxShadow: [
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.28),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded,
                            size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('Approve',
                            style: AppTypography.body(Colors.white)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: _ScaleOnTap(
              onTap: onRequestInfo,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.help_outline_rounded,
                        size: 16, color: colors.primary),
                    const SizedBox(width: 4),
                    Text('Request Info',
                        style: AppTypography.caption(colors.primary)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// APPROVAL DETAILS SHEET — "Why this needs your approval". Shows the full
// request (title, category, priority, requester, amount) plus a rationale
// list, with Approve / Reject reachable right from the sheet.
// ---------------------------------------------------------------------------
void _showApprovalDetailsSheet(
  BuildContext context, {
  required ApprovalModel approval,
  required ApprovalPriority priority,
  required VoidCallback onApprove,
  required VoidCallback onReject,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ApprovalDetailsSheet(
      approval: approval,
      priority: priority,
      onApprove: onApprove,
      onReject: onReject,
    ),
  );
}

class _ApprovalDetailsSheet extends StatelessWidget {
  const _ApprovalDetailsSheet({
    required this.approval,
    required this.priority,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalModel approval;
  final ApprovalPriority priority;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  bool get _isUrgent =>
      priority == ApprovalPriority.high || priority == ApprovalPriority.critical;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final priorityColor = _isUrgent ? colors.danger : colors.info;
    final reasons = _approvalReasons(approval, _isUrgent);

    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(AppSpacing.xl,
                    AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
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
                              style: AppTypography.caption(colors.textSecondary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(approval.title, style: AppTypography.h3(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
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
                          colors: [colors.primary, colors.secondary]),
                      borderRadius: BorderRadius.circular(20),
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
                  Text('Why this needs your approval',
                      style: AppTypography.h3(colors.textPrimary)),
                  const SizedBox(height: AppSpacing.sm),
                  ...reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                  color: colors.primary, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(reason,
                                  style: AppTypography.body(colors.textSecondary)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onReject();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: colors.danger,
                            side: BorderSide(
                                color: colors.danger.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onApprove();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REQUEST INFO SCREEN — full page pushed when the CEO taps "Request Info"
// on a pending card. Shows the same context as the "why this needs your
// approval" sheet (priority, category, requester, amount, rationale) so
// the CEO has the full picture, then a note field for what to ask the
// requester, and a "Send Request" button that pops this screen with the
// typed message so the caller can hand it to the cubit.
// ---------------------------------------------------------------------------
class _RequestInfoScreen extends StatefulWidget {
  const _RequestInfoScreen({required this.approval, required this.priority});

  final ApprovalModel approval;
  final ApprovalPriority priority;

  @override
  State<_RequestInfoScreen> createState() => _RequestInfoScreenState();
}

class _RequestInfoScreenState extends State<_RequestInfoScreen> {
  final _controller = TextEditingController();
  static const _suggestions = [
    'Need a vendor quote breakdown',
    'Please share the ROI justification',
    'Confirm if this was budgeted',
    'Need sign-off from department head',
  ];

  bool get _isUrgent =>
      widget.priority == ApprovalPriority.high ||
      widget.priority == ApprovalPriority.critical;

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
    final reasons = _approvalReasons(approval, _isUrgent);

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
        title: Text('Request info', style: AppTypography.h3(colors.textPrimary)),
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
                              style: AppTypography.caption(colors.textSecondary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(approval.title, style: AppTypography.h2(colors.textPrimary)),
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
                        .map((s) => _ScaleOnTap(
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
                    return _ScaleOnTap(
                      onTap: enabled ? _submit : () {},
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

class _HistoryTile extends StatelessWidget {
  final ApprovalModel approval;
  final DateTime? decidedAt;
  const _HistoryTile({required this.approval, required this.decidedAt});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final approved = approval.status == ApprovalStatus.approved;
    final color = approved ? colors.success : colors.danger;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              approved ? Icons.check_circle_outline : Icons.cancel_outlined,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  approval.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body(colors.textPrimary)
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        approval.requesterName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption(colors.textSecondary),
                      ),
                    ),
                    Icon(Icons.currency_rupee_rounded,
                        size: 12, color: colors.textSecondary),
                    Text(_formatAmount(approval.amount),
                        style: AppTypography.caption(colors.textSecondary)),
                    if (decidedAt != null) ...[
                      Text(' · ${_formatDate(decidedAt!)}',
                          style: AppTypography.caption(colors.textSecondary)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              approved ? 'Approved' : 'Declined',
              style: AppTypography.caption(color)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[d.month - 1]} ${d.day}';
  }
}