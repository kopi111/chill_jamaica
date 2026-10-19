import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_options.dart';

/// Initialises Firebase and, in debug builds, points the SDKs at the local
/// Firebase Emulator Suite so the app runs with no live project.
///
/// Toggle emulator use with `--dart-define=USE_FIREBASE_EMULATOR=true` (defaults
/// to true in debug, false in release).
abstract final class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static const bool _useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: kDebugMode,
  );

  /// Host the emulator binds to. On the Android emulator, `localhost` on the
  /// device is `10.0.2.2` on the host machine.
  static const String _emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (_useEmulator) {
      await _connectEmulators();
    }
  }

  static Future<void> _connectEmulators() async {
    final String host = _resolveHost();
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    await FirebaseStorage.instance.useStorageEmulator(host, 9199);
    debugPrint('🔥 Firebase running against emulator at $host');
  }

  /// The Android emulator reaches the host loopback via 10.0.2.2.
  static String _resolveHost() {
    final bool isAndroidDevice =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    if (isAndroidDevice && _emulatorHost == 'localhost') return '10.0.2.2';
    return _emulatorHost;
  }
}
