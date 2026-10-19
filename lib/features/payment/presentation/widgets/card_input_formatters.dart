import 'package:flutter/services.dart';

/// Groups a card number into blocks of four as the customer types.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  static const int _groupSize = 4;
  static const int _maxDigits = 16;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = _digitsOf(newValue.text, limit: _maxDigits);
    final String grouped = _inGroupsOfFour(digits);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }

  String _inGroupsOfFour(String digits) {
    final StringBuffer grouped = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % _groupSize == 0) grouped.write(' ');
      grouped.write(digits[i]);
    }
    return grouped.toString();
  }
}

/// Formats an expiry date as `MM/YY` while the customer types.
class ExpiryDateFormatter extends TextInputFormatter {
  const ExpiryDateFormatter();

  static const int _maxDigits = 4;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String digits = _digitsOf(newValue.text, limit: _maxDigits);
    final String formatted = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _digitsOf(String raw, {required int limit}) {
  final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  return digits.length <= limit ? digits : digits.substring(0, limit);
}
