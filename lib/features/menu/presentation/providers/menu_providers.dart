import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/usecases/get_products.dart';

/// Wires the menu feature's dependency graph.

final productRemoteDataSourceProvider = Provider<ProductRemoteDataSource>(
  (ref) => FirestoreProductDataSource(ref.watch(firebaseFirestoreProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.watch(productRemoteDataSourceProvider)),
);

final getProductsProvider = Provider<GetProducts>(
  (ref) => GetProducts(ref.watch(productRepositoryProvider)),
);

/// Products for the menu screen. `AsyncValue` gives us loading/error/data for
/// free; pull-to-refresh calls `ref.invalidate(productsProvider)`.
final productsProvider = FutureProvider<List<Product>>(
  (ref) => ref.watch(getProductsProvider).call(),
);
