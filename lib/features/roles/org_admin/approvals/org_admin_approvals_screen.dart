import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';
import 'org_admin_approvals_cubit.dart';

/// Org Admin · Approvals
/// Pending requests with approve / reject-with-message flow. Wired to
/// [OrgAdminApprovalsCubit].
class OrgAdminApprovalsScreen extends StatelessWidget {
  const OrgAdminApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OrgAdminApprovalsCubit()..loadRequests(),
      child: const _OrgAdminApprovalsView(),
    );
  }
}

class _OrgAdminApprovalsView extends StatelessWidget {
  const _OrgAdminApprovalsView();

  Future<void> _confirmReject(BuildContext context, ApprovalRequest request) async {
    final controller = TextEditingController();
    final cubit = context.read<OrgAdminApprovalsCubit>();
    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Reject "${request.title}"'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Add a reason for the requester (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (message != null) {
      cubit.reject(request.id, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Org Admin · Approvals')),
      body: SafeArea(
        child: BlocBuilder<OrgAdminApprovalsCubit, OrgAdminApprovalsState>(
          builder: (context, state) {
            if (state.status == OrgAdminApprovalsStatus.initial ||
                state.status == OrgAdminApprovalsStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == OrgAdminApprovalsStatus.error) {
              return Center(child: Text(state.errorMessage ?? 'Something went wrong.'));
            }
            if (state.requests.isEmpty) {
              return const EmptyState(
                title: 'All caught up',
                message: 'There are no pending approval requests right now.',
                icon: Icons.task_alt_outlined,
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<OrgAdminApprovalsCubit>().loadRequests(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: state.requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final request = state.requests[index];
                  final isProcessing = state.processingId == request.id;
                  return AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(request.title, style: Theme.of(context).textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          '${request.requester} · ${request.submittedAgo}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Text(request.detail, style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: AppSpacing.sm),
                        if (isProcessing)
                          const Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: () => _confirmReject(context, request),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton(
                                onPressed: () =>
                                    context.read<OrgAdminApprovalsCubit>().approve(request.id),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}