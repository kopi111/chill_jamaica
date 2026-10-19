import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android channel the payment-receipt Cloud Function targets.
const AndroidNotificationChannel _paymentsChannel = AndroidNotificationChannel(
  'payments_channel',
  'Payment Receipts',
  description: 'Confirms when a payment goes through',
  importance: Importance.high,
);

/// Delivers payment receipts to the customer: permission, the FCM token, and
/// foreground display.
///
/// Mirrors [NotificationService] on the admin side, but writes the token to
/// `/customers/{uid}.fcmToken` and listens on its own channel so a receipt is
/// never mistaken for a new-order alert.
class CustomerNotificationService {
  CustomerNotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = local ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final FirebaseFirestore _firestore;

  bool _isConfigured = false;

  /// Requests permission, wires foreground display and syncs the token for
  /// [customerId]. Safe to call more than once.
  Future<void> initializeForCustomer(String customerId) async {
    if (!_isConfigured) {
      await _configureLocalNotifications();
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _isConfigured = true;
    }
    await _syncToken(customerId);
  }

  Future<void> _configureLocalNotifications() async {
    const AndroidInitializationSettings android =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings ios = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_paymentsChannel);
  }

  /// Persists the current and refreshed FCM tokens onto the customer's profile.
  Future<void> _syncToken(String customerId) async {
    final DocumentReference<Map<String, dynamic>> customerDoc =
        _firestore.collection('customers').doc(customerId);
    final String? token = await _messaging.getToken();
    if (token != null) {
      await customerDoc.set(
        <String, dynamic>{'fcmToken': token},
        SetOptions(merge: true),
      );
    }
    _messaging.onTokenRefresh.listen((String refreshed) {
      customerDoc.set(
        <String, dynamic>{'fcmToken': refreshed},
        SetOptions(merge: true),
      );
    });
  }

  void _showForegroundNotification(RemoteMessage message) {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;
    _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _paymentsChannel.id,
          _paymentsChannel.name,
          channelDescription: _paymentsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
