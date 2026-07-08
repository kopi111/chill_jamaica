import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../../order/domain/entities/customer_order.dart';
import '../../../order/domain/entities/order_status.dart';
import '../../data/datasources/admin_auth_datasource.dart';
import '../../data/datasources/admin_order_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';

// --- Auth wiring ---

final adminAuthDataSourceProvider = Provider<AdminAuthDataSource>(
  (ref) => AdminAuthDataSource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firebaseFirestoreProvider),
  ),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.watch(adminAuthDataSourceProvider)),
);

/// Locally-held admin session for the hard-coded login used while Firebase
/// Auth is not yet enabled on the project.
// TODO: remove once Firebase Auth (Email/Password) is enabled and real admin
// accounts exist; then adminAuthStateProvider can just reflect Firebase.
final hardcodedAdminSessionProvider = StateProvider<AdminUser?>((ref) => null);

/// Reactive sign-in state used by the router redirect and dashboard. Prefers
/// the local hard-coded session; otherwise reflects Firebase Auth.
final adminAuthStateProvider = StreamProvider<AdminUser?>((ref) {
  final AdminUser? local = ref.watch(hardcodedAdminSessionProvider);
  if (local != null) return Stream<AdminUser?>.value(local);
  return ref.watch(adminRepositoryProvider).authState();
});

/// Drives the login button: idle → loading → error.
class AdminLoginController extends AutoDisposeAsyncNotifier<void> {
  // Hard-coded admin credentials, used while Firebase Auth is not enabled.
  // TODO: remove once real Firebase Auth accounts exist.
  static const String _devAdminUsername = 'killquick';
  static const String _devAdminPassword = 'killquick123';

  @override
  Future<void> build() async {}

  Future<bool> signIn({required String email, required String password}) async {
    if (email.trim().toLowerCase() == _devAdminUsername &&
        password == _devAdminPassword) {
      ref.read(hardcodedAdminSessionProvider.notifier).state = const AdminUser(
        uid: 'local-admin',
        email: 'Killquick',
        displayName: 'Jamaica Chilled Admin',
        role: 'super_admin',
      );
      state = const AsyncValue<void>.data(null);
      return true;
    }

    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminRepositoryProvider).signIn(
            email: email,
            password: password,
          ),
    );
    return !state.hasError;
  }

  Future<String> sendReset(String email) async {
    try {
      await ref.read(adminRepositoryProvider).sendPasswordReset(email);
      return 'Reset link sent to $email';
    } on AuthFailure catch (e) {
      return e.message;
    }
  }
}

final adminLoginControllerProvider =
    AsyncNotifierProvider.autoDispose<AdminLoginController, void>(
  AdminLoginController.new,
);

// --- Orders wiring ---

final adminOrderDataSourceProvider = Provider<AdminOrderDataSource>(
  (ref) => AdminOrderDataSource(ref.watch(firebaseFirestoreProvider)),
);

/// The dashboard's active status filter (null = All).
final adminOrderFilterProvider = StateProvider<OrderStatus?>((ref) => null);

/// Live order feed for the dashboard, reacting to the active filter.
final adminOrdersProvider = StreamProvider<List<CustomerOrder>>((ref) {
  final OrderStatus? filter = ref.watch(adminOrderFilterProvider);
  return ref.watch(adminOrderDataSourceProvider).watchOrders(status: filter);
});

/// Count of orders still needing attention (not yet delivered), across today's
/// feed. Reads the unfiltered stream so the badge is filter-independent.
final pendingOrderCountProvider = Provider<int>((ref) {
  final AsyncValue<List<CustomerOrder>> all = ref.watch(_allOrdersProvider);
  return all.maybeWhen(
    data: (List<CustomerOrder> orders) => orders
        .where((CustomerOrder o) => o.status != OrderStatus.delivered)
        .length,
    orElse: () => 0,
  );
});

final _allOrdersProvider = StreamProvider<List<CustomerOrder>>(
  (ref) => ref.watch(adminOrderDataSourceProvider).watchOrders(),
);

/// Total orders in today's feed (unfiltered).
final todaysOrderCountProvider = Provider<int>((ref) {
  return ref.watch(_allOrdersProvider).maybeWhen(
        data: (List<CustomerOrder> orders) => orders.length,
        orElse: () => 0,
      );
});
