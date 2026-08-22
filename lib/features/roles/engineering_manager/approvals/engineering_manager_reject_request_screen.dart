import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'pending_requests_repository.dart';
import 'engineering_manager_approval_actions.dart';

/// Full-screen reject request flow.
/// Returns the rejection reason (String) on submit, or null if dismissed.
class RejectRequestScreen extends StatefulWidget {
  const RejectRequestScreen({required this.request, super.key});

  final PendingRequestData request;

  @override
  State<RejectRequestScreen> createState() => _RejectRequestScreenState();
}

class _RejectRequestScreenState extends State<RejectRequestScreen> {
  late TextEditingController _reasonController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRejection() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rejection reason')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.of(context).pop(reason);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final request = widget.request;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: colors.textPrimary),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Reject Request',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Summary Card
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.border, width: 1),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.employeeName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              request.employeeRole.isNotEmpty
                                  ? request.employeeRole
                                  : 'Employee',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: priorityColor(context, request.priority)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                priorityIcon(request.priority),
                                size: 14,
                                color: priorityColor(context, request.priority),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                request.priority.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: priorityColor(
                                          context, request.priority),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colors.border, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tool Requested',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              request.requestedTool,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Monthly Cost',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            CurrencyLabel(request.monthlyCost),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Justification',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.justification,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textPrimary,
                          ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Rejection Reason Input
              Text(
                'Rejection Reason',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                enabled: !_isSubmitting,
                maxLines: 5,
                minLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Provide a reason for rejection...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textSecondary,
                      ),
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border, width: 1),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colors.border, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submitRejection,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.danger,
                        disabledBackgroundColor: colors.danger.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colors.surface,
                                ),
                              ),
                            )
                          : Text(
                              'Reject',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: colors.surface,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
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

