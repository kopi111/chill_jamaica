import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/cart_item.dart';
import '../../../menu/presentation/widgets/quantity_selector.dart';

/// One row in the cart: art, name/size, price, quantity stepper, swipe-to-delete.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey<String>(item.product.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.28,
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => _confirmRemove(context),
            backgroundColor: AppColors.urgentRed,
            foregroundColor: AppColors.white,
            icon: Icons.delete_outline_rounded,
            label: AppStrings.removeItem,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceSm),
          child: Row(
            children: <Widget>[
              _thumb(),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.product.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${item.product.sizeLabel} • ${Formatters.jmd(item.product.priceJmd)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.spaceSm),
                    QuantitySelector(
                      quantity: item.quantity,
                      min: 1,
                      onChanged: onQuantityChanged,
                    ),
                  ],
                ),
              ),
              Text(
                Formatters.jmd(item.lineTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb() => Container(
        height: 56,
        width: 56,
        decoration: BoxDecoration(
          gradient: AppColors.coconutPlaceholder,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
        alignment: Alignment.center,
        child: const Text('🥥', style: TextStyle(fontSize: 26)),
      );

  Future<void> _confirmRemove(BuildContext context) async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text(AppStrings.removeItem),
            content: const Text(AppStrings.removeItemConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Keep it'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Remove'),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) onRemove();
  }
}
