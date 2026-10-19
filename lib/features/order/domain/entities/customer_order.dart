import 'package:flutter/foundation.dart';

import '../../../../core/utils/extensions.dart';
import '../../../payment/domain/entities/payment_summary.dart';
import 'delivery_details.dart';
import 'order_item.dart';
import 'order_status.dart';

/// A placed order. Named `CustomerOrder` to avoid confusion with sort "order".
@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.customerPhone,
    required this.delivery,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.payment,
    required this.createdAt,
    this.customerId,
  });

  final String id;

  /// E.164 Jamaican number, e.g. `+18761234567`.
  final String customerPhone;

  /// The signed-in customer's uid, absent on legacy phone-only orders.
  final String? customerId;

  final DeliveryDetails delivery;
  final List<OrderItem> items;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final OrderStatus status;
  final PaymentSummary payment;
  final DateTime createdAt;

  /// Total number of bottles across all lines.
  int get itemCount => items.sumBy((OrderItem i) => i.quantity);

  /// Compact human summary, e.g. `2x 1/2 Gallon + 1x Soda Bottle`.
  String get itemSummary =>
      items.map((OrderItem i) => '${i.quantity}x ${i.productName}').join(' + ');

  /// Short id for display, e.g. `#A1B2C3`.
  String get shortId =>
      '#${id.substring(0, id.length < 6 ? id.length : 6).toUpperCase()}';
}
