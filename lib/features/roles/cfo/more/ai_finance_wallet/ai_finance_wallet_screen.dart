import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kPrimaryLight = Color(0xFFEDE9FE);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 18.0;

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

class BudgetSummary {
  const BudgetSummary({
    required this.periodLabel,
    required this.consumed,
    required this.totalLimit,
    required this.remainingRunwayMonths,
    required this.burnRatePerMonth,
  });

  final String periodLabel;
  final double consumed;
  final double totalLimit;
  final double remainingRunwayMonths;
  final double burnRatePerMonth;

  double get utilizationRatio => totalLimit == 0 ? 0 : (consumed / totalLimit).clamp(0, 1);
}

class DepartmentSpend {
  const DepartmentSpend({
    required this.name,
    required this.spent,
    required this.limit,
    required this.barColor,
  });

  final String name;
  final double spent;
  final double limit;
  final Color barColor;

  double get ratio => limit == 0 ? 0 : (spent / limit).clamp(0, 1);
}

class WalletTransaction {
  const WalletTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.dateLabel,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
  });

  final String title;
  final String subtitle;
  final double amount;
  final String dateLabel;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
}

/// ---------------------------------------------------------------------
/// Screen
/// ---------------------------------------------------------------------

class AiFinanceWalletScreen extends StatelessWidget {
  AiFinanceWalletScreen({
    super.key,
    BudgetSummary? summary,
    List<DepartmentSpend>? departments,
    List<WalletTransaction>? transactions,
  })  : summary = summary ?? _mockSummary,
        departments = departments ?? _mockDepartments,
        transactions = transactions ?? _mockTransactions;

  final BudgetSummary summary;
  final List<DepartmentSpend> departments;
  final List<WalletTransaction> transactions;

  static const _mockSummary = BudgetSummary(
    periodLabel: 'Oct 2023 - Sep 2024',
    consumed: 2380000,
    totalLimit: 3100000,
    remainingRunwayMonths: 2.4,
    burnRatePerMonth: 310000,
  );

  static const _mockDepartments = [
    DepartmentSpend(name: 'Engineering', spent: 1200000, limit: 1500000, barColor: _kPrimary),
    DepartmentSpend(name: 'Marketing', spent: 600000, limit: 650000, barColor: Color(0xFFE07A2E)),
    DepartmentSpend(name: 'Product', spent: 350000, limit: 500000, barColor: Color(0xFF3B82F6)),
    DepartmentSpend(name: 'Sales', spent: 230000, limit: 450000, barColor: Color(0xFF6B7280)),
  ];

  static const _mockTransactions = [
    WalletTransaction(
      title: 'OpenAI Enterprise',
      subtitle: 'Annual Renewal • Engineering',
      amount: 45000,
      dateLabel: 'Today',
      icon: Icons.smart_toy_outlined,
      iconColor: _kPrimary,
      iconBackgroundColor: _kPrimaryLight,
    ),
    WalletTransaction(
      title: 'GitHub Copilot',
      subtitle: '200 Seats • Engineering',
      amount: 3800,
      dateLabel: 'Yesterday',
      icon: Icons.code,
      iconColor: Colors.black87,
      iconBackgroundColor: Color(0xFFF1F1F5),
    ),
    WalletTransaction(
      title: 'Midjourney Pro',
      subtitle: '50 Seats • Marketing',
      amount: 3000,
      dateLabel: 'Oct 24',
      icon: Icons.brush_outlined,
      iconColor: Color(0xFFE5484D),
      iconBackgroundColor: Color(0xFFFDEBEC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: _buildAppBar(context),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          children: [
            const Text(
              'AI Finance Wallet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              'Enterprise Budget Management & Oversight',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 18),
            _BudgetCard(summary: summary),
            const SizedBox(height: 16),
            _CfoActionsCard(),
            const SizedBox(height: 16),
            _DepartmentalBreakdownCard(departments: departments),
            const SizedBox(height: 16),
            _HighValueTransactionsCard(transactions: transactions),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _kBackground,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Icon(Icons.person_outline, color: Colors.grey.shade700, size: 18),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Runrate',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(6)),
            child: const Text(
              'CFO',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Icon(Icons.notifications_none_rounded, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Shared card shell
/// ---------------------------------------------------------------------

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}

/// ---------------------------------------------------------------------
/// Budget card
/// ---------------------------------------------------------------------

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.summary});

  final BudgetSummary summary;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_outlined, color: _kPrimary, size: 20),
                        const SizedBox(width: 8),
                        const Text('FY24 AI Budget', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total Enterprise Allocation',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      summary.periodLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.grey.shade700),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 176,
              height: 176,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      valueColor: AlwaysStoppedAnimation(Colors.grey.shade200),
                    ),
                  ),
                  SizedBox(
                    width: 176,
                    height: 176,
                    child: CircularProgressIndicator(
                      value: summary.utilizationRatio,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      valueColor: const AlwaysStoppedAnimation(_kPrimary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(summary.utilizationRatio * 100).round()}%',
                        style: const TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 28),
                      ),
                      Text('Utilized', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONSUMED',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                    ),
                    const SizedBox(height: 4),
                    Text(_formatCompactUsd(summary.consumed), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'TOTAL LIMIT',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.4),
                  ),
                  const SizedBox(height: 4),
                  Text(_formatCompactUsd(summary.totalLimit), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Remaining Runway', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 6),
                      Text(
                        '~${summary.remainingRunwayMonths.toStringAsFixed(1)} Months',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Burn Rate', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.trending_up, size: 16, color: Color(0xFFE5484D)),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatCompactUsd(summary.burnRatePerMonth)}/mo',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFFE5484D)),
                          ),
                        ],
                      ),
                    ],
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
/// CFO Actions card
/// ---------------------------------------------------------------------

class _CfoActionsCard extends StatelessWidget {
  const _CfoActionsCard();

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CFO Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Reallocate Funds'),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune, size: 18, color: _kPrimary),
              label: const Text('Adjust Limits', style: TextStyle(color: _kPrimary)),
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimaryLight,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: const Text('Export Audit Log'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Departmental breakdown card
/// ---------------------------------------------------------------------

class _DepartmentalBreakdownCard extends StatelessWidget {
  const _DepartmentalBreakdownCard({required this.departments});

  final List<DepartmentSpend> departments;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Departmental Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                child: const Text('View All', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < departments.length; i++) ...[
            _DepartmentRow(department: departments[i]),
            if (i != departments.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _DepartmentRow extends StatelessWidget {
  const _DepartmentRow({required this.department});

  final DepartmentSpend department;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(department.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              '${_formatCompactUsd(department.spent)} / ${_formatCompactUsd(department.limit)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: department.ratio,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(department.barColor),
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// High-value transactions card
/// ---------------------------------------------------------------------

class _HighValueTransactionsCard extends StatelessWidget {
  const _HighValueTransactionsCard({required this.transactions});

  final List<WalletTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('High-Value Transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
                child: Text('>\$10k', style: TextStyle(color: Colors.grey.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final transaction in transactions) ...[
            _TransactionTile(transaction: transaction),
            if (transaction != transactions.last) Divider(color: Colors.grey.shade200, height: 1),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction});

  final WalletTransaction transaction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: transaction.iconBackgroundColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(transaction.icon, color: transaction.iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(transaction.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '-${_formatCompactUsd(transaction.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFFE5484D)),
              ),
              const SizedBox(height: 2),
              Text(transaction.dateLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Bottom navigation bar
/// ---------------------------------------------------------------------

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(icon: Icons.home_outlined, label: 'Home', isSelected: false),
              _NavItem(icon: Icons.smart_toy_outlined, label: 'AI', isSelected: false),
              _NavItem(icon: Icons.groups_outlined, label: 'Teams', isSelected: false),
              _NavItem(icon: Icons.fact_check_outlined, label: 'Approvals', isSelected: false),
              _NavItem(icon: Icons.more_horiz, label: 'More', isSelected: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.isSelected});

  final IconData icon;
  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _kPrimary : Colors.grey.shade500;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        if (isSelected) ...[
          const SizedBox(height: 2),
          Container(width: 4, height: 4, decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle)),
        ],
      ],
    );
  }
}

/// ---------------------------------------------------------------------
/// Formatting helper — compact USD (e.g. $2.38M, $600k, $45,000)
/// ---------------------------------------------------------------------

String _formatCompactUsd(double value) {
  if (value >= 1000000) {
    return '\$${(value / 1000000).toStringAsFixed(2)}M';
  }
  if (value >= 100000) {
    return '\$${(value / 1000).toStringAsFixed(0)}k';
  }
  if (value >= 1000) {
    return '\$${(value / 1000).toStringAsFixed(1)}k';
  }
  return '\$${value.toStringAsFixed(0)}';
}