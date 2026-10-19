import 'package:chill_jamaica/core/errors/failures.dart';
import 'package:chill_jamaica/features/payment/data/gateways/sandbox_payment_gateway.dart';
import 'package:chill_jamaica/features/payment/domain/entities/card_brand.dart';
import 'package:chill_jamaica/features/payment/domain/entities/card_details.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_method.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_request.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_status.dart';
import 'package:chill_jamaica/features/payment/domain/entities/payment_summary.dart';
import 'package:flutter_test/flutter_test.dart';

const PaymentRequest _request = PaymentRequest(
  amountJmd: 2400,
  reference: 'CJTEST1',
  customerName: 'Lex Robinson',
  customerEmail: 'lex@example.com',
  customerPhone: '+18761234567',
);

CardDetails _card(String number) => CardDetails(
      number: number,
      holderName: 'LEX ROBINSON',
      expiryMonth: 6,
      expiryYear: DateTime.now().year + 2,
      securityCode: '123',
    );

void main() {
  const SandboxPaymentGateway gateway = SandboxPaymentGateway();

  test('approves a valid card and reports it settled', () async {
    final PaymentSummary summary = await gateway.chargeCard(
      request: _request,
      card: _card('4242424242424242'),
    );

    expect(summary.status, PaymentStatus.paid);
    expect(summary.method, PaymentMethod.card);
    expect(summary.cardBrand, CardBrand.visa);
    expect(summary.cardLast4, '4242');
    expect(summary.gatewayReference, 'SBX-CJTEST1');
  });

  test('keeps only the brand and last four on the summary', () async {
    final PaymentSummary summary = await gateway.chargeCard(
      request: _request,
      card: _card('4242424242424242'),
    );

    expect(summary.maskedCard, 'Visa ••••4242');
    expect(summary.maskedCard, isNot(contains('4242424242')));
  });

  test('declines the decline-suffix test card', () async {
    expect(
      () => gateway.chargeCard(
        request: _request,
        card: _card('4000000000000002'),
      ),
      throwsA(isA<ServerFailure>()),
    );
  });

  test('reports the gateway unreachable for the network test card', () async {
    expect(
      () => gateway.chargeCard(
        request: _request,
        card: _card('4000000000000069'),
      ),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('refuses a card that fails local validation', () async {
    expect(
      () => gateway.chargeCard(
        request: _request,
        card: _card('4242424242424241'),
      ),
      throwsA(isA<ServerFailure>()),
    );
  });
}
