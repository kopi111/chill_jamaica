import '../constants/app_strings.dart';

/// User-facing failures surfaced to the presentation layer.
///
/// Each failure carries a friendly, Jamaican-flavoured [message] safe to show
/// in a snackbar or error view. Data-layer [Exception]s are mapped to these.
sealed class Failure {
  const Failure(this.message);

  /// Friendly copy suitable for direct display to the customer.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A remote service (Firestore, Functions) returned an error.
class ServerFailure extends Failure {
  const ServerFailure([super.message = AppStrings.serverError]);
}

/// The device is offline or the request timed out.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = AppStrings.networkError]);
}

/// GPS acquisition or geocoding failed.
class LocationFailure extends Failure {
  const LocationFailure(
    super.message, {
    this.isPermanentlyDenied = false,
  });

  /// When true, the UI should offer to open system settings.
  final bool isPermanentlyDenied;
}

/// Authentication failed (admin sign-in).
class AuthFailure extends Failure {
  const AuthFailure([super.message = AppStrings.genericError]);
}

/// Reading or writing local storage failed.
class CacheFailure extends Failure {
  const CacheFailure([super.message = AppStrings.genericError]);
}
