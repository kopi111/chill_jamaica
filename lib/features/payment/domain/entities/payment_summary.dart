import 'package:flutter/foundation.dart';

import 'card_brand.dart';
import 'payment_method.dart';
import 'payment_status.dart';

/// The payment facts recorded on an order.
///
/// Deliberately holds nothing that could identify a card beyond its brand and
/// last four digits.
@immutable
class PaymentSummary {
  const PaymentSummary({
    required this.method,
    required this.status,
    this.gatewayReference,
    this.cardBrand,
    this.cardLast4,
  });

  /// The summary for an order the driver will collect cash for.
  const PaymentSummary.cashOnDelivery()
      : method = PaymentMethod.cashOnDelivery,
        status = PaymentStatus.awaitingCash,
        gatewayReference = null,
        cardBrand = null,
        cardLast4 = null;

  final PaymentMethod method;
  final PaymentStatus status;

  /// The gateway's transaction id, used to reconcile against the merchant
  /// account and to raise a refund.
  final String? gatewayReference;

  final CardBrand? cardBrand;
  final String? cardLast4;

  /// Display form for a receipt line, e.g. `Visa ••••4242`.
  String get maskedCard {
    final CardBrand? brand = cardBrand;
    final String? last4 = cardLast4;
    if (brand == null || last4 == null) return method.label;
    return '${brand.label} ••••$last4';
  }
}
