import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android notification channel the Cloud Function targets (`orders_channel`).
const AndroidNotificationChannel _ordersChannel = AndroidNotificationChannel(
  'orders_channel',
  'New Orders',
  description: 'Alerts admins when a new coconut-water order comes in',
  importance: Importance.high,
);

/// Handles admin push notifications end-to-end: permissions, the FCM token,
/// foreground display, and keeping `/admins/{uid}.fcmToken` current.
///
/// The customer app doesn't need this — only initialise it after an admin
/// signs in.
class NotificationService {
  NotificationService({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _local = local ?? FlutterLocalNotificationsPlugin(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final FirebaseFirestore _firestore;

  bool _initialised = false;

  /// Requests permission, wires foreground display, and syncs the token for
  /// [adminId]. Safe to call more than once.
  Future<void> initializeForAdmin(String adminId) async {
    if (!_initialised) {
      await _configureLocalNotifications();
      await _messaging.requestPermission();
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _initialised = true;
    }
    await _syncToken(adminId);
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
        ?.createNotificationChannel(_ordersChannel);
  }

  /// Persists the current + refreshed FCM tokens onto the admin's profile.
  Future<void> _syncToken(String adminId) async {
    final DocumentReference<Map<String, dynamic>> adminDoc =
        _firestore.collection('admins').doc(adminId);
    final String? token = await _messaging.getToken();
    if (token != null) {
      await adminDoc.set(
        <String, dynamic>{'fcmToken': token},
        SetOptions(merge: true),
      );
    }
    _messaging.onTokenRefresh.listen((String refreshed) {
      adminDoc.set(
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
          _ordersChannel.id,
          _ordersChannel.name,
          channelDescription: _ordersChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
    debugPrint('🔔 Foreground order notification: ${notification.title}');
  }
}
