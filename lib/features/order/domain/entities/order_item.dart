import 'package:flutter/foundation.dart';

import 'cart_item.dart';

/// A snapshot of one ordered line, frozen at checkout time.
///
/// Unlike [CartItem] this stores the price/name paid so a later product price
/// change never rewrites historical orders.
@immutable
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;

  /// Size label as shown to the customer, e.g. `1.89L`.
  final String size;
  final int quantity;

  /// Price per unit in JMD at time of order.
  final int unitPrice;

  int get lineTotal => unitPrice * quantity;

  /// Builds an immutable order line from a live cart item.
  factory OrderItem.fromCartItem(CartItem item) => OrderItem(
        productId: item.product.id,
        productName: item.product.name,
        size: item.product.sizeLabel,
        quantity: item.quantity,
        unitPrice: item.product.priceJmd,
      );
}
