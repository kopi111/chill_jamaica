import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Small local key/value store for lightweight preferences (e.g. the customer's
/// phone number, cached so "My Orders" doesn't ask for it every time).
final prefsBoxProvider = Provider<Box<String>>(
  (ref) => throw UnimplementedError(
    'prefsBoxProvider must be overridden in main() with the opened box',
  ),
);

const String _customerPhoneKey = 'customer_phone_e164';

/// The cached customer phone (E.164), persisted across launches.
class CustomerPhoneNotifier extends Notifier<String?> {
  @override
  String? build() => ref.watch(prefsBoxProvider).get(_customerPhoneKey);

  Future<void> save(String phoneE164) async {
    await ref.read(prefsBoxProvider).put(_customerPhoneKey, phoneE164);
    state = phoneE164;
  }

  Future<void> clear() async {
    await ref.read(prefsBoxProvider).delete(_customerPhoneKey);
    state = null;
  }
}

final customerPhoneProvider =
    NotifierProvider<CustomerPhoneNotifier, String?>(CustomerPhoneNotifier.new);
