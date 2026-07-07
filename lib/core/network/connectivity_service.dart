import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over `connectivity_plus` exposing a simple online/offline view.
///
/// Wrapping the third-party API (per our error-handling standard) keeps the rest
/// of the app decoupled from the package and easy to fake in tests.
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Emits `true` when at least one active transport is available.
  Stream<bool> get onStatusChange => _connectivity
      .onConnectivityChanged
      .map(_isOnline);

  /// One-shot check — use before a network write to fail fast when offline.
  Future<bool> get isOnline async => _isOnline(await _connectivity.checkConnectivity());

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((ConnectivityResult r) => r != ConnectivityResult.none);
}
