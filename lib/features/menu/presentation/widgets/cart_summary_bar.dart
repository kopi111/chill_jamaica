import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../../order/presentation/providers/cart_provider.dart';

/// Sticky bottom bar summarising the cart. Hidden when the cart is empty.
class CartSummaryBar extends ConsumerWidget {
  const CartSummaryBar({required this.onViewCart, super.key});

  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(cartItemCountProvider);
    final int subtotal = ref.watch(cartSubtotalProvider);

    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      offset: count == 0 ? const Offset(0, 1) : Offset.zero,
      child: Material(
        color: AppColors.primaryGreen,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppDimensions.cartBarHeight,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppDimensions.spaceMd),
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$count item${count == 1 ? '' : 's'}',
                        style: const TextStyle(color: AppColors.white, fontSize: 12),
                      ),
                      Text(
                        Formatters.jmd(subtotal),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: count == 0 ? null : onViewCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryGold,
                      foregroundColor: AppColors.dark,
                    ),
                    icon: const Icon(Icons.shopping_cart_rounded, size: 18),
                    label: const Text(AppStrings.viewCart),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cart icon with an item-count badge, for app bars.
class CartBadgeIcon extends ConsumerWidget {
  const CartBadgeIcon({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = ref.watch(cartItemCountProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: AppStrings.viewCart,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.secondaryGold,
        textColor: AppColors.dark,
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
