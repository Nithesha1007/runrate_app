import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_approval_actions.dart';
import 'engineering_manager_approval_details_screen.dart';
import 'engineering_manager_approvals_cubit.dart';
import 'pending_requests_repository.dart';

/// Engineering Manager · Approvals (team-tier).
/// Deliberately excludes: Delegate action, vendor/annual-cost/risk-level
/// fields, cross-department comparisons — those are CEO-tier. This screen
/// is single-team, single-seat AI-tool requests only.
class EngineeringManagerApprovalsScreen extends StatelessWidget {
  const EngineeringManagerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerApprovalsCubit(),
      child: const _EngineeringManagerApprovalsView(),
    );
  }
}

enum _Tab { pending, history }

class _EngineeringManagerApprovalsView extends StatefulWidget {
  const _EngineeringManagerApprovalsView();

  @override
  State<_EngineeringManagerApprovalsView> createState() =>
      _EngineeringManagerApprovalsViewState();
}

class _EngineeringManagerApprovalsViewState
    extends State<_EngineeringManagerApprovalsView> {
  _Tab _tab = _Tab.pending;
  RequestPriority? _priorityFilter; // null = All

  List<PendingRequestData> _filteredPending(
      EngineeringManagerApprovalsData data) {
    if (_priorityFilter == null) return data.pending;
    return data.pending.where((r) => r.priority == _priorityFilter).toList();
  }

  /// Pushes the details screen with the same cubit instance, so
  /// approve/reject there updates the exact state this list is watching.
  Future<void> _openDetails(BuildContext context, String requestId) {
    final cubit = context.read<EngineeringManagerApprovalsCubit>();
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, animation, __) => BlocProvider.value(
          value: cubit,
          child: EngineeringManagerApprovalDetailsScreen(requestId: requestId),
        ),
        transitionsBuilder: (_, animation, __, child) {
          final curved =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
                .animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerApprovalsCubit,
            EngineeringManagerApprovalsState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerApprovalsLoading() => _LoadingView(colors: colors),
              EngineeringManagerApprovalsError(:final message) => Column(
                  children: [
                    const _Header(),
                    Expanded(
                      child: _ErrorView(
                        message: message,
                        onRetry: () => context
                            .read<EngineeringManagerApprovalsCubit>()
                            .loadApprovals(),
                      ),
                    ),
                  ],
                ),
              EngineeringManagerApprovalsLoaded(:final data, :final isProcessing) =>
                RefreshIndicator(
                  color: colors.primary,
                  onRefresh: () =>
                      context.read<EngineeringManagerApprovalsCubit>().refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      const SliverToBoxAdapter(child: _Header()),
                      SliverToBoxAdapter(child: _HeroCard(data: data)),
                      SliverToBoxAdapter(
                        child: _SegmentedToggle(
                          tab: _tab,
                          pendingCount: data.pendingCount,
                          historyCount: data.history.length,
                          onChanged: (t) => setState(() => _tab = t),
                        ),
                      ),
                      if (_tab == _Tab.pending)
                        SliverToBoxAdapter(
                          child: _PriorityChips(
                            selected: _priorityFilter,
                            countFor: data.countFor,
                            onSelected: (p) =>
                                setState(() => _priorityFilter = p),
                          ),
                        ),
                      if (isProcessing)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: colors.surfaceElevated,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                          child: SizedBox(height: isProcessing ? AppSpacing.sm : 0)),
                      _buildBody(context, colors, data),
                    ],
                  ),
                ),
            };
          },
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColorsData colors,
    EngineeringManagerApprovalsData data,
  ) {
    final processingState =
        context.watch<EngineeringManagerApprovalsCubit>().state;
    final processingId = processingState is EngineeringManagerApprovalsLoaded
        ? processingState.processingId
        : null;

    if (_tab == _Tab.history) {
      final items = data.history;
      if (items.isEmpty) {
        return const SliverFillRemaining(
            hasScrollBody: false, child: _EmptyHistoryView());
      }
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        sliver: SliverList.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) => _Staggered(
              index: index,
              child: _HistoryTile(
                request: items[index],
                onTap: () => _openDetails(context, items[index].id),
              )),
        ),
      );
    }

    final items = _filteredPending(data);
    if (items.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _priorityFilter != null
            ? const _NoResultsView()
            : const _EmptyPendingView(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final request = items[index];
          return _Staggered(
            index: index,
            child: _PendingCard(
              key: ValueKey(request.id),
              request: request,
              enabled: processingId == null,
              onApprove: () => context
                  .read<EngineeringManagerApprovalsCubit>()
                  .approve(request.id),
              onReject: () => openRejectRequestScreen(context, request),
              onViewDetails: () => _openDetails(context, request.id),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Approvals', style: AppTypography.h2(colors.textPrimary)),
          const SizedBox(height: 2),
          Text('Team AI tool requests',
              style: AppTypography.body(colors.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HERO CARD
// FIX: the budget stat used to be a single Row with a concatenated
// " / 60,000" suffix that had no room to shrink — that's what threw the
// overflow. It's now stacked (big remaining figure, small "of ₹X total"
// caption underneath) so there's no long single line competing for width,
// and every number still routes through the overflow-safe CurrencyLabel.
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.data});
  final EngineeringManagerApprovalsData data;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final overBudget = data.budget.remainingBudget < 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.xl, AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.primary, colors.secondary],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withOpacity(0.30),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween:
                                Tween(begin: 0, end: data.pendingCount.toDouble()),
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) => Text(
                              value.round().toString(),
                              style: AppTypography.h1(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w800, height: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.pendingCount == 1
                            ? 'request awaiting your approval'
                            : 'requests awaiting your approval',
                        style: AppTypography.caption(Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
                if (data.urgentCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.priority_high_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              '${data.urgentCount} high priority',
                              style: AppTypography.caption(Colors.white)
                                  .copyWith(fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: Colors.white.withOpacity(0.18)),
            const SizedBox(height: AppSpacing.md),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _HeroStat(
                      label: 'Monthly value pending',
                      value: CurrencyLabel(
                        data.totalMonthlyPending,
                        style: AppTypography.h3(Colors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                        iconSize: 15,
                      ),
                    ),
                  ),
                  Container(
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                      color: Colors.white.withOpacity(0.18)),
                  Expanded(
                    child: _HeroStat(
                      label: 'Team budget remaining',
                      value: CurrencyLabel(
                        data.budget.remainingBudget,
                        style: AppTypography.h3(
                                overBudget ? colors.warning : Colors.white)
                            .copyWith(fontWeight: FontWeight.w700),
                        iconSize: 15,
                      ),
                      caption:
                          'of ${formatAmountDigits(data.budget.totalMonthlyBudget)} total',
                    ),
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

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value, this.caption});
  final String label;
  final Widget value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          value,
          if (caption != null)
            Text(caption!,
                style: AppTypography.caption(Colors.white.withOpacity(0.75))
                    .copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption(Colors.white.withOpacity(0.85)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SEGMENTED TOGGLE
// ---------------------------------------------------------------------------

class _SegmentedToggle extends StatelessWidget {
  const _SegmentedToggle({
    required this.tab,
    required this.pendingCount,
    required this.historyCount,
    required this.onChanged,
  });

  final _Tab tab;
  final int pendingCount;
  final int historyCount;
  final ValueChanged<_Tab> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: _ToggleSegment(
                label: 'Pending',
                count: pendingCount,
                selected: tab == _Tab.pending,
                onTap: () => onChanged(_Tab.pending),
              ),
            ),
            Expanded(
              child: _ToggleSegment(
                label: 'History',
                count: historyCount,
                selected: tab == _Tab.history,
                onTap: () => onChanged(_Tab.history),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.primary.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          '$label ($count)',
          style: AppTypography.caption(selected ? Colors.white : colors.textSecondary)
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PRIORITY FILTER CHIPS
// ---------------------------------------------------------------------------

class _PriorityChips extends StatelessWidget {
  const _PriorityChips({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final RequestPriority? selected;
  final int Function(RequestPriority?) countFor;
  final ValueChanged<RequestPriority?> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final options = <RequestPriority?>[
      null,
      RequestPriority.high,
      RequestPriority.medium,
      RequestPriority.low,
    ];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final p = options[index];
          final isSelected = p == selected;
          final label = p == null ? 'All' : p.label;
          final color = p == null ? colors.primary : priorityColor(context, p);

          return ChoiceChip(
            avatar: p == null
                ? null
                : Icon(priorityIcon(p),
                    size: 14, color: isSelected ? Colors.white : color),
            label: Text('$label (${countFor(p)})'),
            selected: isSelected,
            onSelected: (_) => onSelected(p),
            labelStyle: AppTypography.caption(
                    isSelected ? Colors.white : colors.textSecondary)
                .copyWith(fontWeight: FontWeight.w600),
            backgroundColor: colors.surfaceElevated,
            selectedColor: color,
            side: BorderSide(color: isSelected ? color : colors.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ANIMATION HELPERS
// ---------------------------------------------------------------------------

class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 60).clamp(0, 480);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 14), child: child),
      ),
      child: child,
    );
  }
}

class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap(
      {required this.child, required this.onTap, this.enabled = true});
  final Widget child;
  final VoidCallback onTap;
  final bool enabled;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _scale = 0.95) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _scale = 1);
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => setState(() => _scale = 1) : null,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Opacity(opacity: widget.enabled ? 1 : 0.5, child: widget.child),
      ),
    );
  }
}

class _ExitAnimated extends StatelessWidget {
  const _ExitAnimated({required this.child, required this.exiting});
  final Widget child;
  final bool exiting;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: exiting ? 0 : 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: exiting ? 0.92 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// PENDING CARD
// ---------------------------------------------------------------------------

class _PendingCard extends StatefulWidget {
  const _PendingCard({
    super.key,
    required this.request,
    required this.enabled,
    required this.onApprove,
    required this.onReject,
    required this.onViewDetails,
  });

  final PendingRequestData request;
  final bool enabled;
  final VoidCallback onApprove;

  /// Returns true if the request was actually rejected (vs. cancelled),
  /// so the card knows whether to play its exit animation.
  final Future<bool> Function() onReject;
  final VoidCallback onViewDetails;

  @override
  State<_PendingCard> createState() => _PendingCardState();
}

class _PendingCardState extends State<_PendingCard> {
  bool _expanded = false;
  bool _exiting = false;

  void _handleApprove() {
    setState(() => _exiting = true);
    widget.onApprove();
  }

  Future<void> _handleReject() async {
    final rejected = await widget.onReject();
    if (rejected && mounted) setState(() => _exiting = true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final request = widget.request;
    final pColor = priorityColor(context, request.priority);
    final isHigh = request.priority == RequestPriority.high;

    return _ExitAnimated(
      exiting: _exiting,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isHigh ? colors.danger.withOpacity(0.45) : colors.border,
              width: isHigh ? 1.4 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.enabled ? widget.onViewDetails : null,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initials(request.employeeName),
                        style: AppTypography.caption(colors.primary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request.employeeName,
                              style: AppTypography.body(colors.textPrimary)
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          if (request.employeeRole.isNotEmpty)
                            Text(request.employeeRole,
                                style: AppTypography.caption(colors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(priorityIcon(request.priority), size: 12, color: pColor),
                          const SizedBox(width: 3),
                          Text(
                            request.priority.label.toUpperCase(),
                            style: AppTypography.caption(pColor)
                                .copyWith(fontWeight: FontWeight.w700, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, size: 14, color: colors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(request.requestedTool,
                            style: AppTypography.body(colors.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      CurrencyLabel(
                        request.monthlyCost,
                        suffix: '/mo',
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Text(
                    request.justification,
                    style: AppTypography.caption(colors.textSecondary),
                    maxLines: _expanded ? null : 2,
                    overflow: _expanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                if (request.duplicateTeammateCount > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.primary.withOpacity(0.16)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.content_copy_rounded,
                            size: 13, color: colors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${request.duplicateTeammateCount} teammate${request.duplicateTeammateCount == 1 ? '' : 's'} already use ${request.requestedTool}',
                            style: AppTypography.caption(colors.primary)
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(formatRelative(request.requestDate),
                        style: AppTypography.caption(colors.textSecondary)),
                    const Spacer(),
                    InkWell(
                      onTap: widget.enabled ? widget.onViewDetails : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('View details',
                                style: AppTypography.caption(colors.primary)
                                    .copyWith(fontWeight: FontWeight.w700)),
                            Icon(Icons.chevron_right_rounded,
                                size: 15, color: colors.primary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final rejectBtn = _ScaleOnTap(
                      enabled: widget.enabled,
                      onTap: _handleReject,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.danger.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: colors.danger.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 16, color: colors.danger),
                            const SizedBox(width: 6),
                            Text('Reject',
                                style: AppTypography.caption(colors.danger)
                                    .copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    );

                    final approveBtn = _ScaleOnTap(
                      enabled: widget.enabled,
                      onTap: _handleApprove,
                      child: Container(
                        height: 42,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary]),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.28),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text('Approve',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    );

                    return Row(
                      children: [
                        Expanded(child: rejectBtn),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(flex: 2, child: approveBtn),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// HISTORY TILE
// ---------------------------------------------------------------------------

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.request, required this.onTap});
  final PendingRequestData request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final approved = request.decision == RequestDecision.approved;
    final color = approved ? colors.success : colors.danger;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
                  BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(approved ? Icons.check_rounded : Icons.close_rounded,
                  size: 16, color: color),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.requestedTool,
                      style: AppTypography.body(colors.textPrimary)
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${approved ? 'Approved' : 'Rejected'} · ${request.employeeName}',
                    style: AppTypography.caption(colors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!approved && request.rejectionReason != null)
                    Text(request.rejectionReason!,
                        style: AppTypography.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatRelative(request.decidedAt ?? request.requestDate),
                    style: AppTypography.caption(colors.textSecondary)),
                Icon(Icons.chevron_right_rounded, size: 16, color: colors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EMPTY / LOADING / ERROR STATES
// ---------------------------------------------------------------------------

class _EmptyPendingView extends StatelessWidget {
  const _EmptyPendingView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                  color: colors.success.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.task_alt_rounded, size: 32, color: colors.success),
            ),
            const SizedBox(height: AppSpacing.md),
            Text("You're all caught up", style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('No requests from your team need approval right now.',
                style: AppTypography.body(colors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 32, color: colors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('No history yet', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Requests you approve or reject will show up here.',
                style: AppTypography.body(colors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_off_rounded, size: 32, color: colors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text('No matching requests', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Try a different priority filter.',
                style: AppTypography.body(colors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        _Shimmer(child: _skeletonBlock(colors, height: 44)),
        const SizedBox(height: AppSpacing.md),
        _Shimmer(child: _skeletonBlock(colors, height: 140)),
        const SizedBox(height: AppSpacing.md),
        _Shimmer(child: _skeletonBlock(colors, height: 44)),
        const SizedBox(height: AppSpacing.lg),
        for (var i = 0; i < 3; i++) ...[
          _Shimmer(child: _skeletonBlock(colors, height: 190)),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _skeletonBlock(AppColorsData colors, {required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1 + 3 * t, 0),
              end: Alignment(0 + 3 * t, 0),
              colors: [
                Colors.white.withOpacity(0.0),
                Colors.white.withOpacity(0.35),
                Colors.white.withOpacity(0.0),
              ],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: colors.danger),
            const SizedBox(height: AppSpacing.md),
            Text('Unable to load approvals', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text('Something went wrong while loading your requests.',
                style: AppTypography.body(colors.textSecondary),
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}