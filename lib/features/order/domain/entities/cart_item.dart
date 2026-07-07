import 'package:flutter/foundation.dart';

import '../../../menu/domain/entities/product.dart';

/// A product plus a chosen quantity, held in the customer's cart.
@immutable
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  /// Line total in JMD (unit price × quantity).
  int get lineTotal => product.priceJmd * quantity;

  CartItem copyWith({int? quantity}) =>
      CartItem(product: product, quantity: quantity ?? this.quantity);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CartItem &&
          other.product == product &&
          other.quantity == quantity);

  @override
  int get hashCode => Object.hash(product, quantity);
}
