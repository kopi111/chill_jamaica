import '../entities/card_details.dart';
import '../entities/payment_request.dart';
import '../entities/payment_summary.dart';

/// A card-acquiring gateway that settles into the business's merchant account.
///
/// The app talks only to this interface, so switching acquirer — WiPay, Fygaro,
/// First Atlantic Commerce, an NCB or Sagicor facility — is one new
/// implementation and one changed provider, with no checkout rewrite.
///
/// Implementations must never persist or log [CardDetails]; return only the
/// brand, last four digits and the gateway's reference on the [PaymentSummary].
abstract interface class PaymentGateway {
  /// Name shown on the checkout screen, e.g. `WiPay`.
  String get displayName;

  /// Charges [card] for [request].
  ///
  /// Returns a settled [PaymentSummary] on approval. Throws a [Failure] when
  /// the card is declined or the gateway is unreachable.
  Future<PaymentSummary> chargeCard({
    required PaymentRequest request,
    required CardDetails card,
  });
}
