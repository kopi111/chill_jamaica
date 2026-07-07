import '../entities/product.dart';

/// Contract for reading products. Implemented in the data layer.
///
/// Implementations throw a [Failure] (from `core/errors`) on error rather than
/// returning null, so callers can surface friendly copy.
abstract interface class ProductRepository {
  /// Available products, ordered for display. Never null; empty when none.
  Future<List<Product>> getProducts();

  /// Live stream of products for reactive UIs (pull-to-refresh still calls
  /// [getProducts]).
  Stream<List<Product>> watchProducts();
}
