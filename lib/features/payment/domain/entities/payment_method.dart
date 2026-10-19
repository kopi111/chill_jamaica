import 'package:flutter/material.dart';

/// How the customer chose to pay.
///
/// [wireValue] is stored on the order document — renaming one needs a data
/// migration.
enum PaymentMethod {
  card(
    wireValue: 'card',
    label: 'Pay by Card',
    description: 'Visa, Mastercard or Amex — paid now',
    icon: Icons.credit_card,
  ),
  cashOnDelivery(
    wireValue: 'cash_on_delivery',
    label: 'Cash on Delivery',
    description: 'Pay di driver when it reach',
    icon: Icons.payments_outlined,
  );

  const PaymentMethod({
    required this.wireValue,
    required this.label,
    required this.description,
    required this.icon,
  });

  final String wireValue;
  final String label;
  final String description;
  final IconData icon;

  bool get isCard => this == PaymentMethod.card;

  static PaymentMethod fromWire(String? value) => values.firstWhere(
        (PaymentMethod m) => m.wireValue == value,
        orElse: () => PaymentMethod.cashOnDelivery,
      );
}
