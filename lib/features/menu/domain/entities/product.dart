import 'package:flutter/foundation.dart';

/// A coconut-water product the customer can order.
///
/// Pure domain entity — no Firestore or JSON concerns live here.
@immutable
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sizeMl,
    required this.priceJmd,
    required this.imagePlaceholder,
    required this.isAvailable,
  });

  final String id;

  /// Display name, e.g. `1/2 Gallon`.
  final String name;

  /// Volume in millilitres, e.g. `1890` for a half gallon.
  final int sizeMl;

  /// Price in whole Jamaican dollars.
  final int priceJmd;

  /// Asset path or remote URL for the product art (placeholder until real art).
  final String imagePlaceholder;

  /// Whether the product can currently be ordered.
  final bool isAvailable;

  /// Human-friendly volume, e.g. `500ml` or `1.89L`.
  String get sizeLabel =>
      sizeMl < 1000 ? '${sizeMl}ml' : '${(sizeMl / 1000).toStringAsFixed(2)}L';

  /// True when a real remote image is set (vs. the gradient fallback).
  bool get hasImage => imagePlaceholder.trim().startsWith('http');

  /// Returns a copy with the given fields replaced — used by the admin editor.
  Product copyWith({
    String? id,
    String? name,
    int? sizeMl,
    int? priceJmd,
    String? imagePlaceholder,
    bool? isAvailable,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sizeMl: sizeMl ?? this.sizeMl,
      priceJmd: priceJmd ?? this.priceJmd,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Product && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
