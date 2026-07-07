import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../features/order/data/datasources/order_local_datasource.dart';
import '../notifications/notification_service.dart';

/// Shared Firebase singletons, injected via Riverpod so tests can override them.

final firebaseFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// The opened Hive box backing the offline order queue.
///
/// Overridden in `main()` with the real box once Hive has initialised.
final queuedOrdersBoxProvider = Provider<Box<Map<dynamic, dynamic>>>(
  (ref) => throw UnimplementedError(
    'queuedOrdersBoxProvider must be overridden in main() with the opened box',
  ),
);

final orderLocalDataSourceProvider = Provider<OrderLocalDataSource>(
  (ref) => HiveOrderQueue(ref.watch(queuedOrdersBoxProvider)),
);

/// Admin push-notification service (FCM + local notifications).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(
    firestore: ref.watch(firebaseFirestoreProvider),
  ),
);
