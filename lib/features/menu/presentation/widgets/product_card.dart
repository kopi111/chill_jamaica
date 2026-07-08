import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/product_image.dart';
import '../../../order/presentation/providers/cart_provider.dart';
import '../../domain/entities/product.dart';
import 'quantity_selector.dart';

/// A single product tile: art placeholder, size, price, quantity stepper and
/// an add-to-cart button with a subtle tap animation.
class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({required this.product, super.key});

  final Product product;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tapController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    lowerBound: 0,
    upperBound: 0.06,
  );

  /// Draft quantity shown on the card before it's committed to the cart.
  int _draftQuantity = 1;

  @override
  void dispose() {
    _tapController.dispose();
    super.dispose();
  }

  Future<void> _addToCart() async {
    await _tapController.forward();
    await _tapController.reverse();
    ref.read(cartProvider.notifier).add(widget.product, quantity: _draftQuantity);
    if (!mounted) return;
    context.showSnack('${AppStrings.allGood} Added to cart.');
    setState(() => _draftQuantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final Product product = widget.product;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(child: ProductImage(imageRef: product.imagePlaceholder)),
            const SizedBox(height: AppDimensions.spaceSm),
            Text(
              product.name,
              style: context.textStyles.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              product.sizeLabel,
              style: context.textStyles.bodySmall,
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              Formatters.jmd(product.priceJmd),
              style: context.textStyles.titleMedium?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Align(
              alignment: Alignment.centerLeft,
              child: QuantitySelector(
                quantity: _draftQuantity,
                min: 1,
                onChanged: (int q) => setState(() => _draftQuantity = q),
              ),
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.94).animate(_tapController),
              child: ElevatedButton(
                onPressed: _addToCart,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(40),
                  backgroundColor: AppColors.secondaryGold,
                  foregroundColor: AppColors.dark,
                ),
                child: const Text(AppStrings.addToCart),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
