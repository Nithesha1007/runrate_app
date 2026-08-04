import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_approvals_cubit.dart';

/// CFO · Approvals
/// Pending requests with approve / reject-with-message flow, wired to
/// [CfoApprovalsCubit].
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
      appBar: AppBar(title: const Text('Approvals')),
      body: SafeArea(
        child: BlocBuilder<CfoApprovalsCubit, CfoApprovalsState>(
          builder: (context, state) {
            if (state is CfoApprovalsLoading || state is CfoApprovalsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoApprovalsError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoApprovalsCubit>().load(),
              );
            }

            final loaded = state as CfoApprovalsLoaded;
            final pending = loaded.pending;

            return RefreshIndicator(
              onRefresh: () => context.read<CfoApprovalsCubit>().refresh(),
              child: pending.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: _EmptyApprovals(),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      itemCount: pending.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => AppCard(
                        child: _ApprovalTile(
                          request: pending[index],
                          isBusy: loaded.actionInFlightId == pending[index].id,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyApprovals extends StatelessWidget {
  const _EmptyApprovals();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(Icons.task_alt_outlined, size: 40, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: AppSpacing.md),
        Text('All caught up', style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'There are no approval requests waiting on you right now.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({required this.request, required this.isBusy});

  final ApprovalRequest request;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _initialsOf(request.requesterName),
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(request.requesterName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(request.category, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              formatInr(request.amount),
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Submitted ${request.submittedDaysAgo} ${request.submittedDaysAgo == 1 ? 'day' : 'days'} ago',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (isBusy)
          const Align(
            alignment: Alignment.centerRight,
            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _confirmReject(context, request),
                icon: Icon(Icons.close, size: 16, color: theme.colorScheme.error),
                label: Text('Reject', style: TextStyle(color: theme.colorScheme.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error)),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton.icon(
                onPressed: () => context.read<CfoApprovalsCubit>().approve(request.id),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve'),
              ),
            ],
          ),
      ],
    );
  }

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _confirmReject(BuildContext context, ApprovalRequest request) async {
    final cubit = context.read<CfoApprovalsCubit>();
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reject ${request.requesterName}\'s request?'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Explain why this is being rejected',
              ),
              maxLines: 3,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'A reason is required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (message != null && message.isNotEmpty) {
      cubit.reject(request.id, message);
    }
  }
}

/// ---------------------------------------------------------------------
/// Error state
/// ---------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — Indian currency (Cr / L)
/// ---------------------------------------------------------------------

String formatInr(double value) {
  if (value >= 10000000) {
    return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
  }
  if (value >= 100000) {
    return '₹${(value / 100000).toStringAsFixed(1)}L';
  }
  return '₹${value.toStringAsFixed(0)}';
}