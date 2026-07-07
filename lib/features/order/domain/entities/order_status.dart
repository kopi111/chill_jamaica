import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Lifecycle of an order, shared by the customer and admin apps.
///
/// [wireValue] is the exact string stored in Firestore — never rename these
/// without a data migration.
enum OrderStatus {
  newOrder(wireValue: 'new', label: 'New', color: AppColors.statusNew),
  processing(
    wireValue: 'processing',
    label: 'Processing',
    color: AppColors.statusProcessing,
  ),
  outForDelivery(
    wireValue: 'out_for_delivery',
    label: 'Out for Delivery',
    color: AppColors.statusOutForDelivery,
  ),
  delivered(
    wireValue: 'delivered',
    label: 'Delivered',
    color: AppColors.statusDelivered,
  );

  const OrderStatus({
    required this.wireValue,
    required this.label,
    required this.color,
  });

  final String wireValue;
  final String label;
  final Color color;

  /// Parses a Firestore string, defaulting to [newOrder] for unknown values.
  static OrderStatus fromWire(String? value) => values.firstWhere(
        (OrderStatus s) => s.wireValue == value,
        orElse: () => OrderStatus.newOrder,
      );
}
