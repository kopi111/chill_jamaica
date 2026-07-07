import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Compact − / + stepper with an animated count.
///
/// Purely presentational: it reports changes via [onChanged] and never holds
/// its own source of truth.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    required this.quantity,
    required this.onChanged,
    this.min = 0,
    this.max = 99,
    super.key,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCream,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: quantity > min ? () => onChanged(quantity - 1) : null,
            semanticLabel: 'Decrease quantity',
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (Widget child, Animation<double> anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Padding(
              key: ValueKey<int>(quantity),
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceSm),
              child: Text(
                '$quantity',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: quantity < max ? () => onChanged(quantity + 1) : null,
            semanticLabel: 'Increase quantity',
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      tooltip: semanticLabel,
      icon: Icon(
        icon,
        color: enabled ? AppColors.primaryGreen : AppColors.textSecondary,
      ),
    );
  }
}
