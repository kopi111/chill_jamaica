import 'package:flutter/foundation.dart';

import 'card_brand.dart';

/// Card data typed at checkout, held in memory only for the length of one
/// charge.
///
/// Nothing here is ever written to Firestore, Hive, logs or analytics — only
/// [brand] and [last4] survive onto the order. Keep it that way: storing a full
/// card number would put the business inside PCI-DSS scope.
@immutable
class CardDetails {
  CardDetails({
    required String number,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
    required this.securityCode,
  }) : number = number.replaceAll(RegExp(r'[^0-9]'), '');

  /// Digits only, separators stripped.
  final String number;

  final String holderName;

  /// 1–12.
  final int expiryMonth;

  /// Four digits, e.g. 2028.
  final int expiryYear;

  final String securityCode;

  CardBrand get brand => CardBrand.fromNumber(number);

  /// Last four digits, the only part of the number safe to keep.
  String get last4 =>
      number.length < 4 ? number : number.substring(number.length - 4);

  bool get hasValidNumber =>
      number.length == brand.numberLength && _passesLuhn(number);

  bool get hasValidSecurityCode =>
      securityCode.length == brand.securityCodeLength &&
      int.tryParse(securityCode) != null;

  /// True while the card is still in date, counting the expiry month itself.
  bool isUnexpiredOn(DateTime date) {
    if (expiryMonth < 1 || expiryMonth > 12) return false;
    final DateTime endOfExpiryMonth = DateTime(expiryYear, expiryMonth + 1);
    return date.isBefore(endOfExpiryMonth);
  }

  bool isValidOn(DateTime date) =>
      hasValidNumber &&
      hasValidSecurityCode &&
      isUnexpiredOn(date) &&
      holderName.trim().isNotEmpty;

  /// Never expose the number, even by accident, in a log line or crash report.
  @override
  String toString() => 'CardDetails(${brand.label} ••••$last4)';

  /// The Luhn checksum every card network's numbers satisfy.
  static bool _passesLuhn(String digits) {
    if (digits.isEmpty) return false;
    int sum = 0;
    bool doubleThisDigit = false;
    for (int i = digits.length - 1; i >= 0; i--) {
      int digit = digits.codeUnitAt(i) - _zeroCodeUnit;
      if (digit < 0 || digit > 9) return false;
      if (doubleThisDigit) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleThisDigit = !doubleThisDigit;
    }
    return sum % 10 == 0;
  }

  static final int _zeroCodeUnit = '0'.codeUnitAt(0);
}
