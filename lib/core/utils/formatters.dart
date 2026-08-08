import 'package:intl/intl.dart';

/// Currency/number formatting helpers used across dashboards and reports.
class Formatters {
  static final _currency = NumberFormat.currency(symbol: '', decimalDigits: 0);
  static String currency(num value) => _currency.format(value);
  static String percent(num value) => '${value.toStringAsFixed(0)}%';

  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat.yMMMd().format(dateTime);
  }
}
