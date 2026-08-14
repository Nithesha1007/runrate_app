import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:runrate/core/theme/app_typography.dart';

/// Renders a numeric value (spend, cost, count) as an [Icon] + plain
/// formatted digits — never a raw currency-symbol string, which renders
/// as a black tofu box on this app's font.
///
/// Use [StatValue.currency] for money amounts (icon defaults to a payments
/// glyph) and [StatValue.count] for plain counts (icon defaults to a
/// generic numeric glyph).
class StatValue extends StatelessWidget {
  const StatValue({
    super.key,
    required this.formatted,
    required this.icon,
    required this.color,
    this.style,
  });

  factory StatValue.currency(
    num amount, {
    Color color = Colors.black,
    TextStyle? style,
    IconData icon = Icons.payments_outlined,
  }) {
    final formatter = NumberFormat.decimalPattern();
    return StatValue(
      formatted: formatter.format(amount),
      icon: icon,
      color: color,
      style: style,
    );
  }

  factory StatValue.count(
    num amount, {
    Color color = Colors.black,
    TextStyle? style,
    IconData icon = Icons.tag_outlined,
  }) {
    final formatter = NumberFormat.decimalPattern();
    return StatValue(
      formatted: formatter.format(amount),
      icon: icon,
      color: color,
      style: style,
    );
  }

  final String formatted;
  final IconData icon;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: (style?.fontSize ?? 16) + 2, color: color),
        const SizedBox(width: 4),
        Text(formatted, style: style ?? AppTypography.bodyLarge(color)),
      ],
    );
  }
}

