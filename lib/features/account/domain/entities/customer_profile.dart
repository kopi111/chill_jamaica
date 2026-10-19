import 'package:flutter/foundation.dart';

import 'saved_address.dart';

/// A registered customer's account details.
///
/// Created at sign-up and edited from the profile screen. The password lives in
/// Firebase Auth and never appears here.
@immutable
class CustomerProfile {
  const CustomerProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photoUrl,
    this.homeAddress,
    this.workAddress,
  });

  final String uid;
  final String fullName;
  final String email;

  /// E.164 Jamaican number, e.g. `+18761234567`.
  final String phone;

  /// Cloud Storage download URL, absent until the customer uploads a photo.
  final String? photoUrl;

  final String? homeAddress;
  final String? workAddress;

  /// Saved addresses complete enough to deliver to, in menu order.
  List<SavedAddress> get deliverableAddresses => <SavedAddress>[
        SavedAddress(label: AddressLabel.home, line: homeAddress ?? ''),
        SavedAddress(label: AddressLabel.work, line: workAddress ?? ''),
      ].where((SavedAddress a) => a.isUsable).toList(growable: false);

  bool get hasPhoto => (photoUrl ?? '').isNotEmpty;

  /// Up to two letters for the avatar fallback, e.g. `Lex Robinson` → `LR`.
  String get initials {
    final List<String> words = fullName.trim().split(RegExp(r'\s+'))
      ..removeWhere((String w) => w.isEmpty);
    if (words.isEmpty) return '🥥';
    final String first = words.first[0];
    final String last = words.length > 1 ? words.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  /// First name only, for greetings like "Hi Lex".
  String get firstName {
    final String trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'friend';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  CustomerProfile copyWith({
    String? fullName,
    String? phone,
    String? photoUrl,
    String? homeAddress,
    String? workAddress,
  }) =>
      CustomerProfile(
        uid: uid,
        fullName: fullName ?? this.fullName,
        email: email,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        homeAddress: homeAddress ?? this.homeAddress,
        workAddress: workAddress ?? this.workAddress,
      );
}
