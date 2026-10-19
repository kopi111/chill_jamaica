import 'dart:async';

import 'package:chill_jamaica/core/utils/switch_latest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('emits the events of the newest inner stream', () async {
    final StreamController<int> outer = StreamController<int>();
    final Map<int, StreamController<String>> inners =
        <int, StreamController<String>>{
      1: StreamController<String>(),
      2: StreamController<String>(),
    };

    final List<String> seen = <String>[];
    final StreamSubscription<String> sub = switchLatest<int, String>(
      outer.stream,
      (int key) => inners[key]!.stream,
    ).listen(seen.add);

    outer.add(1);
    await pumpEventQueue();
    inners[1]!.add('a');
    await pumpEventQueue();

    // Switching outer events must drop the first inner stream, even though it
    // is still open — this is the case `asyncExpand` cannot handle.
    outer.add(2);
    await pumpEventQueue();
    inners[1]!.add('ignored');
    inners[2]!.add('b');
    await pumpEventQueue();

    expect(seen, <String>['a', 'b']);
    await sub.cancel();
  });

  test('forwards inner errors without closing the stream', () async {
    final StreamController<int> outer = StreamController<int>();
    final StreamController<String> inner = StreamController<String>();

    final List<Object> errors = <Object>[];
    final List<String> values = <String>[];
    final StreamSubscription<String> sub = switchLatest<int, String>(
      outer.stream,
      (_) => inner.stream,
    ).listen(values.add, onError: errors.add);

    outer.add(1);
    await pumpEventQueue();
    inner.addError('boom');
    inner.add('still here');
    await pumpEventQueue();

    expect(errors, <Object>['boom']);
    expect(values, <String>['still here']);
    await sub.cancel();
  });

  test('closes when the outer stream is done', () async {
    final StreamController<int> outer = StreamController<int>();
    bool isDone = false;

    switchLatest<int, String>(outer.stream, (_) => const Stream<String>.empty())
        .listen(null, onDone: () => isDone = true);

    await outer.close();
    await pumpEventQueue();

    expect(isDone, isTrue);
  });
}

/// Lets pending microtasks and timers run before asserting.
Future<void> pumpEventQueue() =>
    Future<void>.delayed(const Duration(milliseconds: 1));
