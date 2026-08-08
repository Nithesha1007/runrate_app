import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_colors_data.dart';
import '../../../../core/theme/app_typography.dart';
import 'engineering_manager_approvals_cubit.dart';

/// Engineering Manager · Approvals
/// Pending requests with approve / reject-with-message flow.
class EngineeringManagerApprovalsScreen extends StatelessWidget {
  const EngineeringManagerApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EngineeringManagerApprovalsCubit()..loadApprovals(),
      child: const _EngineeringManagerApprovalsView(),
    );
  }
}

class _EngineeringManagerApprovalsView extends StatelessWidget {
  const _EngineeringManagerApprovalsView();

  Future<void> _handleReject(
      BuildContext context, ApprovalRequest request) async {
    final cubit = context.read<EngineeringManagerApprovalsCubit>();
    final colors = AppColors.of(context);
    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reject request',
              style: AppTypography.h3(colors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Let ${request.requesterName} know why this is being rejected.',
                  style: AppTypography.body(colors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection',
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Cancel',
                  style: AppTypography.body(colors.textSecondary)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.danger,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (message == null || message.isEmpty || !context.mounted) return;
    await cubit.reject(request.id, message);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rejected ${request.requesterName}\'s request')),
      );
    }
  }

  Future<void> _handleApprove(
      BuildContext context, ApprovalRequest request) async {
    final cubit = context.read<EngineeringManagerApprovalsCubit>();
    await cubit.approve(request.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Approved ${request.requesterName}\'s request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text('Approvals', style: AppTypography.h3(colors.textPrimary)),
      ),
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerApprovalsCubit,
            EngineeringManagerApprovalsState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerApprovalsInitial() ||
              EngineeringManagerApprovalsLoading() =>
                _LoadingView(colors: colors),
              EngineeringManagerApprovalsError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context
                      .read<EngineeringManagerApprovalsCubit>()
                      .loadApprovals(),
                ),
              EngineeringManagerApprovalsLoaded(
                :final data,
                :final isProcessing
              ) =>
                data.pending.isEmpty
                    ? const _EmptyView()
                    : Column(
                        children: [
                          if (isProcessing)
                            const LinearProgressIndicator(minHeight: 2)
                          else
                            const SizedBox(height: 2),
                          Expanded(
                            child: RefreshIndicator(
                              color: colors.primary,
                              onRefresh: () => context
                                  .read<EngineeringManagerApprovalsCubit>()
                                  .refresh(),
                              child: ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(AppSpacing.xl),
                                itemCount: data.pending.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final request = data.pending[index];
                                  return _Staggered(
                                    index: index,
                                    child: _ApprovalCard(
                                      request: request,
                                      enabled: !isProcessing,
                                      onApprove: () =>
                                          _handleApprove(context, request),
                                      onReject: () =>
                                          _handleReject(context, request),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
            };
          },
        ),
      ),
    );
  }
}

/// Slide-up + fade stagger wrapper, matching the Home screen's entrance style.
class _Staggered extends StatelessWidget {
  const _Staggered({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => Opacity(
        opacity: value,
        child: Transform.translate(
            offset: Offset(0, (1 - value) * 16), child: child),
      ),
      child: child,
    );
  }
}

/// Subtle scale-down-on-tap wrapper for tactile buttons.
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

// ---------------------------------------------------------------------------
// TYPE BRAND — each approval type gets its own icon + color instead of a
// plain initials avatar reused for everything.
// ---------------------------------------------------------------------------
class _TypeBrand {
  const _TypeBrand({required this.icon, required this.color, required this.bg});
  final IconData icon;
  final Color color;
  final Color bg;
}

_TypeBrand _brandFor(ApprovalType type) {
  switch (type) {
    case ApprovalType.timeOff:
      return const _TypeBrand(
          icon: Icons.beach_access_rounded,
          color: Color(0xFF2F80ED),
          bg: Color(0xFFE8F1FE));
    case ApprovalType.expense:
      return const _TypeBrand(
          icon: Icons.receipt_long_rounded,
          color: Color(0xFFB7791F),
          bg: Color(0xFFFBF0DD));
    case ApprovalType.toolAccess:
      return const _TypeBrand(
          icon: Icons.vpn_key_rounded,
          color: Color(0xFF6C5CE7),
          bg: Color(0xFFEFECFD));
    case ApprovalType.resourceRequest:
      return const _TypeBrand(
          icon: Icons.dns_rounded,
          color: Color(0xFF11998E),
          bg: Color(0xFFE1F5F3));
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.request,
    required this.enabled,
    required this.onApprove,
    required this.onReject,
  });

  final ApprovalRequest request;
  final bool enabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final brand = _brandFor(request.type);

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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: brand.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(brand.icon, color: brand.color, size: 19),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.requesterName,
                        style: AppTypography.body(colors.textPrimary)
                            .copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('${request.type.label} · ${request.submittedAgo}',
                        style: AppTypography.caption(colors.textSecondary)),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    request.requesterInitials,
                    style: AppTypography.caption(colors.primary)
                        .copyWith(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(request.detail,
                style: AppTypography.body(colors.textPrimary)),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ScaleOnTap(
                  enabled: enabled,
                  onTap: onReject,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.danger.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close_rounded,
                            size: 16, color: colors.danger),
                        const SizedBox(width: 6),
                        Text('Reject',
                            style: AppTypography.caption(colors.danger)
                                .copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ScaleOnTap(
                  enabled: enabled,
                  onTap: onApprove,
                  child: Container(
                    height: 40,
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
                        Icon(Icons.check_rounded,
                            size: 16, color: Colors.white),
                        SizedBox(width: 6),
                        Text('Approve',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.colors});
  final AppColorsData colors;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) => Container(
        height: 150,
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

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
                color: colors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.task_alt_rounded, size: 32, color: colors.success),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('All caught up', style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'There are no pending requests right now.',
              style: AppTypography.body(colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
            Text('Couldn\'t load approvals',
                style: AppTypography.h3(colors.textPrimary)),
            const SizedBox(height: AppSpacing.xs),
            Text(message,
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
