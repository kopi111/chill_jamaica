import 'package:flutter/foundation.dart';

/// An authenticated admin operator.
@immutable
class AdminUser {
  const AdminUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = 'admin',
  });

  final String uid;
  final String email;
  final String? displayName;

  /// `admin` or `super_admin`.
  final String role;

  String get shortName =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : email;
}
