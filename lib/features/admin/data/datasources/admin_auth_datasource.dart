import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/admin_user.dart';

/// Firebase Auth + `/admins` profile lookups for the admin app.
class AdminAuthDataSource {
  AdminAuthDataSource({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AdminUser?> authState() => _auth.authStateChanges().asyncMap(_toAdmin);

  AdminUser? get currentAdmin {
    final User? user = _auth.currentUser;
    return user == null ? null : _fromUser(user, null);
  }

  Future<AdminUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final AdminUser? admin = await _toAdmin(credential.user);
      if (admin == null) {
        throw const AuthException('Signed in but no admin profile found');
      }
      return admin;
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

  /// Enriches the Firebase user with the `/admins/{uid}` profile if present.
  Future<AdminUser?> _toAdmin(User? user) async {
    if (user == null) return null;
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _firestore.collection('admins').doc(user.uid).get();
      return _fromUser(user, doc.data());
    } catch (_) {
      // Profile fetch failed — still return a basic admin from the auth record.
      return _fromUser(user, null);
    }
  }

  AdminUser _fromUser(User user, Map<String, dynamic>? profile) => AdminUser(
        uid: user.uid,
        email: user.email ?? profile?['email'] as String? ?? '',
        displayName:
            profile?['displayName'] as String? ?? user.displayName,
        role: profile?['role'] as String? ?? 'admin',
      );

  /// Maps Firebase Auth error codes to friendly copy.
  String _friendly(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Wrong email or password.';
      case 'user-not-found':
        return 'No admin found with that email.';
      case 'user-disabled':
        return 'This admin account is disabled.';
      case 'too-many-requests':
        return 'Too many tries. Wait a moment and try again.';
      case 'network-request-failed':
        return 'Network a act up. Check yuh connection.';
      default:
        return 'Could not sign in. Try again.';
    }
  }
}
