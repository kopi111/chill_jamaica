import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../menu/domain/entities/product.dart';
import '../providers/admin_product_providers.dart';

/// Admin catalogue: list every product with quick edit / availability / delete.
class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Product>> products = ref.watch(allProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.manageProducts)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminProductForm),
        backgroundColor: AppColors.secondaryGold,
        foregroundColor: AppColors.dark,
        icon: const Icon(Icons.add_rounded),
        label: const Text(AppStrings.addProduct),
      ),
      body: products.when(
        loading: () => const LoadingIndicator(message: 'Loading products…'),
        error: (Object error, _) => ErrorView(
          message: AppStrings.serverError,
          onRetry: () => ref.invalidate(allProductsProvider),
        ),
        data: (List<Product> list) => list.isEmpty
            ? const EmptyView(message: AppStrings.noProductsYet, emoji: '🥥')
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceMd,
                  AppDimensions.spaceMd,
                  AppDimensions.spaceMd,
                  96,
                ),
                itemCount: list.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppDimensions.spaceSm),
                itemBuilder: (BuildContext context, int index) =>
                    _ProductRow(product: list[index]),
              ),
      ),
    );
  }
}

/// One catalogue row: thumbnail, name/size/price, availability switch and menu.
class _ProductRow extends ConsumerWidget {
  const _ProductRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () =>
            context.push(AppRoutes.adminProductForm, extra: product),
        leading: _Thumbnail(product: product),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${product.sizeLabel} • ${Formatters.jmd(product.priceJmd)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Switch(
              value: product.isAvailable,
              onChanged: (_) => _toggle(context, ref),
            ),
            _RowMenu(
              onEdit: () =>
                  context.push(AppRoutes.adminProductForm, extra: product),
              onDelete: () => _confirmDelete(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final bool ok = await ref
        .read(adminProductControllerProvider.notifier)
        .toggleAvailability(product);
    if (context.mounted && !ok) {
      context.showSnack(AppStrings.serverError, isError: true);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text(AppStrings.deleteProduct),
            content: const Text(AppStrings.deleteProductConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.urgentRed,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(AppStrings.deleteProduct),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;

    final bool ok = await ref
        .read(adminProductControllerProvider.notifier)
        .delete(product.id);
    if (context.mounted) {
      context.showSnack(
        ok ? AppStrings.productDeleted : AppStrings.serverError,
        isError: !ok,
      );
    }
  }
}

/// Square product thumbnail — remote image, bundled asset, or brand-logo default.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: ProductImage(imageRef: product.imagePlaceholder),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      onSelected: (VoidCallback action) => action(),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<VoidCallback>>[
        PopupMenuItem<VoidCallback>(
          value: onEdit,
          child: const Text(AppStrings.editProduct),
        ),
        PopupMenuItem<VoidCallback>(
          value: onDelete,
          child: const Text(
            AppStrings.deleteProduct,
            style: TextStyle(color: AppColors.urgentRed),
          ),
        ),
      ],
    );
  }
}
