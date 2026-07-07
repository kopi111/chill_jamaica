import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_datasource.dart';

/// Default [ProductRepository] backed by Firestore.
///
/// Translates low-level [Exception]s into user-facing [Failure]s.
class ProductRepositoryImpl implements ProductRepository {
  const ProductRepositoryImpl(this._remote);

  final ProductRemoteDataSource _remote;

  @override
  Future<List<Product>> getProducts() async {
    try {
      return await _remote.fetchProducts();
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } catch (_) {
      throw const ServerFailure();
    }
  }

  @override
  Stream<List<Product>> watchProducts() =>
      _remote.watchProducts().handleError((Object _) {
        throw const ServerFailure();
      });
}
