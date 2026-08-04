import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_spacing.dart';
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

  Future<void> _handleReject(BuildContext context, ApprovalRequest request) async {
    final cubit = context.read<EngineeringManagerApprovalsCubit>();
    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Let ${request.requesterName} know why this is being rejected.'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Reason for rejection',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
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

  Future<void> _handleApprove(BuildContext context, ApprovalRequest request) async {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: SafeArea(
        child: BlocBuilder<EngineeringManagerApprovalsCubit, EngineeringManagerApprovalsState>(
          builder: (context, state) {
            return switch (state) {
              EngineeringManagerApprovalsInitial() ||
              EngineeringManagerApprovalsLoading() =>
                const Center(child: CircularProgressIndicator()),
              EngineeringManagerApprovalsError(:final message) => _ErrorView(
                  message: message,
                  onRetry: () => context.read<EngineeringManagerApprovalsCubit>().loadApprovals(),
                ),
              EngineeringManagerApprovalsLoaded(:final data, :final isProcessing) => data.pending.isEmpty
                  ? const _EmptyView()
                  : Stack(
                      children: [
                        RefreshIndicator(
                          onRefresh: () =>
                              context.read<EngineeringManagerApprovalsCubit>().refresh(),
                          child: ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            itemCount: data.pending.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final request = data.pending[index];
                              return _ApprovalCard(
                                request: request,
                                enabled: !isProcessing,
                                onApprove: () => _handleApprove(context, request),
                                onReject: () => _handleReject(context, request),
                              );
                            },
                          ),
                        ),
                        if (isProcessing)
                          const Positioned(
                            top: 12,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  request.requesterInitials,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.requesterName,
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${request.type.label} · ${request.submittedAgo}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(request.detail, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: enabled ? onReject : null,
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: enabled ? onApprove : null,
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.task_alt_outlined, size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: AppSpacing.md),
            Text('All caught up', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'There are no pending requests right now.',
              style: theme.textTheme.bodySmall,
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text('Couldn\'t load approvals', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(message, style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}