import '../entities/customer_order.dart';
import '../entities/order_draft.dart';

/// Result of a place-order attempt.
enum SubmitOutcome {
  /// Written to Firestore successfully.
  submitted,

  /// Device offline — queued locally, will sync when back online.
  queuedOffline,
}

/// The order id together with how it was persisted.
class PlacedOrder {
  const PlacedOrder({required this.orderId, required this.outcome});

  final String orderId;
  final SubmitOutcome outcome;
}

/// Contract for creating and reading customer orders.
abstract interface class OrderRepository {
  /// Places an order. Falls back to a local queue when offline.
  ///
  /// Throws a [Failure] on a genuine (non-connectivity) error.
  Future<PlacedOrder> placeOrder(OrderDraft draft);

  /// Orders for one customer phone, newest first.
  Future<List<CustomerOrder>> getOrdersByPhone(String customerPhone);

  /// Live stream of a customer's orders for the "My Orders" screen.
  Stream<List<CustomerOrder>> watchOrdersByPhone(String customerPhone);

  /// Flushes any locally-queued orders to Firestore. Returns how many synced.
  Future<int> syncQueuedOrders();
}
