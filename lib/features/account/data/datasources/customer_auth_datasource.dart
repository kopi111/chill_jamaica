import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';

/// Firebase Auth calls for customer accounts.
///
/// Deals only in credentials and uids; the profile document is a separate
/// concern handled by [CustomerProfileDataSource].
class CustomerAuthDataSource {
  CustomerAuthDataSource(this._auth);

  final FirebaseAuth _auth;

  /// The signed-in customer's uid, or null when signed out.
  Stream<String?> uidChanges() =>
      _auth.authStateChanges().map((User? user) => user?.uid);

  String? get currentUid => _auth.currentUser?.uid;

  /// Registers a new account and returns its uid.
  Future<String> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = credential.user;
      if (user == null) {
        throw const AuthException('Account created but no session started');
      }
      await user.updateDisplayName(fullName.trim());
      return user.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e.code), code: e.code);
    }
  }

  Future<String> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final String? uid = credential.user?.uid;
      if (uid == null) {
        throw const AuthException('Signed in but no session started');
      }
      return uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e.code), code: e.code);
    }
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_friendly(e.code), code: e.code);
    }
  }

  /// Maps Firebase Auth error codes to copy a customer can act on.
  String _friendly(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'That email already has an account. Sign in instead.';
      case 'invalid-email':
        return 'That email nuh look right.';
      case 'weak-password':
        return 'Pick a stronger password — at least 6 characters.';
      case 'invalid-credential':
      case 'wrong-password':
        return 'Wrong email or password.';
      case 'user-not-found':
        return 'No account with that email yet.';
      case 'user-disabled':
        return 'This account is disabled. Contact us for help.';
      case 'too-many-requests':
        return 'Too many tries. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Network a act up. Check yuh connection.';
      default:
        return 'Could not complete that. Try again.';
    }
  }
}
