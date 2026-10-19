import 'dart:async';

/// Maps each event of [source] to an inner stream and emits only that stream's
/// events, dropping the previous one.
///
/// `Stream.asyncExpand` cannot do this: it waits for the inner stream to finish
/// first, and endless streams — a Firestore `snapshots()` listener, say — never
/// do. This is the `switchMap` operator, without pulling in rxdart.
Stream<R> switchLatest<T, R>(
  Stream<T> source,
  Stream<R> Function(T value) toInnerStream,
) {
  late final StreamController<R> controller;
  StreamSubscription<T>? outerSubscription;
  StreamSubscription<R>? innerSubscription;

  Future<void> dropInner() async {
    final StreamSubscription<R>? current = innerSubscription;
    innerSubscription = null;
    await current?.cancel();
  }

  void switchTo(T value) {
    dropInner();
    innerSubscription = toInnerStream(value).listen(
      controller.add,
      onError: controller.addError,
    );
  }

  controller = StreamController<R>(
    onListen: () => outerSubscription = source.listen(
      switchTo,
      onError: controller.addError,
      onDone: controller.close,
    ),
    onCancel: () async {
      await outerSubscription?.cancel();
      await dropInner();
    },
  );

  return controller.stream;
}
