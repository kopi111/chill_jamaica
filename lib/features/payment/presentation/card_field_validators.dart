import '../domain/entities/card_brand.dart';
import '../domain/entities/card_details.dart';

/// Form-field validators for the card entry form.
///
/// They mirror the checks the gateway will run, so an obviously bad card is
/// caught before it costs a round trip or a declined-transaction fee.
abstract final class CardFieldValidators {
  const CardFieldValidators._();

  static String? number(String? raw) {
    final String digits = _digitsOf(raw);
    if (digits.isEmpty) return 'Enter di card number';
    final CardBrand brand = CardBrand.fromNumber(digits);
    if (digits.length != brand.numberLength) {
      return 'Card number should be ${brand.numberLength} digits';
    }
    final CardDetails probe = _probeCardWith(number: digits);
    return probe.hasValidNumber ? null : 'That card number nuh look right';
  }

  static String? holderName(String? raw) {
    final String value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter di name on di card';
    return null;
  }

  /// Expects `MM/YY`, as produced by the expiry-date input formatter.
  static String? expiry(String? raw, {DateTime? now}) {
    final String digits = _digitsOf(raw);
    if (digits.length < 4) return 'Enter MM/YY';

    final ExpiryDate? expiryDate = ExpiryDate.parse(raw ?? '');
    if (expiryDate == null) return 'Check di expiry month';

    final CardDetails probe = _probeCardWith(
      expiryMonth: expiryDate.month,
      expiryYear: expiryDate.year,
    );
    return probe.isUnexpiredOn(now ?? DateTime.now())
        ? null
        : 'That card expire already';
  }

  static String? securityCode(String? raw, {required String cardNumber}) {
    final String digits = _digitsOf(raw);
    final CardBrand brand = CardBrand.fromNumber(_digitsOf(cardNumber));
    if (digits.isEmpty) return 'Enter di CVV';
    if (digits.length != brand.securityCodeLength) {
      return 'CVV is ${brand.securityCodeLength} digits';
    }
    return null;
  }

  /// A throwaway card used only to reuse the entity's own validation rules.
  static CardDetails _probeCardWith({
    String number = '',
    int expiryMonth = 1,
    int expiryYear = 2000,
  }) =>
      CardDetails(
        number: number,
        holderName: 'probe',
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        securityCode: '000',
      );

  static String _digitsOf(String? raw) =>
      (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');
}

/// A parsed `MM/YY` expiry.
class ExpiryDate {
  const ExpiryDate({required this.month, required this.year});

  final int month;

  /// Full four-digit year, e.g. 2028.
  final int year;

  /// Parses `MM/YY` (separators optional), returning null when unparseable.
  static ExpiryDate? parse(String raw) {
    final String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 4) return null;
    final int? month = int.tryParse(digits.substring(0, 2));
    final int? shortYear = int.tryParse(digits.substring(2, 4));
    if (month == null || shortYear == null) return null;
    if (month < 1 || month > 12) return null;
    return ExpiryDate(month: month, year: _century + shortYear);
  }

  static const int _century = 2000;
}
