import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Policies & Approval Rules
///
/// Read-only for this role by design — EMs view and acknowledge org
/// policies here, they don't edit them. TODO: swap `_policies` for a
/// real fetch from your policy service once available.
class PoliciesApprovalRulesScreen extends StatefulWidget {
  const PoliciesApprovalRulesScreen({super.key});

  @override
  State<PoliciesApprovalRulesScreen> createState() =>
      _PoliciesApprovalRulesScreenState();
}

class _Policy {
  const _Policy({
    required this.icon,
    required this.title,
    required this.summary,
    required this.fullText,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String fullText;
}

class _PoliciesApprovalRulesScreenState
    extends State<PoliciesApprovalRulesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;
  static const _blockCount = 3;

  static const _policies = [
    _Policy(
      icon: Icons.smart_toy_outlined,
      title: 'AI Tool Usage Policy',
      summary:
          'Approved AI coding assistants, data-handling rules, and review requirements.',
      fullText: 'Engineers may use approved AI coding assistants for drafting, '
          'refactoring, and test generation. Do not paste proprietary source, '
          'customer data, or credentials into any AI tool that is not on the '
          'approved vendor list. All AI-generated code must still go through '
          'normal code review before merging. Contact Platform Engineering to '
          'request evaluation of a new tool.',
    ),
    _Policy(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Budget Approval Thresholds',
      summary: 'Who needs to approve a purchase, based on request amount.',
      fullText:
          'Requests are routed for approval based on amount. Smaller requests '
          'route to your Engineering Manager, mid-size requests require '
          'Manager + Finance sign-off, and larger requests require Executive '
          'approval. See the exact thresholds below.',
    ),
    _Policy(
      icon: Icons.shopping_cart_outlined,
      title: 'Purchase / Procurement Policy',
      summary: 'Steps for requesting and procuring new software or tools.',
      fullText:
          'All new software purchases must go through the procurement request '
          'form, including a business justification and expected monthly '
          'cost. Security review is required for any tool that will access '
          'company code or customer data before it can be approved.',
    ),
  ];

  static const _thresholds = [
    (label: 'Under', amount: 10000.0, approver: 'Engineering Manager'),
    (label: '10,000 – 50,000', amount: 50000.0, approver: 'Manager + Finance'),
    (label: 'Above', amount: 50000.0, approver: 'Executive Approval'),
  ];

  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    WidgetsBinding.instance.addPostFrameCallback((_) => _entrance.forward());
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return EmScreenScaffold(
      title: 'Policies & Approval Rules',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Org-level policies you follow as an Engineering Manager. These '
            'are set centrally — reach out to your admin to request an '
            'exception.',
            style:
                AppTypography.body(colors.textSecondary).copyWith(height: 1.4),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _policies.length; i++) ...[
            StaggeredFade(
              index: i,
              total: _blockCount,
              controller: _entrance,
              child: _PolicyAccordion(
                policy: _policies[i],
                expanded: _expandedIndex == i,
                onTap: () => setState(
                    () => _expandedIndex = _expandedIndex == i ? null : i),
                trailing: i == 1
                    ? _ThresholdMiniTable(thresholds: _thresholds)
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _PolicyAccordion extends StatelessWidget {
  const _PolicyAccordion({
    required this.policy,
    required this.expanded,
    required this.onTap,
    this.trailing,
  });

  final _Policy policy;
  final bool expanded;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
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
                        color: colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(policy.icon, size: 18, color: colors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(policy.title,
                              style:
                                  AppTypography.bodyLarge(colors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            policy.summary,
                            maxLines: expanded ? null : 1,
                            overflow: expanded ? null : TextOverflow.ellipsis,
                            style: AppTypography.caption(colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down,
                          color: colors.textSecondary),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                policy.fullText,
                                style: AppTypography.body(colors.textSecondary)
                                    .copyWith(height: 1.5),
                              ),
                              if (trailing != null) ...[
                                const SizedBox(height: AppSpacing.md),
                                trailing!,
                              ],
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  '${policy.title} acknowledged.')),
                                        );
                                      },
                                      child: const Text('Acknowledge'),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        // TODO: wire to your real exception-request flow.
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Exception request sent for ${policy.title}.')),
                                        );
                                      },
                                      child: const Text('Request exception'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThresholdMiniTable extends StatelessWidget {
  const _ThresholdMiniTable({required this.thresholds});
  final List<({String label, double amount, String approver})> thresholds;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          for (final t in thresholds)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${t.label} ',
                            style: AppTypography.caption(colors.textPrimary)),
                        RupeeAmount(
                          amount: t.amount,
                          style: AppTypography.caption(colors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward,
                      size: 12, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(t.approver,
                      style: AppTypography.caption(colors.primary)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

