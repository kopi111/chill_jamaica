import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/launchers.dart';
import '../../../order/domain/entities/customer_order.dart';
import '../../../order/domain/entities/delivery_details.dart';
import '../../../order/domain/entities/order_status.dart';

/// Rich order card for the admin dashboard: tappable phone/address, status
/// dropdown, and swipe actions (mark delivered / call customer).
class AdminOrderCard extends StatelessWidget {
  const AdminOrderCard({
    required this.order,
    required this.onStatusChanged,
    super.key,
  });

  final CustomerOrder order;
  final ValueChanged<OrderStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey<String>(order.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.3,
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => _call(context),
            backgroundColor: AppColors.statusNew,
            foregroundColor: AppColors.white,
            icon: Icons.call,
            label: 'Call',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.3,
        children: <Widget>[
          SlidableAction(
            onPressed: (_) => onStatusChanged(OrderStatus.delivered),
            backgroundColor: AppColors.statusDelivered,
            foregroundColor: AppColors.white,
            icon: Icons.check_circle,
            label: 'Delivered',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppDimensions.spaceXs),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Header(order: order),
              const Divider(height: AppDimensions.spaceLg),
              _ContactRow(
                icon: Icons.phone,
                text: Formatters.prettyPhone(order.customerPhone),
                onTap: () => _call(context),
              ),
              const SizedBox(height: AppDimensions.spaceXs),
              _ContactRow(
                icon: order.delivery.method == DeliveryMethod.gps
                    ? Icons.place
                    : Icons.home_outlined,
                text: order.delivery.method == DeliveryMethod.gps
                    ? '📍 ${order.delivery.displayAddress}'
                    : order.delivery.displayAddress,
                onTap: () => _openMaps(context),
              ),
              const SizedBox(height: AppDimensions.spaceSm),
              Text(order.itemSummary, style: context.textStyles.bodyLarge),
              const SizedBox(height: AppDimensions.spaceSm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    Formatters.jmd(order.total),
                    style: context.textStyles.titleMedium?.copyWith(
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  _StatusDropdown(
                    status: order.status,
                    onChanged: onStatusChanged,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context) async {
    final bool ok = await Launchers.dial(order.customerPhone);
    if (!ok && context.mounted) {
      context.showSnack('No dialer available on this device.', isError: true);
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final bool ok = await Launchers.maps(order.delivery);
    if (!ok && context.mounted) {
      context.showSnack('Could not open maps.', isError: true);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: order.id));
              context.showSnack('Order id copied.');
            },
            child: Text(
              order.shortId,
              style: context.textStyles.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        Text(
          Formatters.relativeTime(order.createdAt),
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.accentBrown),
          const SizedBox(width: AppDimensions.spaceSm),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodyMedium?.copyWith(
                color: AppColors.statusNew,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.status, required this.onChanged});

  final OrderStatus status;
  final ValueChanged<OrderStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<OrderStatus>(
      value: status,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      onChanged: (OrderStatus? next) {
        if (next != null && next != status) onChanged(next);
      },
      items: OrderStatus.values
          .map(
            (OrderStatus s) => DropdownMenuItem<OrderStatus>(
              value: s,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.circle, size: 10, color: s.color),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Text(s.label),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
