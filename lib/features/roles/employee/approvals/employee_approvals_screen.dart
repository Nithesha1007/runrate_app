import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../core/constants/app_spacing.dart';

import 'employee_approvals_cubit.dart';

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

extension _EmployeeApprovalsThemeExtensions on BuildContext {
  Color get scaffoldColor => Theme.of(this).scaffoldBackgroundColor;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get mutedTextColor =>
      Theme.of(this).textTheme.bodyMedium?.color ?? Colors.grey;
  Color get borderColor => Theme.of(this).dividerColor;
}

/// Employee · Approvals
/// Pending requests with approve / reject-with-message flow.
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

class _EmployeeApprovalsView extends StatelessWidget {
  const _EmployeeApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldColor,
      appBar: AppBar(title: const Text('Approvals')),
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
              return const Center(child: CircularProgressIndicator());
            }
            if (state.hasError && state.requests.isEmpty) {
              return EmptyState(
                title: 'Something went wrong',
                message: state.errorMessage ?? 'Please try again.',
                icon: Icons.error_outline,
              );
            }

            final pending = state.pending;
            if (pending.isEmpty) {
              return const EmptyState(
                title: 'All caught up',
                message: 'You have no pending approvals right now.',
                icon: Icons.task_alt_outlined,
              );
            }

            return RefreshIndicator(
              onRefresh: () =>
                  context.read<EmployeeApprovalsCubit>().loadRequests(),
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.xl),
                itemCount: pending.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final request = pending[index];
                  return _ApprovalCard(
                    request: request,
                    isProcessing: state.processingIds.contains(request.id),
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

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({required this.request, required this.isProcessing});

  final ApprovalRequest request;
  final bool isProcessing;

  String get _typeLabel {
    switch (request.type) {
      case ApprovalRequestType.leave:
        return 'Leave request';
      case ApprovalRequestType.expense:
        return 'Expense';
      case ApprovalRequestType.purchase:
        return 'Purchase';
    }
  }

  Future<void> _rejectWithMessage(BuildContext context) async {
    final cubit = context.read<EmployeeApprovalsCubit>();
    final controller = TextEditingController();

    final message = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reject request'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Add a reason for the requester...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (message != null && message.isNotEmpty) {
      await cubit.reject(request.id, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: context.primaryColor.withOpacity(0.12),
                child: Text(
                  request.requesterName.isNotEmpty
                      ? request.requesterName[0].toUpperCase()
                      : '?',
                  style: appFontStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
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
                      style: appFontStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _typeLabel,
                      style: appFontStyle(
                          fontSize: 11, color: context.mutedTextColor),
                    ),
                  ],
                ),
              ),
              Text(
                DateFormat('d MMM').format(request.submittedAt),
                style:
                    appFontStyle(fontSize: 11, color: context.mutedTextColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(request.summary, style: appFontStyle(fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          if (isProcessing)
            const Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectWithMessage(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: appFontStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context
                        .read<EmployeeApprovalsCubit>()
                        .approve(request.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Approve',
                      style: appFontStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
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
