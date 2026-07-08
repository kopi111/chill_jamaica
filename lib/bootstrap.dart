import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/firebase/firebase_bootstrap.dart';
import 'core/providers/firebase_providers.dart';
import 'core/providers/prefs_provider.dart';
import 'features/order/data/datasources/order_local_datasource.dart';

/// Handles data-only FCM messages while the app is backgrounded/terminated.
///
/// Must be a top-level function so the platform can find it.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background order message: ${message.messageId}');
}

/// Shared startup for both the customer and admin apps: initialises Firebase,
/// crash reporting and Hive, then runs [app] inside a [ProviderScope].
Future<void> bootstrap(Widget app) async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseBootstrap.initialize();
  _installCrashReporting();
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

  final (Box<Map<dynamic, dynamic>> queueBox, Box<String> prefsBox) =
      await _openHiveBoxes();

  runApp(
    ProviderScope(
      overrides: <Override>[
        queuedOrdersBoxProvider.overrideWithValue(queueBox),
        prefsBoxProvider.overrideWithValue(prefsBox),
      ],
      child: app,
    ),
  );
}

/// Routes uncaught Flutter + platform errors to Crashlytics (release only, so
/// debugging stays local).
void _installCrashReporting() {
  if (kDebugMode) return;
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Opens the Hive boxes backing the offline order queue and local prefs.
Future<(Box<Map<dynamic, dynamic>>, Box<String>)> _openHiveBoxes() async {
  await Hive.initFlutter();
  final Box<Map<dynamic, dynamic>> queueBox =
      await Hive.openBox<Map<dynamic, dynamic>>(HiveOrderQueue.boxName);
  final Box<String> prefsBox = await Hive.openBox<String>('prefs');
  return (queueBox, prefsBox);
}
