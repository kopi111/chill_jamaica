import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

/// Firestore serialization for [Product].
///
/// Keeping (de)serialization in the data layer keeps the domain entity free of
/// any Firestore dependency.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.sizeMl,
    required super.priceJmd,
    required super.imagePlaceholder,
    required super.isAvailable,
  });

  /// Builds a model from a Firestore document, tolerating missing fields.
  factory ProductModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? const <String, dynamic>{};
    return ProductModel(
      id: doc.id,
      name: (data['name'] as String?) ?? 'Coconut Water',
      sizeMl: (data['size_ml'] as num?)?.toInt() ?? 0,
      priceJmd: (data['price_jmd'] as num?)?.toInt() ?? 0,
      imagePlaceholder: (data['image_placeholder'] as String?) ?? '',
      isAvailable: (data['is_available'] as bool?) ?? true,
    );
  }

  /// Wraps a domain [Product] so the admin editor can persist it.
  factory ProductModel.fromEntity(Product product) => ProductModel(
        id: product.id,
        name: product.name,
        sizeMl: product.sizeMl,
        priceJmd: product.priceJmd,
        imagePlaceholder: product.imagePlaceholder,
        isAvailable: product.isAvailable,
      );

  /// Document payload for a brand-new product; stamps both timestamps.
  Map<String, dynamic> toCreateMap() => <String, dynamic>{
        ..._fields(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Update payload; refreshes `updatedAt` without clobbering `createdAt`.
  Map<String, dynamic> toUpdateMap() => <String, dynamic>{
        ..._fields(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _fields() => <String, dynamic>{
        'name': name,
        'size_ml': sizeMl,
        'price_jmd': priceJmd,
        'image_placeholder': imagePlaceholder,
        'is_available': isAvailable,
      };
}
