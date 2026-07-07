import '../entities/product.dart';
import '../repositories/product_repository.dart';

/// Fetches the products to show on the menu.
///
/// A thin use case, but it keeps the presentation layer depending on the domain
/// contract rather than a concrete repository.
class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call() => _repository.getProducts();
}
