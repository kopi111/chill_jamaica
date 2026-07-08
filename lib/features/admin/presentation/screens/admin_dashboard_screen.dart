import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_indicator.dart';
import '../../../order/domain/entities/customer_order.dart';
import '../../../order/domain/entities/order_status.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_order_card.dart';

/// Real-time order console for admins.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  /// Tracks the newest order id we've already alerted on, so a fresh order
  /// buzzes exactly once.
  String? _lastSeenOrderId;

  @override
  void initState() {
    super.initState();
    // Register this admin device for push once the dashboard opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? uid = ref.read(adminAuthStateProvider).valueOrNull?.uid;
      if (uid != null) {
        ref.read(notificationServiceProvider).initializeForAdmin(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _watchForNewOrders();
    final AsyncValue<List<CustomerOrder>> orders =
        ref.watch(adminOrdersProvider);
    final int today = ref.watch(todaysOrderCountProvider);
    final int pending = ref.watch(pendingOrderCountProvider);
    final String adminEmail = ref
            .watch(adminAuthStateProvider)
            .valueOrNull
            ?.shortName ??
        'Admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboardTitle),
        actions: <Widget>[
          IconButton(
            tooltip: AppStrings.manageProducts,
            onPressed: () => context.push(AppRoutes.adminProducts),
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          _NotificationBell(count: pending),
          IconButton(
            tooltip: AppStrings.logout,
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: <Widget>[
              _CounterStrip(email: adminEmail, today: today, pending: pending),
              const _FilterChips(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.showSnack(
          '${AppStrings.comingSoon} CSV export lands here.',
        ),
        backgroundColor: AppColors.secondaryGold,
        foregroundColor: AppColors.dark,
        icon: const Icon(Icons.download_rounded),
        label: const Text(AppStrings.exportTodaysOrders),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminOrdersProvider),
        child: orders.when(
          loading: () => const LoadingIndicator(message: 'Loading orders…'),
          error: (Object error, _) => ErrorView(
            message: AppStrings.serverError,
            onRetry: () => ref.invalidate(adminOrdersProvider),
          ),
          data: (List<CustomerOrder> list) => list.isEmpty
              ? ListView(
                  children: const <Widget>[
                    SizedBox(height: 120),
                    EmptyView(message: 'No orders yet — soon come!', emoji: '📭'),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceMd,
                    AppDimensions.spaceMd,
                    AppDimensions.spaceMd,
                    96,
                  ),
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) =>
                      _DashboardOrderCard(order: list[index]),
                ),
        ),
      ),
    );
  }

  /// Buzzes + plays a sound once when a new order arrives at the top of the feed.
  void _watchForNewOrders() {
    ref.listen<AsyncValue<List<CustomerOrder>>>(adminOrdersProvider,
        (AsyncValue<List<CustomerOrder>>? prev,
            AsyncValue<List<CustomerOrder>> next) {
      final List<CustomerOrder>? orders = next.valueOrNull;
      if (orders == null || orders.isEmpty) return;
      final String newestId = orders.first.id;
      final bool isFirstLoad = _lastSeenOrderId == null;
      if (!isFirstLoad && newestId != _lastSeenOrderId) {
        HapticFeedback.mediumImpact();
        SystemSound.play(SystemSoundType.alert);
        if (mounted) {
          context.showSnack(AppStrings.newOrderNotification);
        }
      }
      _lastSeenOrderId = newestId;
    });
  }

  Future<void> _confirmLogout() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            title: const Text(AppStrings.logout),
            content: const Text(AppStrings.logoutConfirm),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(AppStrings.logout),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await ref.read(adminRepositoryProvider).signOut();
    ref.read(hardcodedAdminSessionProvider.notifier).state = null;
    if (mounted) context.go(AppRoutes.adminLogin);
  }
}

/// Binds an [AdminOrderCard] to the status-update datasource, stamping the
/// change with the signed-in admin's id.
class _DashboardOrderCard extends ConsumerWidget {
  const _DashboardOrderCard({required this.order});

  final CustomerOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdminOrderCard(
      order: order,
      onStatusChanged: (OrderStatus status) => _updateStatus(context, ref, status),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    OrderStatus status,
  ) async {
    final String adminId =
        ref.read(adminAuthStateProvider).valueOrNull?.uid ?? 'unknown';
    try {
      await ref.read(adminOrderDataSourceProvider).updateStatus(
            orderId: order.id,
            status: status,
            adminId: adminId,
          );
      if (context.mounted) {
        context.showSnack('${order.shortId} → ${status.label}');
      }
    } catch (_) {
      if (context.mounted) {
        context.showSnack(AppStrings.serverError, isError: true);
      }
    }
  }
}

/// Notification bell with an unread (pending-order) badge.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.showSnack('$count order${count == 1 ? '' : 's'} pending.'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: AppColors.urgentRed,
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}

/// "Signed in as … · N orders today · M pending" strip under the app bar.
class _CounterStrip extends StatelessWidget {
  const _CounterStrip({
    required this.email,
    required this.today,
    required this.pending,
  });

  final String email;
  final int today;
  final int pending;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primaryGreen,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceMd,
        vertical: AppDimensions.spaceXs,
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.person_outline, color: AppColors.white, size: 16),
          const SizedBox(width: AppDimensions.spaceXs),
          Expanded(
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.white),
            ),
          ),
          Text(
            '$today today • $pending pending',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status filter chips: All | New | Processing | Out for Delivery | Delivered.
class _FilterChips extends ConsumerWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final OrderStatus? selected = ref.watch(adminOrderFilterProvider);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceSm),
        children: <Widget>[
          _chip(ref, label: 'All', value: null, isSelected: selected == null),
          ...OrderStatus.values.map(
            (OrderStatus s) => _chip(
              ref,
              label: s.label,
              value: s,
              isSelected: selected == s,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    WidgetRef ref, {
    required String label,
    required OrderStatus? value,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXs),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) =>
            ref.read(adminOrderFilterProvider.notifier).state = value,
      ),
    );
  }
}
