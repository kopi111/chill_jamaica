/// The card networks the business accepts.
///
/// Detected from the leading digits so the checkout form can show the right
/// logo and expect the right CVV length.
enum CardBrand {
  visa(
    wireValue: 'visa',
    label: 'Visa',
    securityCodeLength: 3,
    numberLength: 16,
  ),
  mastercard(
    wireValue: 'mastercard',
    label: 'Mastercard',
    securityCodeLength: 3,
    numberLength: 16,
  ),
  amex(
    wireValue: 'amex',
    label: 'American Express',
    securityCodeLength: 4,
    numberLength: 15,
  ),
  unknown(
    wireValue: 'unknown',
    label: 'Card',
    securityCodeLength: 3,
    numberLength: 16,
  );

  const CardBrand({
    required this.wireValue,
    required this.label,
    required this.securityCodeLength,
    required this.numberLength,
  });

  final String wireValue;
  final String label;

  /// Digits in this brand's CVV/CVC.
  final int securityCodeLength;

  /// Digits in a full card number for this brand.
  final int numberLength;

  /// Identifies the brand from a card number's leading digits.
  static CardBrand fromNumber(String digits) {
    if (digits.startsWith('4')) return visa;
    if (_isMastercardRange(digits)) return mastercard;
    if (RegExp(r'^3[47]').hasMatch(digits)) return amex;
    return unknown;
  }

  static CardBrand fromWire(String? value) => values.firstWhere(
        (CardBrand b) => b.wireValue == value,
        orElse: () => unknown,
      );

  /// Mastercard uses 51–55 plus the newer 2221–2720 range.
  static bool _isMastercardRange(String digits) {
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return true;
    if (digits.length < 4) return false;
    final int prefix = int.tryParse(digits.substring(0, 4)) ?? 0;
    return prefix >= 2221 && prefix <= 2720;
  }
}
