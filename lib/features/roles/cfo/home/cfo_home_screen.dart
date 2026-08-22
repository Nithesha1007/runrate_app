import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../core/constants/app_spacing.dart';
import 'cfo_home_cubit.dart';

/// CFO · Home
/// Dashboard with financial health, expense breakdown, pending invoices
/// (approve / reject), and budget vs actual — wired to [CfoHomeCubit].
///
/// Note: bottom navigation (Home / AI / Teams / Approvals / More) is
/// assumed to live in the parent tab shell, not in this screen, so it
/// isn't duplicated here.
class CfoHomeScreen extends StatelessWidget {
  const CfoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CfoHomeCubit(),
      child: const _CfoHomeView(),
    );
  }
}

class _CfoHomeView extends StatelessWidget {
  const _CfoHomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CfoHomeCubit, CfoHomeState>(
          builder: (context, state) {
            if (state is CfoHomeLoading || state is CfoHomeInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CfoHomeError) {
              return _ErrorView(
                message: state.message,
                onRetry: () => context.read<CfoHomeCubit>().loadDashboard(),
              );
            }

            final loaded = state as CfoHomeLoaded;
            return RefreshIndicator(
              onRefresh: () => context.read<CfoHomeCubit>().refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(data: loaded.data),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: _FinancialHealthCard(
                          health: loaded.data.financialHealth),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: AppCard(
                        child: _ExpenseBreakdownSection(
                            items: loaded.data.expenseBreakdown),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: AppCard(
                        child: _PendingInvoicesSection(
                          invoices: loaded.data.pendingInvoices,
                          actionInFlightId: loaded.invoiceActionInFlightId,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: AppCard(
                        child: _BudgetVsActualSection(
                            lines: loaded.data.budgetLines),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Header — avatar, greeting, notification bell
/// ---------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.data});

  final CfoHomeData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              data.userInitials,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning', style: theme.textTheme.bodySmall),
                Text(
                  data.userName,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (data.pendingInvoices.isNotEmpty)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      shape: BoxShape.circle,
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

/// ---------------------------------------------------------------------
/// Financial health card
/// ---------------------------------------------------------------------

class _FinancialHealthCard extends StatelessWidget {
  const _FinancialHealthCard({required this.health});

  final FinancialHealth health;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const onDark = Colors.white;
    const onDarkMuted = Colors.white70;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Financial health',
              style: theme.textTheme.labelMedium?.copyWith(color: onDarkMuted)),
          const SizedBox(height: 2),
          Text(
            'Updated ${_formatUpdatedAt(health.updatedAt)}',
            style: theme.textTheme.labelSmall?.copyWith(color: onDarkMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _HealthMetric(
                    label: 'Cash balance',
                    value: formatInr(health.cashBalance),
                    color: onDark,
                    mutedColor: onDarkMuted),
              ),
              Expanded(
                child: _HealthMetric(
                  label: 'Burn rate',
                  value: '${formatInr(health.burnRatePerMonth)}/mo',
                  color: onDark,
                  mutedColor: onDarkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _HealthMetric(
                  label: 'Runway',
                  value: '${health.runwayMonths.toStringAsFixed(1)} mo',
                  color: onDark,
                  mutedColor: onDarkMuted,
                ),
              ),
              Expanded(
                child: _HealthMetric(
                    label: 'MRR',
                    value: formatInr(health.mrr),
                    color: onDark,
                    mutedColor: onDarkMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatUpdatedAt(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return 'today, $hour:$minute $period';
  }
}

class _HealthMetric extends StatelessWidget {
  const _HealthMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.mutedColor,
  });

  final String label;
  final String value;
  final Color color;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.labelSmall?.copyWith(color: mutedColor)),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.titleMedium
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Expense breakdown
/// ---------------------------------------------------------------------

class _ExpenseBreakdownSection extends StatelessWidget {
  const _ExpenseBreakdownSection({required this.items});

  final List<ExpenseCategory> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = [
      theme.colorScheme.primary,
      Colors.teal,
      Colors.amber.shade700,
      Colors.pink.shade300,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Expense breakdown',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < items.length; i++) ...[
          _ExpenseBar(item: items[i], color: palette[i % palette.length]),
          if (i != items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ExpenseBar extends StatelessWidget {
  const _ExpenseBar({required this.item, required this.color});

  final ExpenseCategory item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.label, style: theme.textTheme.bodySmall),
            Text(formatInr(item.amount), style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: item.shareOfTotal.clamp(0, 1),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Pending invoices
/// ---------------------------------------------------------------------

class _PendingInvoicesSection extends StatelessWidget {
  const _PendingInvoicesSection(
      {required this.invoices, this.actionInFlightId});

  final List<PendingInvoice> invoices;
  final String? actionInFlightId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Pending invoices',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('${invoices.length} waiting',
                style: theme.textTheme.bodySmall),
          ],
        ),
        if (invoices.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('All caught up — no invoices waiting on you.',
                style: theme.textTheme.bodySmall),
          )
        else
          for (final invoice in invoices)
            _InvoiceRow(
              invoice: invoice,
              isBusy: actionInFlightId == invoice.id,
            ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice, required this.isBusy});

  final PendingInvoice invoice;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = Colors.green.shade600;
    final danger = theme.colorScheme.error;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border:
            Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.vendorName,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatInr(invoice.amount)} · due in ${invoice.dueInDays} ${invoice.dueInDays == 1 ? 'day' : 'days'}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (isBusy)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else ...[
            _CircleIconButton(
              icon: Icons.check,
              backgroundColor: success.withValues(alpha: 0.15),
              iconColor: success,
              tooltip: 'Approve',
              onPressed: () =>
                  context.read<CfoHomeCubit>().approveInvoice(invoice.id),
            ),
            const SizedBox(width: AppSpacing.xs),
            _CircleIconButton(
              icon: Icons.close,
              backgroundColor: danger.withValues(alpha: 0.12),
              iconColor: danger,
              tooltip: 'Reject',
              onPressed: () => _confirmReject(context, invoice),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmReject(
      BuildContext context, PendingInvoice invoice) async {
    final cubit = context.read<CfoHomeCubit>();
    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Reject ${invoice.vendorName}?'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              hintText: 'Let the vendor know why',
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      cubit.rejectInvoice(invoice.id, reason: reason.isEmpty ? null : reason);
    }
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: iconColor),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Budget vs actual
/// ---------------------------------------------------------------------

class _BudgetVsActualSection extends StatelessWidget {
  const _BudgetVsActualSection({required this.lines});

  final List<BudgetLine> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final success = Colors.green.shade600;
    final danger = theme.colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget vs actual · this quarter',
          style:
              theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < lines.length; i++) ...[
          _BudgetRow(
              line: lines[i], onTrackColor: success, overBudgetColor: danger),
          if (i != lines.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow(
      {required this.line,
      required this.onTrackColor,
      required this.overBudgetColor});

  final BudgetLine line;
  final Color onTrackColor;
  final Color overBudgetColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = line.isOverBudget ? overBudgetColor : onTrackColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(line.department, style: theme.textTheme.bodySmall),
            Text(
              '${formatInr(line.actual)} / ${formatInr(line.budgeted)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (line.progress > 1 ? 1 : line.progress).toDouble(),
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
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
            Icon(Icons.error_outline,
                size: 40, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
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
