import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../order/data/models/order_model.dart';
import '../../../order/domain/entities/customer_order.dart';
import '../../../order/domain/entities/order_status.dart';

/// Admin-side reads/writes over the shared `orders` collection.
class AdminOrderDataSource {
  AdminOrderDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'orders';

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(_collection);

  /// Live order feed, newest first, optionally filtered by [status].
  Stream<List<CustomerOrder>> watchOrders({OrderStatus? status}) {
    Query<Map<String, dynamic>> query =
        _orders.orderBy('createdAt', descending: true);
    if (status != null) {
      query = _orders
          .where('status', isEqualTo: status.wireValue)
          .orderBy('createdAt', descending: true);
    }
    return query.snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> s) =>
              s.docs.map(OrderModel.fromDoc).toList(),
        );
  }

  /// Transitions an order to [status], appending to its status history.
  Future<void> updateStatus({
    required String orderId,
    required OrderStatus status,
    required String adminId,
  }) async {
    try {
      await _orders.doc(orderId).update(<String, dynamic>{
        'status': status.wireValue,
        'updatedAt': FieldValue.serverTimestamp(),
        'adminId': adminId,
        'statusHistory': FieldValue.arrayUnion(<Map<String, dynamic>>[
          <String, dynamic>{
            'status': status.wireValue,
            'timestamp': Timestamp.now(),
            'updatedBy': adminId,
          },
        ]),
      });
    } on FirebaseException catch (e) {
      throw ServerException('Failed to update order', cause: e);
    }
  }
}
