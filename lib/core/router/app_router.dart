import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/domain/entities/admin_user.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_login_screen.dart';
import '../../features/admin/presentation/screens/admin_product_form_screen.dart';
import '../../features/admin/presentation/screens/admin_products_screen.dart';
import '../../features/menu/domain/entities/product.dart';
import '../../features/menu/presentation/screens/menu_screen.dart';
import '../../features/order/presentation/screens/cart_screen.dart';
import '../../features/order/presentation/screens/my_orders_screen.dart';
import '../../features/order/presentation/screens/order_confirmation_screen.dart';
import 'app_routes.dart';

/// Builds the app's [GoRouter], guarding admin routes behind authentication.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.menu,
    refreshListenable: _AuthRefresh(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final AdminUser? admin = ref.read(adminAuthStateProvider).valueOrNull;
      final bool goingToAdminArea = state.matchedLocation
          .startsWith('/admin');
      final bool onLoginPage = state.matchedLocation == AppRoutes.adminLogin;

      // Unauthenticated user reaching for the dashboard → send to login.
      if (goingToAdminArea && !onLoginPage && admin == null) {
        return AppRoutes.adminLogin;
      }
      // Already signed in but sitting on login → jump to the dashboard.
      if (onLoginPage && admin != null) {
        return AppRoutes.adminDashboard;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.menu,
        builder: (_, _) => const MenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (_, _) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.orderConfirmation,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          if (extra is! OrderConfirmationArgs) {
            // Deep-linked without args — fall back to the menu.
            return const MenuScreen();
          }
          return OrderConfirmationScreen(args: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.myOrders,
        builder: (_, _) => const MyOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminLogin,
        builder: (_, _) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (_, _) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        builder: (_, _) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProductForm,
        builder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          // Editing an existing product passes it as `extra`; a null means
          // "create a new product".
          return AdminProductFormScreen(
            product: extra is Product ? extra : null,
          );
        },
      ),
    ],
    errorBuilder: (BuildContext context, GoRouterState state) => Scaffold(
      body: Center(child: Text('Route not found: ${state.uri}')),
    ),
  );
});

/// Bridges Riverpod's auth stream to go_router's [Listenable] so redirects
/// re-run on sign-in / sign-out.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen<AsyncValue<AdminUser?>>(
      adminAuthStateProvider,
      (_, _) => notifyListeners(),
      fireImmediately: true,
    );
    ref.onDispose(() => _sub.close());
  }

  late final ProviderSubscription<AsyncValue<AdminUser?>> _sub;
}
