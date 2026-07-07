import '../entities/admin_user.dart';

/// Authentication + admin-profile operations for the admin app.
abstract interface class AdminRepository {
  /// Currently signed-in admin, or null. Emits on every auth change.
  Stream<AdminUser?> authState();

  /// The current admin synchronously, if any.
  AdminUser? get currentAdmin;

  /// Signs in with email/password. Throws [AuthFailure] on any failure.
  Future<AdminUser> signIn({required String email, required String password});

  Future<void> signOut();

  /// Sends a password-reset email. Throws [AuthFailure] on failure.
  Future<void> sendPasswordReset(String email);
}
