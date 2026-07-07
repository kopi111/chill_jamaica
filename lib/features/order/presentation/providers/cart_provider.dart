import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/extensions.dart';
import '../../../menu/domain/entities/product.dart';
import '../../domain/entities/cart_item.dart';

/// Holds the in-progress cart. Survives navigation but not app restart —
/// intentional, since prices can change between sessions.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => const <CartItem>[];

  /// Adds [quantity] of [product], merging with an existing line if present.
  void add(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;
    final int index = _indexOf(product);
    if (index == -1) {
      state = <CartItem>[...state, CartItem(product: product, quantity: quantity)];
      return;
    }
    state = _replaceAt(index, state[index].quantity + quantity);
  }

  /// Sets an absolute quantity; a value of 0 or less removes the line.
  void setQuantity(Product product, int quantity) {
    final int index = _indexOf(product);
    if (index == -1) {
      if (quantity > 0) add(product, quantity: quantity);
      return;
    }
    if (quantity <= 0) {
      remove(product);
      return;
    }
    state = _replaceAt(index, quantity);
  }

  void remove(Product product) {
    state = state
        .where((CartItem item) => item.product != product)
        .toList(growable: false);
  }

  void clear() => state = const <CartItem>[];

  int quantityOf(Product product) {
    final int index = _indexOf(product);
    return index == -1 ? 0 : state[index].quantity;
  }

  int _indexOf(Product product) =>
      state.indexWhere((CartItem item) => item.product == product);

  List<CartItem> _replaceAt(int index, int newQuantity) {
    final List<CartItem> next = List<CartItem>.of(state);
    next[index] = next[index].copyWith(quantity: newQuantity);
    return next;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

/// Total number of bottles in the cart — drives the app-bar badge.
final cartItemCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).sumBy((CartItem i) => i.quantity),
);

/// Cart subtotal in JMD.
final cartSubtotalProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).sumBy((CartItem i) => i.lineTotal),
);
