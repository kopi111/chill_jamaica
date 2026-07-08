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

  /// Every product, available or not — for the admin catalogue.
  Stream<List<ProductModel>> watchAllProducts();

  Future<void> addProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
}

class FirestoreProductDataSource implements ProductRemoteDataSource {
  FirestoreProductDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  static const String _collection = 'products';

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(_collection);

  Query<Map<String, dynamic>> get _availableProducts => _products
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

  @override
  Stream<List<ProductModel>> watchAllProducts() => _products
      .orderBy('price_jmd')
      .snapshots()
      .map((QuerySnapshot<Map<String, dynamic>> s) =>
          s.docs.map(ProductModel.fromDoc).toList());

  @override
  Future<void> addProduct(ProductModel product) async {
    try {
      await _products.add(product.toCreateMap());
    } on FirebaseException catch (e) {
      throw ServerException('Failed to add product', cause: e);
    }
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    try {
      await _products.doc(product.id).update(product.toUpdateMap());
    } on FirebaseException catch (e) {
      throw ServerException('Failed to update product', cause: e);
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _products.doc(id).delete();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to delete product', cause: e);
    }
  }
}
