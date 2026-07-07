import 'package:intl/intl.dart';

/// Formatting helpers for currency, phone numbers and dates.
///
/// Centralised so JMD and Jamaican phone display stay identical everywhere.
abstract final class Formatters {
  const Formatters._();

  static final NumberFormat _jmd = NumberFormat.currency(
    locale: 'en_JM',
    symbol: 'JMD \$',
    decimalDigits: 0,
  );

  static final DateFormat _dateTime = DateFormat('MMM d, y • h:mm a');

  /// Formats an integer amount of Jamaican dollars, e.g. `JMD $1,200`.
  static String jmd(num amount) => _jmd.format(amount);

  /// Friendly absolute timestamp, e.g. `Jul 6, 2026 • 3:14 PM`.
  static String dateTime(DateTime value) => _dateTime.format(value.toLocal());

  /// Relative "time ago", e.g. `3 mins ago`, `just now`.
  static String relativeTime(DateTime value) {
    final Duration diff = DateTime.now().difference(value.toLocal());
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final int m = diff.inMinutes;
      return '$m min${m == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final int h = diff.inHours;
      return '$h hour${h == 1 ? '' : 's'} ago';
    }
    final int d = diff.inDays;
    if (d < 7) return '$d day${d == 1 ? '' : 's'} ago';
    return dateTime(value);
  }

  /// Normalises any human-typed Jamaican number to E.164, e.g. `+18761234567`.
  static String toE164Jamaican(String raw) {
    final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final String national = digits.startsWith('1') ? digits.substring(1) : digits;
    return '+1$national';
  }

  /// Pretty display form, e.g. `+1 (876) 123-4567`.
  static String prettyPhone(String e164) {
    final String digits = e164.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11) return e164;
    final String area = digits.substring(1, 4);
    final String prefix = digits.substring(4, 7);
    final String line = digits.substring(7);
    return '+1 ($area) $prefix-$line';
  }
}
