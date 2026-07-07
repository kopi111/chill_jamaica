/// Low-level exceptions thrown by data sources.
///
/// Repositories catch these and translate them into user-facing [Failure]s so
/// the presentation layer never has to reason about raw platform errors.
library;

/// Thrown when a remote call (Firestore, Auth, Functions) fails.
class ServerException implements Exception {
  const ServerException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when the device has no usable network connection.
class NetworkException implements Exception {
  const NetworkException([this.message = 'No internet connection']);

  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when acquiring GPS location or reverse-geocoding fails.
class LocationException implements Exception {
  const LocationException(this.message, {this.isPermanentlyDenied = false});

  final String message;

  /// True when the user has blocked location at the OS level and must change it
  /// in system settings — the caller should offer a "open settings" action.
  final bool isPermanentlyDenied;

  @override
  String toString() => 'LocationException: $message';
}

/// Thrown when authentication fails (bad credentials, missing user, etc.).
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

/// Thrown when persisting to or reading from local storage fails.
class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}
