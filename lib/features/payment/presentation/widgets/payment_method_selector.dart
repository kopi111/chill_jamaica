import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../domain/entities/payment_method.dart';

/// Radio-style list letting the customer pick card or cash on delivery.
class PaymentMethodSelector extends StatelessWidget {
  const PaymentMethodSelector({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final PaymentMethod selected;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: PaymentMethod.values
          .map(
            (PaymentMethod method) => _MethodTile(
              method: method,
              isSelected: method == selected,
              onTap: () => onSelected(method),
            ),
          )
          .toList(),
    );
  }
}

class _MethodTile extends StatelessWidget {
  const _MethodTile({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isSelected ? AppColors.primaryGreen : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                method.icon,
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      method.label,
                      style: context.textStyles.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      method.description,
                      style: context.textStyles.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? AppColors.primaryGreen : AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
