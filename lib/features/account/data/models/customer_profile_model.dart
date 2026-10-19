import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/saved_address.dart';

/// Firestore (de)serialization for `/customers/{uid}`.
abstract final class CustomerProfileModel {
  const CustomerProfileModel._();

  static CustomerProfile fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? const <String, dynamic>{};
    return CustomerProfile(
      uid: doc.id,
      fullName: (data['fullName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      phone: (data['phone'] as String?) ?? '',
      photoUrl: data['photoUrl'] as String?,
      homeAddress: data[AddressLabel.home.wireValue] as String?,
      workAddress: data[AddressLabel.work.wireValue] as String?,
    );
  }

  /// Payload for a brand-new profile document.
  static Map<String, dynamic> toCreatePayload(CustomerProfile profile) =>
      <String, dynamic>{
        ...toUpdatePayload(profile),
        'email': profile.email,
        'createdAt': FieldValue.serverTimestamp(),
      };

  /// Payload for an edit — everything the customer is allowed to change.
  static Map<String, dynamic> toUpdatePayload(CustomerProfile profile) =>
      <String, dynamic>{
        'fullName': profile.fullName,
        'phone': profile.phone,
        'photoUrl': profile.photoUrl,
        AddressLabel.home.wireValue: profile.homeAddress,
        AddressLabel.work.wireValue: profile.workAddress,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
