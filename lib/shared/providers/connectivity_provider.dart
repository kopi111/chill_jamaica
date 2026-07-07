import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_service.dart';

/// Single [ConnectivityService] instance for the app.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityService(),
);

/// Live online/offline status. Seeds with the current one-shot check, then
/// tracks changes. `true` = online.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final ConnectivityService service = ref.watch(connectivityServiceProvider);
  yield await service.isOnline;
  yield* service.onStatusChange;
});
