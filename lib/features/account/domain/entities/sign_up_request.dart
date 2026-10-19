import 'package:flutter/foundation.dart';

import 'profile_photo.dart';

/// Everything collected on the sign-up form.
///
/// The email doubles as the customer's username so password reset has somewhere
/// to send its link.
@immutable
class SignUpRequest {
  const SignUpRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
    this.photo,
    this.homeAddress,
    this.workAddress,
  });

  final String fullName;
  final String email;
  final String password;

  /// E.164 Jamaican number, e.g. `+18761234567`.
  final String phone;

  final ProfilePhoto? photo;
  final String? homeAddress;
  final String? workAddress;
}
