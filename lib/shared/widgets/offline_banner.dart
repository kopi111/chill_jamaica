import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../providers/connectivity_provider.dart';

/// A thin banner that slides in whenever the device goes offline.
///
/// Wrap a screen body with this so customers know an order will be queued
/// rather than lost.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isOnline = ref.watch(isOnlineProvider).value ?? true;
    return Column(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isOnline ? const SizedBox.shrink() : const _Banner(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentBrown,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spaceMd,
            vertical: AppDimensions.spaceSm,
          ),
          child: Row(
            children: <Widget>[
              const Icon(Icons.cloud_off_rounded, color: AppColors.white, size: 18),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  AppStrings.offlineBanner,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
