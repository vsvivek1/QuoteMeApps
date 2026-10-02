import 'dart:async';

/// Stale-while-revalidate: emits the cached value first (if any), then every
/// live value, writing each live value back to the cache. When the live
/// stream fails (offline) and a cached value was shown, the error is swallowed
/// so the screen keeps showing cached data.
Stream<T> staleWhileRevalidate<T>({
  required Future<T?> Function() readCache,
  required Stream<T> live,
  required Future<void> Function(T value) writeCache,
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  var gotLive = false;
  var shownCache = false;

  controller = StreamController<T>(
    onListen: () async {
      sub = live.listen(
        (v) {
          gotLive = true;
          controller.add(v);
          unawaited(writeCache(v).catchError((_) {}));
        },
        onError: (Object e, StackTrace st) {
          if (!shownCache) controller.addError(e, st);
        },
        onDone: controller.close,
      );
      try {
        final cached = await readCache();
        if (cached != null && !gotLive && !controller.isClosed) {
          shownCache = true;
          controller.add(cached);
        }
      } catch (_) {
        // A broken cache never blocks live data.
      }
    },
    onCancel: () => sub?.cancel(),
  );
  return controller.stream;
}
