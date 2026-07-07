import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/delivery_details.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/repositories/order_repository.dart';
import 'cart_provider.dart';
import 'order_providers.dart';

/// Orchestrates placing an order from the checkout screen.
///
/// Guards against the double-submit / rapid-tap problem: while a submission is
/// in flight the controller is `loading`, and [submit] no-ops until it settles.
class CheckoutController extends AutoDisposeAsyncNotifier<PlacedOrder?> {
  @override
  Future<PlacedOrder?> build() async => null;

  Future<void> submit({
    required String phoneE164,
    required DeliveryDetails delivery,
  }) async {
    if (state.isLoading) return; // ignore rapid re-taps

    final List<CartItem> cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      state = AsyncValue<PlacedOrder?>.error(
        const ServerFailure('Yuh cart empty — add someting first.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue<PlacedOrder?>.loading();
    state = await AsyncValue.guard(() async {
      final OrderDraft draft = OrderDraft(
        customerPhone: phoneE164,
        delivery: delivery,
        cartItems: cartItems,
      );
      final PlacedOrder placed = await ref.read(placeOrderProvider).call(draft);
      ref.read(cartProvider.notifier).clear();
      return placed;
    });
  }
}

final checkoutControllerProvider =
    AsyncNotifierProvider.autoDispose<CheckoutController, PlacedOrder?>(
  CheckoutController.new,
);
