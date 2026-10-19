import 'package:flutter/foundation.dart';

/// What the gateway needs to know to take one payment.
@immutable
class PaymentRequest {
  const PaymentRequest({
    required this.amountJmd,
    required this.reference,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  /// Whole Jamaican dollars — the app never deals in cents.
  final int amountJmd;

  /// The business's own reference for this payment, echoed back by the gateway.
  final String reference;

  final String customerName;
  final String customerEmail;

  /// E.164 Jamaican number, e.g. `+18761234567`.
  final String customerPhone;
}
