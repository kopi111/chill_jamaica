import 'package:flutter/foundation.dart';

import '../../../../core/utils/extensions.dart';
import '../../../menu/domain/entities/product.dart';
import '../../../payment/domain/entities/payment_summary.dart';
import 'cart_item.dart';
import 'delivery_details.dart';
import 'order_item.dart';

/// An order the customer is about to place — no id or server timestamp yet.
///
/// The repository turns this into a persisted [CustomerOrder]. Totals are
/// computed here so the client and the eventual receipt always agree.
@immutable
class OrderDraft {
  OrderDraft({
    required this.customerPhone,
    required this.delivery,
    required List<CartItem> cartItems,
    this.payment = const PaymentSummary.cashOnDelivery(),
    this.customerId,
    this.deliveryFee = 0,
  }) : items = List<OrderItem>.unmodifiable(
          cartItems.map(OrderItem.fromCartItem),
        );

  final String customerPhone;

  /// The signed-in customer's uid, so they can see this order on any device.
  final String? customerId;

  final DeliveryDetails delivery;
  final List<OrderItem> items;

  /// How this order is being paid for. Card orders arrive already settled.
  final PaymentSummary payment;

  /// Placeholder — currently always 0; kept so pricing can grow later.
  final int deliveryFee;

  int get subtotal => items.sumBy((OrderItem i) => i.lineTotal);
  int get total => subtotal + deliveryFee;

  bool get isEmpty => items.isEmpty;

  /// A stable idempotency key so a retried submit doesn't create a duplicate.
  ///
  /// Built from phone + line contents; two identical carts from the same phone
  /// within the same session map to the same order document id.
  String idempotencyKey(DateTime placedAt) {
    final String lines = items
        .map((OrderItem i) => '${i.productId}:${i.quantity}')
        .join('|');
    final int bucket = placedAt.millisecondsSinceEpoch ~/ 60000; // 1-min bucket
    return '$customerPhone#$lines#$bucket'.hashCode.toRadixString(16);
  }

  /// Convenience for tests / previews.
  static OrderDraft fromSingleProduct(
    Product product, {
    required String phone,
    int quantity = 1,
  }) =>
      OrderDraft(
        customerPhone: phone,
        delivery: const DeliveryDetails.typed('Kingston, Jamaica'),
        cartItems: <CartItem>[CartItem(product: product, quantity: quantity)],
      );
}
