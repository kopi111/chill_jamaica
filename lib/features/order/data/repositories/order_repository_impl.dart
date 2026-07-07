import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/network/retry.dart';
import '../../domain/entities/customer_order.dart';
import '../../domain/entities/order_draft.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';
import '../datasources/order_remote_datasource.dart';
import '../models/order_model.dart';

/// Default [OrderRepository].
///
/// Write path: check connectivity → try Firestore (with retry) → on offline or
/// network failure, queue locally and report [SubmitOutcome.queuedOffline].
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl({
    required OrderRemoteDataSource remote,
    required OrderLocalDataSource local,
    required ConnectivityService connectivity,
    DateTime Function() now = DateTime.now,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity,
        _now = now;

  final OrderRemoteDataSource _remote;
  final OrderLocalDataSource _local;
  final ConnectivityService _connectivity;
  final DateTime Function() _now;

  @override
  Future<PlacedOrder> placeOrder(OrderDraft draft) async {
    final String queueKey = draft.idempotencyKey(_now());

    if (!await _connectivity.isOnline) {
      return _queue(draft, queueKey);
    }

    try {
      final String id = await retryWithBackoff(
        () => _remote.createOrder(OrderModel.draftToFirestore(draft)),
        retryIf: (Object e) => e is ServerException,
      );
      return PlacedOrder(orderId: id, outcome: SubmitOutcome.submitted);
    } on ServerException {
      // Network flaked mid-submit — don't lose the order, queue it.
      return _queue(draft, queueKey);
    } catch (_) {
      throw const ServerFailure();
    }
  }

  Future<PlacedOrder> _queue(OrderDraft draft, String key) async {
    try {
      await _local.enqueue(key, OrderModel.draftToQueueJson(draft));
      return PlacedOrder(orderId: key, outcome: SubmitOutcome.queuedOffline);
    } on CacheException catch (e) {
      throw CacheFailure(e.message);
    }
  }

  @override
  Future<List<CustomerOrder>> getOrdersByPhone(String customerPhone) async {
    try {
      return await _remote.ordersByPhone(customerPhone);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const ServerFailure();
    }
  }

  @override
  Stream<List<CustomerOrder>> watchOrdersByPhone(String customerPhone) =>
      _remote.watchOrdersByPhone(customerPhone).handleError((Object _) {
        throw const ServerFailure();
      });

  @override
  Future<int> syncQueuedOrders() async {
    if (!await _connectivity.isOnline) return 0;
    final Map<String, Map<String, dynamic>> pending = await _local.pending();
    int synced = 0;
    for (final MapEntry<String, Map<String, dynamic>> entry in pending.entries) {
      try {
        await _remote.createOrder(OrderModel.queueJsonToFirestore(entry.value));
        await _local.remove(entry.key);
        synced++;
      } on ServerException {
        // Still failing — leave it queued for the next attempt.
        break;
      }
    }
    return synced;
  }
}
