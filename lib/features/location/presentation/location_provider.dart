import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => const LocationService(),
);

/// Drives the GPS button on the checkout screen: idle → loading → data/error.
class LocationController extends AutoDisposeAsyncNotifier<LocationResult?> {
  @override
  Future<LocationResult?> build() async => null;

  /// Acquires the device location, surfacing a friendly [LocationFailure] on
  /// error (with the permanent-denial flag preserved for the settings CTA).
  Future<void> acquire() async {
    state = const AsyncValue<LocationResult?>.loading();
    state = await AsyncValue.guard(() async {
      try {
        return await ref.read(locationServiceProvider).currentLocation();
      } on LocationException catch (e) {
        throw LocationFailure(e.message,
            isPermanentlyDenied: e.isPermanentlyDenied);
      }
    });
  }

  void reset() => state = const AsyncValue<LocationResult?>.data(null);
}

final locationControllerProvider =
    AsyncNotifierProvider.autoDispose<LocationController, LocationResult?>(
  LocationController.new,
);
