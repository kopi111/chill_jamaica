import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/customer_profile.dart';
import '../../domain/entities/profile_photo.dart';
import '../models/customer_profile_model.dart';

/// Reads and writes `/customers/{uid}` plus the customer's photo in Storage.
class CustomerProfileDataSource {
  CustomerProfileDataSource({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  })  : _firestore = firestore,
        _storage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const String _collection = 'customers';

  DocumentReference<Map<String, dynamic>> _docFor(String uid) =>
      _firestore.collection(_collection).doc(uid);

  /// Live profile for [uid]; emits null while the document does not exist yet.
  Stream<CustomerProfile?> watch(String uid) =>
      _docFor(uid).snapshots().map((DocumentSnapshot<Map<String, dynamic>> doc) {
        return doc.exists ? CustomerProfileModel.fromDoc(doc) : null;
      });

  Future<CustomerProfile?> read(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _docFor(uid).get();
      return doc.exists ? CustomerProfileModel.fromDoc(doc) : null;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to load your profile', cause: e);
    }
  }

  Future<void> create(CustomerProfile profile) async {
    try {
      await _docFor(profile.uid)
          .set(CustomerProfileModel.toCreatePayload(profile));
    } on FirebaseException catch (e) {
      throw ServerException('Failed to save your profile', cause: e);
    }
  }

  Future<void> update(CustomerProfile profile) async {
    try {
      await _docFor(profile.uid).set(
        CustomerProfileModel.toUpdatePayload(profile),
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException('Failed to save your changes', cause: e);
    }
  }

  /// Uploads [photo] for [uid] and returns its public download URL.
  Future<String> uploadPhoto({
    required String uid,
    required ProfilePhoto photo,
  }) async {
    try {
      final Reference ref = _storage.ref(photo.storagePathFor(uid));
      await ref.putData(
        photo.bytes,
        SettableMetadata(contentType: photo.contentType),
      );
      return ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to upload your photo', cause: e);
    }
  }

  /// Stores the device's push token so payment receipts can reach this customer.
  Future<void> saveMessagingToken({
    required String uid,
    required String token,
  }) async {
    try {
      await _docFor(uid).set(
        <String, dynamic>{'fcmToken': token},
        SetOptions(merge: true),
      );
    } on FirebaseException catch (e) {
      throw ServerException('Failed to register for notifications', cause: e);
    }
  }
}
