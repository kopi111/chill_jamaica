import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/customer_order.dart';
import '../models/order_model.dart';

/// Reads and writes orders in Cloud Firestore.
abstract interface class OrderRemoteDataSource {
  /// Writes a new order and returns its generated id.
  Future<String> createOrder(Map<String, dynamic> firestorePayload);
  Future<List<CustomerOrder>> ordersByPhone(String customerPhone);
  Stream<List<CustomerOrder>> watchOrdersByPhone(String customerPhone);
}

class FirestoreOrderDataSource implements OrderRemoteDataSource {
  FirestoreOrderDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'orders';

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection(_collection);

  Query<Map<String, dynamic>> _byPhone(String phone) => _orders
      .where('customerPhone', isEqualTo: phone)
      .orderBy('createdAt', descending: true);

  @override
  Future<String> createOrder(Map<String, dynamic> firestorePayload) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref =
          await _orders.add(firestorePayload);
      return ref.id;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to submit order', cause: e);
    }
  }

  @override
  Future<List<CustomerOrder>> ordersByPhone(String customerPhone) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _byPhone(customerPhone).get();
      return snapshot.docs.map(OrderModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to load orders', cause: e);
    }
  }

  @override
  Stream<List<CustomerOrder>> watchOrdersByPhone(String customerPhone) =>
      _byPhone(customerPhone).snapshots().map(
            (QuerySnapshot<Map<String, dynamic>> s) =>
                s.docs.map(OrderModel.fromDoc).toList(),
          );
}
