import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    symbol: '\$',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.compactCurrency(
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Format a number as currency ($1,234.56)
  static String formatCurrency(double value) {
    return _currencyFormat.format(value);
  }

  /// Format a number as compact currency ($1.2M, $45K)
  static String formatCompactCurrency(double value) {
    return _compactCurrencyFormat.format(value);
  }

  /// Format a number as a percentage (7.5%)
  static String formatPercentage(double value, {int decimals = 1}) {
    return '${value.toStringAsFixed(decimals)}%';
  }

  /// Format a date as MM/dd/yyyy
  static String formatDate(DateTime date) {
    return DateFormat('MM/dd/yyyy').format(date);
  }

  /// Format a date as a short date (Jan 15, 2024)
  static String formatShortDate(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }

  /// Format a large number with commas (1,234,567)
  static String formatNumber(double value, {int decimals = 0}) {
    final pattern = decimals > 0 ? '#,##0.${'0' * decimals}' : '#,##0';
    return NumberFormat(pattern).format(value);
  }
}
