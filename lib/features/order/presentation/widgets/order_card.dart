import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/customer_order.dart';
import 'status_chip.dart';

/// Customer-facing summary card for one order in the history list.
class OrderCard extends StatelessWidget {
  const OrderCard({required this.order, super.key});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  order.shortId,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                StatusChip(order.status),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              Formatters.dateTime(order.createdAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: AppDimensions.spaceLg),
            Text(
              order.itemSummary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: AppDimensions.spaceSm),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                Formatters.jmd(order.total),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
