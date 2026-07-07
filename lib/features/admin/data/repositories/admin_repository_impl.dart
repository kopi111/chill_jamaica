import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/admin_user.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_auth_datasource.dart';

/// Default [AdminRepository], mapping auth exceptions to [AuthFailure].
class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._auth);

  final AdminAuthDataSource _auth;

  @override
  Stream<AdminUser?> authState() => _auth.authState();

  @override
  AdminUser? get currentAdmin => _auth.currentAdmin;

  @override
  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signIn(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }
}
