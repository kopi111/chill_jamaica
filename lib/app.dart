import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/order/presentation/providers/order_providers.dart';
import 'shared/providers/connectivity_provider.dart';

/// Root widget: applies the theme and go_router, and flushes any offline order
/// queue whenever connectivity returns.
class ChillJamaicaApp extends ConsumerWidget {
  const ChillJamaicaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _syncQueueWhenOnline(ref);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: const _NoStretchScrollBehavior(),
      routerConfig: router,
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
