import 'package:intl/intl.dart';

/// Currency/number formatting helpers used across dashboards and reports.
class Formatters {
  static final _currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
  static String currency(num value) => _currency.format(value);
  static String percent(num value) => '\${value.toStringAsFixed(0)}%';
}
