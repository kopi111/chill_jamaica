import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';

/// Data handed to the confirmation screen via go_router `extra`.
class OrderConfirmationArgs {
  const OrderConfirmationArgs({
    required this.orderId,
    required this.wasQueuedOffline,
    required this.deliveryAddress,
  });

  final String orderId;
  final bool wasQueuedOffline;
  final String deliveryAddress;
}

/// Success screen after placing an order.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({required this.args, super.key});

  final OrderConfirmationArgs args;

  String get _shortId =>
      '#${args.orderId.substring(0, args.orderId.length < 6 ? args.orderId.length : 6).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Spacer(),
              const _SuccessBadge(),
              const SizedBox(height: AppDimensions.spaceLg),
              Text(
                args.wasQueuedOffline ? 'Order Saved!' : AppStrings.orderPlaced,
                textAlign: TextAlign.center,
                style: context.textStyles.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(
                args.wasQueuedOffline
                    ? AppStrings.offlineBanner
                    : AppStrings.freshnessComing,
                textAlign: TextAlign.center,
                style: context.textStyles.bodyLarge,
              ),
              const SizedBox(height: AppDimensions.spaceLg),
              _InfoTile(label: 'Order ID', value: _shortId),
              _InfoTile(
                label: 'Deliver to',
                value: args.deliveryAddress.isEmpty
                    ? 'On file'
                    : args.deliveryAddress,
              ),
              if (!args.wasQueuedOffline)
                const _InfoTile(
                    label: 'Estimated', value: AppStrings.estimatedDelivery),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _share(context),
                icon: const Icon(Icons.share_outlined),
                label: const Text(AppStrings.shareOrder),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.myOrders),
                      child: const Text(AppStrings.trackMyOrder),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceMd),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.menu),
                      child: const Text(AppStrings.backToHome),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final String text =
        'Mi just ordered fresh coconut water from ${AppStrings.appName}! '
        'Order $_shortId 🥥🇯🇲';
    await Share.share(text);
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();

  @override
  Widget build(BuildContext context) {
    // Placeholder for a Lottie animation (assets/animations/order_success.json).
    return Center(
      child: Container(
        height: 120,
        width: 120,
        decoration: const BoxDecoration(
          gradient: AppColors.tropicalGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: AppColors.white, size: 64),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(label, style: context.textStyles.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textStyles.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
