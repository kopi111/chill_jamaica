import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/switch_latest.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/profile_photo.dart';
import '../../domain/entities/sign_up_request.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_auth_datasource.dart';
import '../datasources/customer_profile_datasource.dart';

/// Firebase-backed [CustomerRepository]: Auth for credentials, Firestore and
/// Storage for the profile.
class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl({
    required CustomerAuthDataSource auth,
    required CustomerProfileDataSource profiles,
  })  : _auth = auth,
        _profiles = profiles;

  final CustomerAuthDataSource _auth;
  final CustomerProfileDataSource _profiles;

  @override
  Stream<CustomerProfile?> watchSignedInCustomer() {
    return switchLatest<String?, CustomerProfile?>(
      _auth.uidChanges(),
      (String? uid) => uid == null
          ? Stream<CustomerProfile?>.value(null)
          : _profiles.watch(uid),
    );
  }

  @override
  Future<CustomerProfile> signUp(SignUpRequest request) {
    return _translatingErrors(() async {
      final String uid = await _auth.register(
        email: request.email,
        password: request.password,
        fullName: request.fullName,
      );
      final CustomerProfile profile = await _withUploadedPhoto(
        _profileFrom(request, uid),
        request.photo,
      );
      await _profiles.create(profile);
      return profile;
    });
  }

  @override
  Future<CustomerProfile> signIn({
    required String email,
    required String password,
  }) {
    return _translatingErrors(() async {
      final String uid = await _auth.signIn(email: email, password: password);
      final CustomerProfile? profile = await _profiles.read(uid);
      if (profile == null) {
        throw const AuthException('Signed in but no profile found');
      }
      return profile;
    });
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _translatingErrors(() => _auth.sendPasswordReset(email));

  @override
  Future<CustomerProfile> saveProfile(CustomerProfile profile) {
    return _translatingErrors(() async {
      await _profiles.update(profile);
      return profile;
    });
  }

  @override
  Future<CustomerProfile> changePhoto({
    required CustomerProfile profile,
    required ProfilePhoto photo,
  }) {
    return _translatingErrors(() async {
      final CustomerProfile updated = await _withUploadedPhoto(profile, photo);
      await _profiles.update(updated);
      return updated;
    });
  }

  // --- Helpers ---

  CustomerProfile _profileFrom(SignUpRequest request, String uid) =>
      CustomerProfile(
        uid: uid,
        fullName: request.fullName.trim(),
        email: request.email.trim(),
        phone: request.phone,
        homeAddress: request.homeAddress,
        workAddress: request.workAddress,
      );

  /// Returns [profile] with its photo uploaded, or unchanged when none was
  /// picked. A failed upload never blocks the account itself.
  Future<CustomerProfile> _withUploadedPhoto(
    CustomerProfile profile,
    ProfilePhoto? photo,
  ) async {
    if (photo == null) return profile;
    final String url = await _profiles.uploadPhoto(
      uid: profile.uid,
      photo: photo,
    );
    return profile.copyWith(photoUrl: url);
  }

  /// Runs [action], converting data-layer exceptions into user-facing failures.
  Future<T> _translatingErrors<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    } on ServerException catch (e) {
      throw ServerFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    }
  }
}
