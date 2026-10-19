import 'package:chill_jamaica/features/payment/domain/entities/card_brand.dart';
import 'package:chill_jamaica/features/payment/domain/entities/card_details.dart';
import 'package:flutter_test/flutter_test.dart';

CardDetails _card({
  String number = '4242424242424242',
  String holderName = 'LEX ROBINSON',
  int expiryMonth = 6,
  int expiryYear = 2030,
  String securityCode = '123',
}) =>
    CardDetails(
      number: number,
      holderName: holderName,
      expiryMonth: expiryMonth,
      expiryYear: expiryYear,
      securityCode: securityCode,
    );

void main() {
  group('CardDetails number handling', () {
    test('strips spaces and dashes typed by the customer', () {
      expect(_card(number: '4242 4242-4242 4242').number, '4242424242424242');
    });

    test('exposes only the last four digits', () {
      expect(_card().last4, '4242');
    });

    test('never puts the number in its string form', () {
      expect(_card().toString(), 'CardDetails(Visa ••••4242)');
    });
  });

  group('CardDetails validation', () {
    test('accepts a Luhn-valid Visa number', () {
      expect(_card().hasValidNumber, isTrue);
    });

    test('rejects a number that fails the Luhn checksum', () {
      expect(_card(number: '4242424242424241').hasValidNumber, isFalse);
    });

    test('rejects a number of the wrong length for its brand', () {
      expect(_card(number: '424242424242').hasValidNumber, isFalse);
    });

    test('requires four CVV digits on Amex and three elsewhere', () {
      const String amex = '378282246310005';
      expect(_card(number: amex, securityCode: '123').hasValidSecurityCode,
          isFalse);
      expect(
          _card(number: amex, securityCode: '1234').hasValidSecurityCode, isTrue);
      expect(_card(securityCode: '1234').hasValidSecurityCode, isFalse);
    });

    test('counts the expiry month itself as still in date', () {
      final CardDetails card = _card(expiryMonth: 6, expiryYear: 2026);
      expect(card.isUnexpiredOn(DateTime(2026, 6, 30)), isTrue);
      expect(card.isUnexpiredOn(DateTime(2026, 7)), isFalse);
    });

    test('rejects an impossible expiry month', () {
      expect(_card(expiryMonth: 13).isUnexpiredOn(DateTime(2026, 8)), isFalse);
    });

    test('requires a holder name', () {
      expect(_card(holderName: '   ').isValidOn(DateTime(2026, 8)), isFalse);
    });
  });

  group('CardBrand detection', () {
    test('reads the brand from the leading digits', () {
      expect(CardBrand.fromNumber('4242424242424242'), CardBrand.visa);
      expect(CardBrand.fromNumber('5555555555554444'), CardBrand.mastercard);
      expect(CardBrand.fromNumber('2223003122003222'), CardBrand.mastercard);
      expect(CardBrand.fromNumber('378282246310005'), CardBrand.amex);
      expect(CardBrand.fromNumber('9999999999999999'), CardBrand.unknown);
    });

    test('survives a partially typed number', () {
      expect(CardBrand.fromNumber(''), CardBrand.unknown);
      expect(CardBrand.fromNumber('22'), CardBrand.unknown);
      expect(CardBrand.fromNumber('4'), CardBrand.visa);
    });

    test('round-trips through its wire value', () {
      for (final CardBrand brand in CardBrand.values) {
        expect(CardBrand.fromWire(brand.wireValue), brand);
      }
      expect(CardBrand.fromWire('something-else'), CardBrand.unknown);
    });
  });
}
