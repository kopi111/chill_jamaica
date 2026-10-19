import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../account/domain/entities/customer_profile.dart';
import '../../../account/presentation/providers/account_providers.dart';
import '../../../payment/domain/entities/payment_summary.dart';
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

  /// Places the order, returning it on success and null when it failed.
  ///
  /// A failure is left in [state] so the screen's listener can show it; the
  /// caller only has to decide where to navigate next.
  Future<PlacedOrder?> submit({
    required String phoneE164,
    required DeliveryDetails delivery,
    required PaymentSummary payment,
  }) async {
    if (state.isLoading) return null; // ignore rapid re-taps

    final List<CartItem> cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) {
      state = AsyncValue<PlacedOrder?>.error(
        const ServerFailure('Yuh cart empty — add someting first.'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue<PlacedOrder?>.loading();
    state = await AsyncValue.guard(() async {
      final OrderDraft draft = OrderDraft(
        customerPhone: phoneE164,
        customerId: _signedInCustomerId(),
        delivery: delivery,
        cartItems: cartItems,
        payment: payment,
      );
      final PlacedOrder placed = await ref.read(placeOrderProvider).call(draft);
      ref.read(cartProvider.notifier).clear();
      return placed;
    });
    return state.valueOrNull;
  }

  String? _signedInCustomerId() {
    final CustomerProfile? customer =
        ref.read(signedInCustomerProvider).valueOrNull;
    return customer?.uid;
  }
}

final checkoutControllerProvider =
    AsyncNotifierProvider.autoDispose<CheckoutController, PlacedOrder?>(
  CheckoutController.new,
);
