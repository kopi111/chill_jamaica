import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/gateways/sandbox_payment_gateway.dart';
import '../../domain/entities/card_details.dart';
import '../../domain/entities/payment_request.dart';
import '../../domain/entities/payment_summary.dart';
import '../../domain/gateways/payment_gateway.dart';

/// The acquirer the app charges cards through.
///
/// TODO: swap [SandboxPaymentGateway] for the live implementation once the
/// business's merchant account and gateway are open (WiPay, Fygaro, First
/// Atlantic Commerce, or an NCB / Sagicor facility). Nothing outside this
/// provider needs to change.
final paymentGatewayProvider = Provider<PaymentGateway>(
  (ref) => const SandboxPaymentGateway(),
);

/// Runs one card charge, exposing idle → loading → error for the pay button.
class CardPaymentController extends AutoDisposeAsyncNotifier<PaymentSummary?> {
  @override
  Future<PaymentSummary?> build() async => null;

  /// Charges [card] and returns the settled payment, or null when it failed.
  ///
  /// A failure leaves the message in [state] for the screen to surface.
  Future<PaymentSummary?> pay({
    required PaymentRequest request,
    required CardDetails card,
  }) async {
    if (state.isLoading) return null; // ignore rapid re-taps

    state = const AsyncValue<PaymentSummary?>.loading();
    state = await AsyncValue.guard(
      () => ref.read(paymentGatewayProvider).chargeCard(
            request: request,
            card: card,
          ),
    );
    return state.valueOrNull;
  }
}

final cardPaymentControllerProvider =
    AsyncNotifierProvider.autoDispose<CardPaymentController, PaymentSummary?>(
  CardPaymentController.new,
);
