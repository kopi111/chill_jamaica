import '../../../../core/errors/failures.dart';
import '../../domain/entities/card_details.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_status.dart';
import '../../domain/entities/payment_summary.dart';
import '../../domain/gateways/payment_gateway.dart';

/// A stand-in [PaymentGateway] for demos and tests — no money moves.
///
/// It exists so the whole checkout can be built, shown to the client and
/// regression-tested before the business finishes onboarding with a Jamaican
/// acquirer. Swap it for the real implementation in `paymentGatewayProvider`;
/// nothing else changes.
///
/// Test cards:
/// * any Luhn-valid number — approved (e.g. `4242 4242 4242 4242`)
/// * a number ending `0002` — declined
/// * a number ending `0069` — gateway unreachable
class SandboxPaymentGateway implements PaymentGateway {
  const SandboxPaymentGateway();

  @override
  String get displayName => 'Sandbox (test mode)';

  @override
  Future<PaymentSummary> chargeCard({
    required PaymentRequest request,
    required CardDetails card,
  }) async {
    await Future<void>.delayed(_simulatedLatency);
    _rejectInvalidCard(card);
    _rejectTestFailures(card);
    return _approval(request, card);
  }

  void _rejectInvalidCard(CardDetails card) {
    if (card.isValidOn(DateTime.now())) return;
    throw const ServerFailure('Check di card details and try again.');
  }

  void _rejectTestFailures(CardDetails card) {
    if (card.number.endsWith(_declineSuffix)) {
      throw const ServerFailure('Card declined. Try a different card.');
    }
    if (card.number.endsWith(_unreachableSuffix)) {
      throw const NetworkFailure(
        'Could not reach di payment service. Try again in a minute.',
      );
    }
  }

  PaymentSummary _approval(PaymentRequest request, CardDetails card) =>
      PaymentSummary(
        method: PaymentMethod.card,
        status: PaymentStatus.paid,
        gatewayReference: 'SBX-${request.reference}',
        cardBrand: card.brand,
        cardLast4: card.last4,
      );

  static const Duration _simulatedLatency = Duration(milliseconds: 1200);
  static const String _declineSuffix = '0002';
  static const String _unreachableSuffix = '0069';
}
