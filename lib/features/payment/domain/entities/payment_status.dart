import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Where an order's money currently stands.
///
/// Card orders are created already [paid]; cash orders stay [awaitingCash]
/// until the driver collects.
enum PaymentStatus {
  paid(
    wireValue: 'paid',
    label: 'Paid',
    color: AppColors.statusDelivered,
    icon: Icons.verified_outlined,
  ),
  awaitingCash(
    wireValue: 'awaiting_cash',
    label: 'Cash on Delivery',
    color: AppColors.statusProcessing,
    icon: Icons.payments_outlined,
  ),
  declined(
    wireValue: 'declined',
    label: 'Declined',
    color: AppColors.urgentRed,
    icon: Icons.error_outline,
  ),
  refunded(
    wireValue: 'refunded',
    label: 'Refunded',
    color: AppColors.textSecondary,
    icon: Icons.undo,
  );

  const PaymentStatus({
    required this.wireValue,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String wireValue;
  final String label;
  final Color color;
  final IconData icon;

  bool get isSettled => this == PaymentStatus.paid;

  static PaymentStatus fromWire(String? value) => values.firstWhere(
        (PaymentStatus s) => s.wireValue == value,
        orElse: () => PaymentStatus.awaitingCash,
      );
}
