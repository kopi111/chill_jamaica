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

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'size_ml': sizeMl,
        'price_jmd': priceJmd,
        'image_placeholder': imagePlaceholder,
        'is_available': isAvailable,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
