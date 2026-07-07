import 'package:hive/hive.dart';

import '../../../../core/errors/exceptions.dart';

/// Persists orders that were placed while offline, so nothing is lost.
///
/// Orders are stored as plain JSON maps keyed by an idempotency key; on
/// reconnect the repository drains this queue into Firestore.
abstract interface class OrderLocalDataSource {
  Future<void> enqueue(String key, Map<String, dynamic> orderJson);
  Future<Map<String, Map<String, dynamic>>> pending();
  Future<void> remove(String key);
}

class HiveOrderQueue implements OrderLocalDataSource {
  HiveOrderQueue(this._box);

  final Box<Map<dynamic, dynamic>> _box;

  static const String boxName = 'queued_orders';

  @override
  Future<void> enqueue(String key, Map<String, dynamic> orderJson) async {
    try {
      await _box.put(key, orderJson);
    } catch (e) {
      throw CacheException('Could not queue order: $e');
    }
  }

  @override
  Future<Map<String, Map<String, dynamic>>> pending() async {
    final Map<String, Map<String, dynamic>> result =
        <String, Map<String, dynamic>>{};
    for (final dynamic key in _box.keys) {
      final Map<dynamic, dynamic>? value = _box.get(key);
      if (value != null) {
        result['$key'] = Map<String, dynamic>.from(value);
      }
    }
    return result;
  }

  @override
  Future<void> remove(String key) => _box.delete(key);
}
