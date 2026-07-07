import 'package:flutter/foundation.dart';

/// How the customer wants their order delivered.
enum DeliveryMethod {
  address(wireValue: 'address'),
  gps(wireValue: 'gps');

  const DeliveryMethod({required this.wireValue});

  final String wireValue;

  static DeliveryMethod fromWire(String? value) => values.firstWhere(
        (DeliveryMethod m) => m.wireValue == value,
        orElse: () => DeliveryMethod.address,
      );
}

/// A GPS coordinate captured for delivery.
@immutable
class GeoCoordinate {
  const GeoCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  String toString() =>
      'Lat: ${latitude.toStringAsFixed(5)}, Lng: ${longitude.toStringAsFixed(5)}';
}

/// Where and how an order should be delivered.
///
/// Exactly one of ([typedAddress]) or ([coordinates]) is meaningful depending on
/// [method]; [resolvedAddress] holds any reverse-geocoded text for GPS orders.
@immutable
class DeliveryDetails {
  const DeliveryDetails({
    required this.method,
    this.typedAddress,
    this.coordinates,
    this.resolvedAddress,
  });

  const DeliveryDetails.typed(String address)
      : method = DeliveryMethod.address,
        typedAddress = address,
        coordinates = null,
        resolvedAddress = null;

  const DeliveryDetails.gps({
    required GeoCoordinate this.coordinates,
    this.resolvedAddress,
  })  : method = DeliveryMethod.gps,
        typedAddress = null;

  final DeliveryMethod method;
  final String? typedAddress;
  final GeoCoordinate? coordinates;
  final String? resolvedAddress;

  /// Human-readable address for display; falls back to raw coordinates.
  String get displayAddress {
    if (method == DeliveryMethod.address) {
      return typedAddress ?? 'Address not provided';
    }
    return resolvedAddress ?? coordinates?.toString() ?? 'GPS location';
  }
}
