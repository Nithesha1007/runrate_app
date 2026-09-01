import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF6C5CE7);
const _kPrimaryLight = Color(0xFFEDE9FE);
const _kBackground = Color(0xFFF7F6FB);
const _kCardRadius = 18.0;
const _kCritical = Color(0xFFE5484D);

/// ---------------------------------------------------------------------
/// Models
/// ---------------------------------------------------------------------

enum NotificationActionStyle { filled, light, muted }

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.timeLabel,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.actionLabel,
    this.actionStyle = NotificationActionStyle.light,
    this.isUnread = true,
  });

  final String title;
  final String timeLabel;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String? actionLabel;
  final NotificationActionStyle actionStyle;
  final bool isUnread;
}

class NotificationSectionData {
  const NotificationSectionData({required this.label, required this.items});

  final String label;
  final List<NotificationItem> items;
}

/// ---------------------------------------------------------------------
/// Screen
/// ---------------------------------------------------------------------

class CfoNotificationsScreen extends StatelessWidget {
  const CfoNotificationsScreen({super.key});

  static const _sections = [
    NotificationSectionData(
      label: 'Today',
      items: [
        NotificationItem(
          title: 'Budget Critical',
          timeLabel: '10m ago',
          description: 'Engineering budget has reached 95% of monthly limit.',
          icon: Icons.warning_amber_rounded,
          iconColor: _kCritical,
          iconBackgroundColor: Color(0xFFFDEBEC),
          actionLabel: 'Review Budget',
          actionStyle: NotificationActionStyle.light,
        ),
        NotificationItem(
          title: 'Large Transaction',
          timeLabel: '1h ago',
          description: 'A transaction for \$12,400 was flagged for manual review.',
          icon: Icons.receipt_long_outlined,
          iconColor: _kPrimary,
          iconBackgroundColor: Color(0xFFF1F1F5),
          actionLabel: 'Review',
          actionStyle: NotificationActionStyle.light,
        ),
        NotificationItem(
          title: 'AI Savings Insight',
          timeLabel: '2h ago',
          description: 'New efficiency report: \$45k in monthly savings identified by AI.',
          icon: Icons.auto_awesome,
          iconColor: _kPrimary,
          iconBackgroundColor: _kPrimaryLight,
          actionLabel: 'View Report',
          actionStyle: NotificationActionStyle.filled,
        ),
      ],
    ),
    NotificationSectionData(
      label: 'Yesterday',
      items: [
        NotificationItem(
          title: 'Escalated Approval',
          timeLabel: 'Yesterday',
          description: 'New tool request escalated to CFO: AWS Enterprise Upgrade.',
          icon: Icons.gavel_outlined,
          iconColor: Colors.grey,
          iconBackgroundColor: Color(0xFFF1F1F5),
          actionLabel: 'View Details',
          actionStyle: NotificationActionStyle.muted,
          isUnread: false,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  for (final section in _sections) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 8),
                      child: Text(
                        section.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    for (int i = 0; i < section.items.length; i++) ...[
                      _NotificationCard(item: section.items[i]),
                      if (i != section.items.length - 1) const SizedBox(height: 14),
                    ],
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w800, fontSize: 24),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
            child: Text(
              'CFO VIEW',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 0.3),
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
            child: const Text(
              'Mark all as read',
              style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// Notification card
/// ---------------------------------------------------------------------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_kCardRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: item.isUnread ? _kCritical : Colors.transparent),
              Expanded(
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          if (item.isUnread)
                            Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 8, top: 4),
                              decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
                            )
                          else
                            const SizedBox(height: 20),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: item.iconBackgroundColor, shape: BoxShape.circle),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: item.isUnread ? Colors.black : Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.timeLabel,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.description,
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4),
                            ),
                            if (item.actionLabel != null) ...[
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _ActionButton(label: item.actionLabel!, style: item.actionStyle),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.style});

  final String label;
  final NotificationActionStyle style;

  @override
  Widget build(BuildContext context) {
    late final Color bg;
    late final Color fg;

    switch (style) {
      case NotificationActionStyle.filled:
        bg = _kPrimary;
        fg = Colors.white;
        break;
      case NotificationActionStyle.light:
        bg = _kPrimaryLight;
        fg = _kPrimary;
        break;
      case NotificationActionStyle.muted:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        break;
    }

    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
      child: const SafeArea(
        child: Padding(
          padding:  EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:  [
              _NavItem(icon: Icons.home_outlined, label: 'Home', isSelected: false),
              _NavItem(icon: Icons.smart_toy_outlined, label: 'AI', isSelected: false, highlightIcon: true),
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
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.highlightIcon = false,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final bool highlightIcon;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? _kPrimary : Colors.grey.shade500;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (highlightIcon)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _kPrimaryLight, shape: BoxShape.circle),
            child: Icon(icon, color: _kPrimary, size: 20),
          )
        else
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