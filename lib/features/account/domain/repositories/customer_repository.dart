import '../entities/customer_profile.dart';
import '../entities/profile_photo.dart';
import '../entities/sign_up_request.dart';

/// Contract for customer registration, sign-in and profile upkeep.
///
/// Implementations translate data-layer exceptions into [Failure]s so callers
/// only ever see friendly messages.
abstract interface class CustomerRepository {
  /// The signed-in customer's profile, or null when nobody is signed in.
  ///
  /// Emits again whenever the customer signs in, signs out, or edits their
  /// profile from another device.
  Stream<CustomerProfile?> watchSignedInCustomer();

  Future<CustomerProfile> signUp(SignUpRequest request);

  Future<CustomerProfile> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  /// Saves edited details. The email is fixed at sign-up and is ignored here.
  Future<CustomerProfile> saveProfile(CustomerProfile profile);

  /// Uploads a new profile photo and returns the profile with its new URL.
  Future<CustomerProfile> changePhoto({
    required CustomerProfile profile,
    required ProfilePhoto photo,
  });
}
