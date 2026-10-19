import 'package:chill_jamaica/features/menu/domain/entities/product.dart';
import 'package:chill_jamaica/features/order/data/models/order_model.dart';
import 'package:chill_jamaica/features/order/domain/entities/cart_item.dart';
import 'package:chill_jamaica/features/order/domain/entities/delivery_details.dart';
import 'package:chill_jamaica/features/order/domain/entities/order_draft.dart';
import 'package:chill_jamaica/features/payment/domain/entities/card_brand.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_method.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_status.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const Product _product = Product(
  id: 'p1',
  name: '1/2 Gallon',
  sizeMl: 1890,
  priceJmd: 1200,
  imagePlaceholder: '',
  isAvailable: true,
);

OrderDraft _draft({
  PaymentSummary payment = const PaymentSummary.cashOnDelivery(),
  String? customerId,
}) =>
    OrderDraft(
      customerPhone: '+18761234567',
      customerId: customerId,
      delivery: const DeliveryDetails.typed('12 Hope Road, Kingston 6'),
      cartItems: const <CartItem>[CartItem(product: _product, quantity: 2)],
      payment: payment,
    );

const PaymentSummary _cardPayment = PaymentSummary(
  method: PaymentMethod.card,
  status: PaymentStatus.paid,
  gatewayReference: 'SBX-CJTEST1',
  cardBrand: CardBrand.visa,
  cardLast4: '4242',
);

void main() {
  group('draftToFirestore', () {
    test('records a settled card payment without the card number', () {
      final Map<String, dynamic> payload =
          OrderModel.draftToFirestore(_draft(payment: _cardPayment));
      final Map<String, dynamic> payment =
          payload['payment'] as Map<String, dynamic>;

      expect(payment['method'], 'card');
      expect(payment['status'], 'paid');
      expect(payment['gatewayReference'], 'SBX-CJTEST1');
      expect(payment['cardBrand'], 'visa');
      expect(payment['cardLast4'], '4242');
      expect(payment.keys, isNot(contains('number')));
      expect(payment.keys, isNot(contains('securityCode')));
    });

    test('defaults to cash on delivery when no payment is given', () {
      final Map<String, dynamic> payment =
          OrderModel.draftToFirestore(_draft())['payment']
              as Map<String, dynamic>;

      expect(payment['method'], 'cash_on_delivery');
      expect(payment['status'], 'awaiting_cash');
      expect(payment['cardLast4'], isNull);
    });

    test('carries the signed-in customer id so the order is theirs', () {
      expect(
        OrderModel.draftToFirestore(_draft(customerId: 'uid-1'))['customerId'],
        'uid-1',
      );
      expect(OrderModel.draftToFirestore(_draft())['customerId'], isNull);
    });
  });

  group('offline queue', () {
    test('keeps the payment through a queue round-trip', () {
      final Map<String, dynamic> queued =
          OrderModel.draftToQueueJson(_draft(payment: _cardPayment));
      final Map<String, dynamic> restored =
          OrderModel.queueJsonToFirestore(queued);
      final Map<String, dynamic> payment =
          restored['payment'] as Map<String, dynamic>;

      expect(payment['gatewayReference'], 'SBX-CJTEST1');
      expect(payment['status'], 'paid');
      expect(restored['customerId'], isNull);
    });
  });

  group('wire values', () {
    test('round-trip through their parsers', () {
      for (final PaymentMethod method in PaymentMethod.values) {
        expect(PaymentMethod.fromWire(method.wireValue), method);
      }
      for (final PaymentStatus status in PaymentStatus.values) {
        expect(PaymentStatus.fromWire(status.wireValue), status);
      }
    });

    test('fall back safely on an unknown value', () {
      expect(PaymentMethod.fromWire(null), PaymentMethod.cashOnDelivery);
      expect(PaymentStatus.fromWire('bananas'), PaymentStatus.awaitingCash);
    });
  });
}
