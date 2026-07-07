import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../models/product_model.dart';

/// Reads products from Cloud Firestore.
///
/// Throws [ServerException] on any Firestore error so the repository can map it
/// to a friendly [Failure].
abstract interface class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts();
  Stream<List<ProductModel>> watchProducts();
}

class FirestoreProductDataSource implements ProductRemoteDataSource {
  FirestoreProductDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'products';

  Query<Map<String, dynamic>> get _availableProducts => _firestore
      .collection(_collection)
      .where('is_available', isEqualTo: true)
      .orderBy('price_jmd');

  @override
  Future<List<ProductModel>> fetchProducts() async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await _availableProducts.get();
      return snapshot.docs.map(ProductModel.fromDoc).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to load products', cause: e);
    }
  }

  @override
  Stream<List<ProductModel>> watchProducts() => _availableProducts
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) =>
          s.docs.map(ProductModel.fromDoc).toList());
}
