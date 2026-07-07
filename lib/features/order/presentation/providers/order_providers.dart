import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../data/datasources/order_remote_datasource.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/get_orders_by_phone.dart';
import '../../domain/usecases/place_order.dart';

/// Dependency graph for the order feature.

final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>(
  (ref) => FirestoreOrderDataSource(ref.watch(firebaseFirestoreProvider)),
);

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepositoryImpl(
    remote: ref.watch(orderRemoteDataSourceProvider),
    local: ref.watch(orderLocalDataSourceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

final placeOrderProvider = Provider<PlaceOrder>(
  (ref) => PlaceOrder(ref.watch(orderRepositoryProvider)),
);

final getOrdersByPhoneProvider = Provider<GetOrdersByPhone>(
  (ref) => GetOrdersByPhone(ref.watch(orderRepositoryProvider)),
);

/// Live order history for a given phone number (E.164). Family keyed by phone.
final ordersByPhoneProvider =
    StreamProvider.family<List<CustomerOrder>, String>((ref, phone) {
  return ref.watch(orderRepositoryProvider).watchOrdersByPhone(phone);
});

/// Drains any offline-queued orders; call after connectivity returns.
final syncQueuedOrdersProvider = FutureProvider.autoDispose<int>((ref) {
  final bool online = ref.watch(isOnlineProvider).value ?? false;
  if (!online) return Future<int>.value(0);
  return ref.watch(orderRepositoryProvider).syncQueuedOrders();
});
