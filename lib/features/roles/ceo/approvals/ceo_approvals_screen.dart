import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/ceo_mock_repository.dart';
import 'ceo_approvals_cubit.dart';
import 'ceo_approvals_state.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../features/notifications/notifications_cubit.dart';
import '../../../../shared/widgets/approval_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/reject_request_sheet.dart';
import '../../../../shared/widgets/reveal.dart';
import '../../../../shared/widgets/toast.dart';

/// CEO · Approvals — pending spend requests. Approve completes instantly;
/// Reject opens the shared reject-with-message bottom sheet.
///
/// Only change vs. original: each ApprovalCard now enters with a staggered
/// fade/slide-in via the shared `Reveal` widget, matching Home's polish.
/// Approve/Reject logic, cubit wiring, and models are untouched.
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

class _CeoApprovalsView extends StatelessWidget {
  const _CeoApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approvals')),
      body: BlocBuilder<CeoApprovalsCubit, CeoApprovalsState>(
        builder: (context, state) {
          if (state.loading) {
            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.xl),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, __) => const SkeletonLoader(height: 120),
            );
          }
          final pending = state.pending;
          if (pending.isEmpty) {
            return const EmptyState(
              title: 'All caught up',
              message: 'No pending approvals right now.',
              icon: Icons.check_circle_outline,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, i) {
              final approval = pending[i];
              return Reveal(
                delayMs: i * 50,
                child: ApprovalCard(
                  approval: approval,
                  onApprove: () {
                    context.read<CeoApprovalsCubit>().approve(approval.id);
                    showAppToast(context, 'Approved "${approval.title}"');
                  },
                  onReject: () async {
                    final message = await showRejectRequestSheet(context,
                        requesterName: approval.requesterName);
                    if (message != null && context.mounted) {
                      context
                          .read<CeoApprovalsCubit>()
                          .reject(approval.id, message);
                      showAppToast(context,
                          'Rejected and notified ${approval.requesterName}');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}