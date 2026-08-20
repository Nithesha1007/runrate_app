import 'package:flutter/material.dart';
import 'package:runrate/core/constants/app_spacing.dart';
import 'package:runrate/core/theme/app_colors.dart';
import 'package:runrate/core/theme/app_colors_data.dart';
import 'package:runrate/core/theme/app_typography.dart';
import 'package:runrate/features/roles/engineering_manager/more/shared/widget/em_screen_scaffold.dart';
import '../em_shared_widget.dart';
import 'package:runrate/shared/widgets/staggered.dart';

/// More → Policies & Approval Rules
///
/// Read-only for this role by design — EMs view org policies here, they
/// don't edit them. Org-controlled data is centrally managed; when a real
/// policy service is available, swap `_loadPolicies()` for the actual
/// fetch and keep the loading/error contract the same.
class PoliciesApprovalRulesScreen extends StatefulWidget {
  const PoliciesApprovalRulesScreen({super.key});

  @override
  State<PoliciesApprovalRulesScreen> createState() =>
      _PoliciesApprovalRulesScreenState();
}

// ---------------------------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------------------------

enum PolicyStatus { active, warning, restricted }

extension on PolicyStatus {
  String get label => switch (this) {
        PolicyStatus.active => 'Active',
        PolicyStatus.warning => 'Exception',
        PolicyStatus.restricted => 'Restricted',
      };

  Color color(AppColorsData colors) => switch (this) {
        PolicyStatus.active => colors.success,
        PolicyStatus.warning => colors.warning,
        PolicyStatus.restricted => colors.danger,
      };

  IconData get icon => switch (this) {
        PolicyStatus.active => Icons.check_circle_rounded,
        PolicyStatus.warning => Icons.error_rounded,
        PolicyStatus.restricted => Icons.block_rounded,
      };
}

enum _PolicyActionType { contactAdmin, requestException }

class _PolicyDetail {
  const _PolicyDetail(this.label, this.value);
  final String label;
  final String value;
}

class _Policy {
  const _Policy({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.metadata,
    required this.metadataIcon,
    required this.details,
    required this.owner,
    required this.lastUpdated,
    required this.restrictionSummary,
    required this.actionType,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String description;
  final PolicyStatus status;
  final String metadata;
  final IconData metadataIcon;
  final List<_PolicyDetail> details;
  final String owner;
  final String lastUpdated;

  /// Shown read-only inside the exception/contact sheet, so the requester
  /// sees exactly what they're asking to deviate from.
  final String restrictionSummary;
  final _PolicyActionType actionType;

  /// Optional extra widget rendered inside the expanded content (used for
  /// the budget threshold table).
  final Widget? trailing;

  String get actionLabel => actionType == _PolicyActionType.contactAdmin
      ? 'Contact Admin'
      : 'Request Exception';
}

enum _LoadState { loading, loaded, error }

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class _PoliciesApprovalRulesScreenState
    extends State<PoliciesApprovalRulesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  _LoadState _loadState = _LoadState.loading;
  List<_Policy> _policies = const [];
  int? _expandedIndex;

  static const _thresholds = [
    (label: 'Under', amount: 10000.0, approver: 'Engineering Manager'),
    (label: '10,000 – 50,000', amount: 50000.0, approver: 'Manager + Finance'),
    (label: 'Above', amount: 50000.0, approver: 'Executive Approval'),
  ];

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loadState = _LoadState.loading);
    try {
      // TODO: replace with the real policy-service fetch. The short delay
      // here just keeps the skeleton state visible briefly so it isn't
      // imperceptible on fast connections.
      await Future.delayed(const Duration(milliseconds: 450));
      final policies = _buildPolicies();
      if (!mounted) return;
      setState(() {
        _policies = policies;
        _loadState = _LoadState.loaded;
      });
      _entrance.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadState = _LoadState.error);
    }
  }

  List<_Policy> _buildPolicies() => [
        _Policy(
          icon: Icons.smart_toy_outlined,
          title: 'AI Tool Usage Policy',
          description:
              'Approved AI tools, data handling, security and usage requirements',
          status: PolicyStatus.active,
          metadata: 'Last updated: 2 days ago',
          metadataIcon: Icons.schedule_rounded,
          owner: 'Platform Engineering',
          lastUpdated: '2 days ago',
          restrictionSummary:
              'Only vendor-approved AI tools may be used, and no proprietary '
              'source, customer data, or credentials may be shared with them.',
          actionType: _PolicyActionType.contactAdmin,
          details: const [
            _PolicyDetail('Approved Tools',
                'Claude, GitHub Copilot, ChatGPT Enterprise — full list in the Admin console'),
            _PolicyDetail('Data Handling',
                'No proprietary source, customer data, or credentials may be pasted into any non-approved tool'),
            _PolicyDetail('Sensitive Data Restrictions',
                'PII, financial records, and security keys must never be shared with AI tools'),
            _PolicyDetail('Security Requirements',
                'SSO is required; approved tools must support enterprise data-retention controls'),
            _PolicyDetail('Personal AI Tools',
                'Personal or consumer AI accounts may not be used for company work'),
          ],
        ),
        _Policy(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget Approval Thresholds',
          description:
              'Approval limits and escalation rules for team purchases',
          status: PolicyStatus.active,
          metadata: 'Applies to: Engineering',
          metadataIcon: Icons.groups_outlined,
          owner: 'Finance Operations',
          lastUpdated: '12 days ago',
          restrictionSummary:
              'Purchases above ₹10,000/mo require Manager + Finance approval, '
              'and above ₹50,000/mo require Executive approval.',
          actionType: _PolicyActionType.requestException,
          details: const [
            _PolicyDetail('Manager approval limit', 'Up to ₹10,000 / month'),
            _PolicyDetail(
                'Finance approval threshold', '₹10,000 – ₹50,000 / month'),
            _PolicyDetail(
                'Executive approval threshold', 'Above ₹50,000 / month'),
            _PolicyDetail('Monthly team budget rule',
                'Team spend is capped at the budget Finance sets each quarter'),
            _PolicyDetail('Emergency purchase rule',
                'Emergency requests can be fast-tracked, but require retroactive Finance sign-off within 5 business days'),
            _PolicyDetail('Escalation required',
                'Any request exceeding the team\'s monthly budget requires Executive approval regardless of amount'),
          ],
          trailing: _ThresholdMiniTable(thresholds: _thresholds),
        ),
        _Policy(
          icon: Icons.shopping_cart_outlined,
          title: 'Purchase / Procurement Policy',
          description:
              'Rules for requesting, reviewing and purchasing software and services',
          status: PolicyStatus.active,
          metadata: 'Approval required',
          metadataIcon: Icons.verified_user_outlined,
          owner: 'Procurement Team',
          lastUpdated: '1 month ago',
          restrictionSummary:
              'All software purchases must go through the procurement request '
              'form with security and finance review before approval.',
          actionType: _PolicyActionType.requestException,
          details: const [
            _PolicyDetail('Purchase request requirement',
                'All software purchases must go through the procurement request form'),
            _PolicyDetail('Vendor approval',
                'Vendor must be on the approved vendor list or pass a new-vendor review'),
            _PolicyDetail('Security review',
                'Required for any tool accessing company code, infrastructure, or customer data'),
            _PolicyDetail('Finance review',
                'Required for annual commitments or purchases above the manager threshold'),
            _PolicyDetail('Contract requirements',
                'Contracts must be routed through Legal before signature'),
            _PolicyDetail('Renewal requirements',
                'Renewals must be reviewed at least 30 days before the contract end date'),
          ],
        ),
      ];

  Future<void> _openActionSheet(_Policy policy) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PolicyActionSheet(policy: policy),
    );
    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            policy.actionType == _PolicyActionType.contactAdmin
                ? 'Message sent to admin about ${policy.title}.'
                : 'Exception request submitted for ${policy.title}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return EmScreenScaffold(
      title: 'Policies & Approval Rules',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PolicyHeader(),
          const SizedBox(height: AppSpacing.lg),
          switch (_loadState) {
            _LoadState.loading => const _PolicySkeletonList(),
            _LoadState.error => _PolicyErrorState(onRetry: _load),
            _LoadState.loaded => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < _policies.length; i++) ...[
                    StaggeredFade(
                      index: i,
                      total: _policies.length,
                      controller: _entrance,
                      child: _PolicyCard(
                        policy: _policies[i],
                        expanded: _expandedIndex == i,
                        onTap: () => setState(() =>
                            _expandedIndex = _expandedIndex == i ? null : i),
                        onAction: () => _openActionSheet(_policies[i]),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
          },
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HEADER — subtitle + "Organization controlled" status badge.
// ---------------------------------------------------------------------------

class _PolicyHeader extends StatelessWidget {
  const _PolicyHeader();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Organization policies and approval requirements',
            style:
                AppTypography.body(colors.textSecondary).copyWith(height: 1.4),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colors.primary.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 12, color: colors.primary),
              const SizedBox(width: 4),
              Text(
                'Org controlled',
                style: AppTypography.caption(colors.primary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// POLICY CARD
// ---------------------------------------------------------------------------

class _PolicyCard extends StatefulWidget {
  const _PolicyCard({
    required this.policy,
    required this.expanded,
    required this.onTap,
    required this.onAction,
  });

  final _Policy policy;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onAction;

  @override
  State<_PolicyCard> createState() => _PolicyCardState();
}

class _PolicyCardState extends State<_PolicyCard> {
  double _scale = 1;

  void _setPressed(bool pressed) => setState(() => _scale = pressed ? 0.985 : 1);

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final policy = widget.policy;
    final statusColor = policy.status.color(colors);

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: widget.expanded
                  ? colors.primary.withValues(alpha: 0.28)
                  : colors.border,
              width: widget.expanded ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withValues(alpha: 0.16),
                          colors.secondary.withValues(alpha: 0.10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(policy.icon, size: 20, color: colors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                policy.title,
                                style:
                                    AppTypography.bodyLarge(colors.textPrimary)
                                        .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          policy.description,
                          style: AppTypography.caption(colors.textSecondary)
                              .copyWith(height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AnimatedRotation(
                    turns: widget.expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _StatusBadge(status: policy.status),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(policy.metadataIcon,
                      size: 12, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      policy.metadata,
                      style: AppTypography.caption(colors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: widget.expanded
                    ? _PolicyExpandedContent(
                        policy: policy,
                        statusColor: statusColor,
                        onAction: widget.onAction,
                      )
                    : const SizedBox(width: double.infinity, height: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final PolicyStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final color = status.color(colors);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(status),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              status.label,
              style: AppTypography.caption(color)
                  .copyWith(fontWeight: FontWeight.w700, fontSize: 10.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXPANDED CONTENT
// ---------------------------------------------------------------------------

class _PolicyExpandedContent extends StatelessWidget {
  const _PolicyExpandedContent({
    required this.policy,
    required this.statusColor,
    required this.onAction,
  });

  final _Policy policy;
  final Color statusColor;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1, color: colors.border),
          const SizedBox(height: AppSpacing.md),
          for (final d in policy.details) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.label,
                    style: AppTypography.caption(colors.textPrimary)
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.value,
                    style: AppTypography.caption(colors.textSecondary)
                        .copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
          ],
          if (policy.trailing != null) ...[
            const SizedBox(height: AppSpacing.xs),
            policy.trailing!,
            const SizedBox(height: AppSpacing.md),
          ],
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 14, color: colors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No active exceptions for this policy.',
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        policy.owner,
                        style: AppTypography.caption(colors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(Icons.update_rounded,
                      size: 13, color: colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Updated ${policy.lastUpdated}',
                    style: AppTypography.caption(colors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PolicyActionButton(
            label: policy.actionLabel,
            icon: policy.actionType == _PolicyActionType.contactAdmin
                ? Icons.support_agent_rounded
                : Icons.rule_folder_outlined,
            onTap: onAction,
          ),
        ],
      ),
    );
  }
}

class _PolicyActionButton extends StatefulWidget {
  const _PolicyActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_PolicyActionButton> createState() => _PolicyActionButtonState();
}

class _PolicyActionButtonState extends State<_PolicyActionButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapCancel: () => setState(() => _scale = 1),
      onTapUp: (_) => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: AppTypography.caption(colors.primary)
                    .copyWith(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// BUDGET THRESHOLD MINI TABLE
// ---------------------------------------------------------------------------

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
          for (var i = 0; i < thresholds.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Divider(height: 1, color: colors.border),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${thresholds[i].label} ',
                            style: AppTypography.caption(colors.textPrimary)),
                        RupeeAmount(
                          amount: thresholds[i].amount,
                          style: AppTypography.caption(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_rounded,
                      size: 12, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(thresholds[i].approver,
                      style: AppTypography.caption(colors.primary)
                          .copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// EXCEPTION REQUEST / CONTACT ADMIN BOTTOM SHEET
// ---------------------------------------------------------------------------

class _PolicyActionSheet extends StatefulWidget {
  const _PolicyActionSheet({required this.policy});
  final _Policy policy;

  @override
  State<_PolicyActionSheet> createState() => _PolicyActionSheetState();
}

class _PolicyActionSheetState extends State<_PolicyActionSheet> {
  final _detailsController = TextEditingController();
  String? _reason;
  bool _showReasonError = false;

  bool get _isContactAdmin =>
      widget.policy.actionType == _PolicyActionType.contactAdmin;

  List<String> get _reasonOptions => _isContactAdmin
      ? const [
          'Clarify policy',
          'Report an issue',
          'Request a tool addition',
          'Other',
        ]
      : const [
          'Business need',
          'Time-sensitive project',
          'Client requirement',
          'Other',
        ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reason == null) {
      setState(() => _showReasonError = true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final policy = widget.policy;

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      _isContactAdmin
                          ? Icons.support_agent_rounded
                          : Icons.rule_folder_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          policy.actionLabel,
                          style: AppTypography.bodyLarge(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          policy.title,
                          style: AppTypography.caption(colors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            size: 13, color: colors.textSecondary),
                        const SizedBox(width: 5),
                        Text(
                          'Current policy restriction',
                          style: AppTypography.caption(colors.textSecondary)
                              .copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      policy.restrictionSummary,
                      style: AppTypography.caption(colors.textSecondary)
                          .copyWith(height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _isContactAdmin
                    ? 'Reason for contacting admin'
                    : 'Reason for exception',
                style: AppTypography.caption(colors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                isExpanded: true,
                borderRadius: BorderRadius.circular(12),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  errorText: _showReasonError ? 'Select a reason' : null,
                  hintText: 'Select a reason',
                  hintStyle: AppTypography.caption(colors.textSecondary),
                ),
                items: [
                  for (final r in _reasonOptions)
                    DropdownMenuItem(
                      value: r,
                      child: Text(r, style: AppTypography.body(colors.textPrimary)),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _reason = v;
                  _showReasonError = false;
                }),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Additional details (optional)',
                style: AppTypography.caption(colors.textPrimary)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _detailsController,
                maxLines: 3,
                style: AppTypography.body(colors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colors.background,
                  contentPadding: const EdgeInsets.all(12),
                  hintText: _isContactAdmin
                      ? 'Add any context that would help the admin...'
                      : 'Add any context that supports this request...',
                  hintStyle: AppTypography.caption(colors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: colors.border),
                      ),
                      child: Text('Cancel',
                          style: AppTypography.body(colors.textPrimary)
                              .copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isContactAdmin ? 'Send Message' : 'Submit Request',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13.5),
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

// ---------------------------------------------------------------------------
// LOADING / ERROR STATES
// ---------------------------------------------------------------------------

class _PolicySkeletonList extends StatelessWidget {
  const _PolicySkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++) ...[
          const _PolicySkeletonCard(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _PolicySkeletonCard extends StatefulWidget {
  const _PolicySkeletonCard();

  @override
  State<_PolicySkeletonCard> createState() => _PolicySkeletonCardState();
}
  
class _PolicySkeletonCardState extends State<_PolicySkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final alpha = 0.5 + (_controller.value * 0.25);
        return Container(
          height: 116,
          decoration: BoxDecoration(
            color: colors.surfaceElevated.withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 8),
                    Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(
                        height: 10,
                        width: 200,
                        decoration: BoxDecoration(
                            color: colors.border,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PolicyErrorState extends StatelessWidget {
  const _PolicyErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 32, color: colors.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Policies unavailable',
              style: AppTypography.h3(colors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Something went wrong while loading organization policies.',
            style: AppTypography.body(colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}