import 'package:chill_jamaica/features/payment/presentation/card_field_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('card number field', () {
    test('accepts a well-formed number, spaces and all', () {
      expect(CardFieldValidators.number('4242 4242 4242 4242'), isNull);
    });

    test('asks for the number when the field is empty', () {
      expect(CardFieldValidators.number(''), 'Enter di card number');
    });

    test('names the expected length for the detected brand', () {
      expect(CardFieldValidators.number('4242 4242'),
          'Card number should be 16 digits');
      expect(CardFieldValidators.number('3782 8224 631'),
          'Card number should be 15 digits');
    });

    test('rejects a full-length number that fails the checksum', () {
      expect(CardFieldValidators.number('4242 4242 4242 4241'),
          'That card number nuh look right');
    });
  });

  group('expiry field', () {
    final DateTime now = DateTime(2026, 8, 7);

    test('accepts a future MM/YY', () {
      expect(CardFieldValidators.expiry('06/30', now: now), isNull);
    });

    test('accepts the current month', () {
      expect(CardFieldValidators.expiry('08/26', now: now), isNull);
    });

    test('rejects a past month', () {
      expect(CardFieldValidators.expiry('07/26', now: now),
          'That card expire already');
    });

    test('asks for more digits while the customer is still typing', () {
      expect(CardFieldValidators.expiry('0', now: now), 'Enter MM/YY');
      expect(CardFieldValidators.expiry('06/', now: now), 'Enter MM/YY');
    });

    test('rejects a month outside 1–12', () {
      expect(CardFieldValidators.expiry('13/30', now: now),
          'Check di expiry month');
    });
  });

  group('CVV field', () {
    test('expects three digits for Visa and four for Amex', () {
      expect(
        CardFieldValidators.securityCode('123', cardNumber: '4242424242424242'),
        isNull,
      );
      expect(
        CardFieldValidators.securityCode('123', cardNumber: '378282246310005'),
        'CVV is 4 digits',
      );
      expect(
        CardFieldValidators.securityCode('1234', cardNumber: '378282246310005'),
        isNull,
      );
    });

    test('asks for the code when the field is empty', () {
      expect(
        CardFieldValidators.securityCode('', cardNumber: '4242424242424242'),
        'Enter di CVV',
      );
    });
  });

  group('ExpiryDate parsing', () {
    test('reads MM/YY into a four-digit year', () {
      final ExpiryDate? parsed = ExpiryDate.parse('06/30');
      expect(parsed?.month, 6);
      expect(parsed?.year, 2030);
    });

    test('ignores separators', () {
      expect(ExpiryDate.parse('0630')?.year, 2030);
    });

    test('returns null for an unparseable value', () {
      expect(ExpiryDate.parse('6/3'), isNull);
      expect(ExpiryDate.parse('00/30'), isNull);
    });
  });
}
