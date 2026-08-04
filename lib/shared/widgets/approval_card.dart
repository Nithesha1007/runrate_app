import 'package:flutter/material.dart';
import 'app_card.dart';
import '../models/approval_model.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';

class ApprovalCard extends StatelessWidget {
  final ApprovalModel approval;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const ApprovalCard({super.key, required this.approval, this.onApprove, this.onReject});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(approval.title, style: theme.textTheme.headlineSmall)),
              Text(Formatters.currency(approval.amount), style: theme.textTheme.headlineSmall),
            ],
          ),
          const SizedBox(height: 4),
          Text('\${approval.requesterName} · \${approval.category}', style: theme.textTheme.bodyMedium),
          if (onApprove != null && onReject != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
