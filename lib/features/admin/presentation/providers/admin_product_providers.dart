import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../menu/domain/entities/product.dart';
import '../../../menu/presentation/providers/menu_providers.dart';

/// Wiring for the admin product-catalogue editor. Reuses the menu feature's
/// [productRepositoryProvider] so products stay a single source of truth.

/// Live feed of every product (available or not) for the admin list.
final allProductsProvider = StreamProvider.autoDispose<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAllProducts(),
);

/// Drives create / update / delete from the admin editor: idle → loading → error.
class AdminProductController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Creates the product when [product] has no id, otherwise updates it.
  /// Returns true on success.
  Future<bool> save(Product product) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(() {
      final repository = ref.read(productRepositoryProvider);
      return product.id.isEmpty
          ? repository.addProduct(product)
          : repository.updateProduct(product);
    });
    return !state.hasError;
  }

  /// Removes the product with [id]. Returns true on success.
  Future<bool> delete(String id) async {
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(productRepositoryProvider).deleteProduct(id),
    );
    return !state.hasError;
  }

  /// Flips a product's availability without opening the full editor.
  Future<bool> toggleAvailability(Product product) =>
      save(product.copyWith(isAvailable: !product.isAvailable));
}

final adminProductControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminProductController, void>(
  AdminProductController.new,
);
