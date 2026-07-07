import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Primary action button with a built-in loading state.
///
/// When [isLoading] is true the button disables itself and shows a spinner,
/// preventing the double-submit problem on slow networks.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effectiveOnPressed = isLoading ? null : onPressed;
    final Widget child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : _LabelWithIcon(label: label, icon: icon);

    if (isOutlined) {
      return OutlinedButton(onPressed: effectiveOnPressed, child: child);
    }
    return ElevatedButton(onPressed: effectiveOnPressed, child: child);
  }
}

class _LabelWithIcon extends StatelessWidget {
  const _LabelWithIcon({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: AppDimensions.spaceSm),
        Text(label),
      ],
    );
  }
}
