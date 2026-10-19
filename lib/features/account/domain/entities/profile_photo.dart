import 'package:flutter/foundation.dart';

/// A photo the customer picked, held in memory until it is uploaded.
///
/// Raw bytes rather than a `File` keep the domain free of `dart:io`, so the
/// same code runs on mobile and web.
@immutable
class ProfilePhoto {
  const ProfilePhoto({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  /// MIME type derived from the file extension, defaulting to JPEG.
  String get contentType {
    final String extension = fileName.split('.').last.toLowerCase();
    return _contentTypesByExtension[extension] ?? 'image/jpeg';
  }

  /// Storage object for [uid].
  ///
  /// The uid is its own folder so the security rule can name the owner, and the
  /// object name is fixed so a re-upload replaces the old photo instead of
  /// leaving orphans behind. The format lives in the object's content type, not
  /// in a file extension.
  String storagePathFor(String uid) => 'customer_photos/$uid/profile';

  static const Map<String, String> _contentTypesByExtension = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
    'heic': 'image/heic',
  };
}
