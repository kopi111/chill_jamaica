import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/order/presentation/providers/order_providers.dart';
import 'shared/providers/connectivity_provider.dart';

/// Customer/order app: menu, cart, checkout and order lookup. Also flushes any
/// offline order queue whenever connectivity returns.
class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _syncQueueWhenOnline(ref);
    return _AppShell(
      title: AppStrings.appName,
      router: ref.watch(customerRouterProvider),
    );
  }

  /// When the device comes back online, drain any queued offline orders.
  void _syncQueueWhenOnline(WidgetRef ref) {
    ref.listen<AsyncValue<bool>>(isOnlineProvider,
        (AsyncValue<bool>? previous, AsyncValue<bool> next) {
      final bool wasOffline = previous?.valueOrNull == false;
      final bool nowOnline = next.valueOrNull == true;
      if (wasOffline && nowOnline) {
        ref.invalidate(syncQueuedOrdersProvider);
      }
    });
  }
}

/// Admin app: login, live order dashboard and product management.
class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AppShell(
      title: AppStrings.adminAppName,
      router: ref.watch(adminRouterProvider),
    );
  }
}

/// Shared MaterialApp configuration for both apps.
class _AppShell extends StatelessWidget {
  const _AppShell({required this.title, required this.router});

  final String title;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const _NoStretchScrollBehavior(),
      routerConfig: router,
    );
  }
}

/// Removes the Android "stretch" overscroll effect app-wide, so lists don't
/// visually stretch when dragged past their edge.
class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
