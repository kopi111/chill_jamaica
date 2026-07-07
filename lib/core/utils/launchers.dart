import 'package:url_launcher/url_launcher.dart';

import '../../features/order/domain/entities/delivery_details.dart';

/// Thin wrapper over `url_launcher` for the actions the admin app needs.
///
/// Each method returns `false` when the platform can't handle the intent, so
/// callers can show a fallback message instead of throwing.
abstract final class Launchers {
  const Launchers._();

  /// Opens the phone dialer pre-filled with [e164].
  static Future<bool> dial(String e164) =>
      _launch(Uri(scheme: 'tel', path: e164));

  /// Opens the SMS composer for [e164].
  static Future<bool> sms(String e164) =>
      _launch(Uri(scheme: 'sms', path: e164));

  /// Opens a maps app at the delivery location — coordinates for GPS orders,
  /// a place search for typed addresses.
  static Future<bool> maps(DeliveryDetails delivery) {
    final GeoCoordinate? coord = delivery.coordinates;
    final Uri uri = coord != null
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${coord.latitude},${coord.longitude}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(delivery.displayAddress)}');
    return _launch(uri);
  }

  static Future<bool> _launch(Uri uri) async {
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
