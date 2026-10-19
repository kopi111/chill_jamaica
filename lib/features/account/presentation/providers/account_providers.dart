import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/providers/firebase_providers.dart';
import '../../data/datasources/customer_auth_datasource.dart';
import '../../data/datasources/customer_profile_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/profile_photo.dart';
import '../../domain/entities/sign_up_request.dart';
import '../../domain/repositories/customer_repository.dart';

// --- Wiring ---

final customerAuthDataSourceProvider = Provider<CustomerAuthDataSource>(
  (ref) => CustomerAuthDataSource(ref.watch(firebaseAuthProvider)),
);

final customerProfileDataSourceProvider = Provider<CustomerProfileDataSource>(
  (ref) => CustomerProfileDataSource(
    firestore: ref.watch(firebaseFirestoreProvider),
    storage: ref.watch(firebaseStorageProvider),
  ),
);

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerRepositoryImpl(
    auth: ref.watch(customerAuthDataSourceProvider),
    profiles: ref.watch(customerProfileDataSourceProvider),
  ),
);

// --- Session state ---

/// The signed-in customer, or null when nobody is signed in.
///
/// The router redirect, the checkout screen and the profile screen all read
/// this, so sign-out propagates everywhere at once.
final signedInCustomerProvider = StreamProvider<CustomerProfile?>(
  (ref) => ref.watch(customerRepositoryProvider).watchSignedInCustomer(),
);

/// True once a customer is signed in and their profile has loaded.
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(signedInCustomerProvider).valueOrNull != null,
);

// --- Actions ---

/// Drives the sign-up, sign-in and profile-edit forms: idle → loading → error.
class AccountController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> signUp(SignUpRequest request) =>
      _perform(() => ref.read(customerRepositoryProvider).signUp(request));

  Future<bool> signIn({required String email, required String password}) =>
      _perform(
        () => ref.read(customerRepositoryProvider).signIn(
              email: email,
              password: password,
            ),
      );

  Future<bool> saveProfile(CustomerProfile profile) =>
      _perform(() => ref.read(customerRepositoryProvider).saveProfile(profile));

  Future<bool> changePhoto({
    required CustomerProfile profile,
    required ProfilePhoto photo,
  }) =>
      _perform(
        () => ref.read(customerRepositoryProvider).changePhoto(
              profile: profile,
              photo: photo,
            ),
      );

  Future<void> signOut() => ref.read(customerRepositoryProvider).signOut();

  /// Sends a reset link and returns the message to show the customer.
  Future<String> sendPasswordReset(String email) async {
    try {
      await ref.read(customerRepositoryProvider).sendPasswordReset(email);
      return 'Reset link sent to $email';
    } on Failure catch (e) {
      return e.message;
    }
  }

  /// Runs [action] under the loading flag, returning whether it succeeded.
  Future<bool> _perform(Future<void> Function() action) async {
    if (state.isLoading) return false; // ignore rapid re-taps
    state = const AsyncValue<void>.loading();
    state = await AsyncValue.guard(action);
    return !state.hasError;
  }
}

final accountControllerProvider =
    AsyncNotifierProvider.autoDispose<AccountController, void>(
  AccountController.new,
);
