import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/errors/exceptions.dart';
import '../../order/domain/entities/delivery_details.dart';

/// A GPS fix plus its accuracy and best-effort street address.
class LocationResult {
  const LocationResult({
    required this.coordinate,
    required this.accuracyMeters,
    this.address,
  });

  final GeoCoordinate coordinate;
  final double accuracyMeters;
  final String? address;

  /// True when the fix is precise enough not to warn the customer.
  bool isAccurateWithin(double thresholdMeters) =>
      accuracyMeters <= thresholdMeters;
}

/// Wraps `geolocator` + `geocoding`, translating platform states into a single
/// [LocationException] the UI can act on (including "open settings").
class LocationService {
  const LocationService();

  /// Acquires the current position and reverse-geocodes it.
  ///
  /// Throws [LocationException] with [isPermanentlyDenied] set when the user has
  /// blocked location in system settings.
  Future<LocationResult> currentLocation() async {
    await _ensureServiceEnabled();
    await _ensurePermission();

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return LocationResult(
      coordinate: GeoCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      accuracyMeters: position.accuracy,
      address: await _reverseGeocode(position),
    );
  }

  /// Opens the OS location settings — used after a permanent denial.
  Future<void> openSettings() => Geolocator.openAppSettings();

  Future<void> _ensureServiceEnabled() async {
    final bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(AppStrings.locationDenied);
    }
  }

  Future<void> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        AppStrings.locationDeniedForever,
        isPermanentlyDenied: true,
      );
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(AppStrings.locationDenied);
    }
  }

  /// Reverse-geocodes to a readable address; returns null on failure so the
  /// caller can fall back to raw coordinates.
  Future<String?> _reverseGeocode(Position position) async {
    try {
      final List<Placemark> marks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (marks.isEmpty) return null;
      return _formatPlacemark(marks.first);
    } catch (_) {
      return null;
    }
  }

  String _formatPlacemark(Placemark p) {
    final List<String> parts = <String>[
      if ((p.name ?? '').isNotEmpty) p.name!,
      if ((p.street ?? '').isNotEmpty && p.street != p.name) p.street!,
      if ((p.subLocality ?? '').isNotEmpty) p.subLocality!,
      if ((p.locality ?? '').isNotEmpty) p.locality!,
      if ((p.administrativeArea ?? '').isNotEmpty) p.administrativeArea!,
    ];
    return parts.isEmpty ? 'Unknown location' : parts.join(', ');
  }
}
