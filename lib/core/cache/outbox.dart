import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_cache.dart';

/// Sends one queued write. Throw [PermanentOutboxError] to drop the entry
/// (e.g. the chat was closed); any other error is retried with backoff.
typedef OutboxHandler = Future<void> Function(String payload);

class PermanentOutboxError implements Exception {
  const PermanentOutboxError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Replays queued writes in order when the network comes back, with
/// exponential backoff (5 s doubling, capped at 15 minutes).
class Outbox {
  Outbox(this._cache, {Stream<List<ConnectivityResult>>? connectivity, DateTime Function()? clock})
    : _connectivity = connectivity ?? Connectivity().onConnectivityChanged,
      _now = clock ?? DateTime.now;

  final AppCache _cache;
  final Stream<List<ConnectivityResult>> _connectivity;
  final DateTime Function() _now;
  final _handlers = <String, OutboxHandler>{};
  StreamSubscription<List<ConnectivityResult>>? _sub;
  Timer? _timer;
  bool _draining = false;

  static const maxAttempts = 12;

  void register(String kind, OutboxHandler handler) => _handlers[kind] = handler;

  Future<void> add(String kind, String payload) async {
    await _cache.enqueue(kind, payload, at: _now());
    unawaited(drain());
  }

  Stream<int> get pendingCount => _cache.watchPendingCount();

  void start() {
    _sub ??= _connectivity.listen((r) {
      if (r.any((c) => c != ConnectivityResult.none)) unawaited(drain());
    });
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => drain());
    unawaited(drain());
  }

  static Duration backoff(int attempts) => Duration(seconds: math.min(5 * (1 << math.min(attempts, 20)), 900));

  /// Sends every due entry in insertion order; stops at the first transient failure
  /// so later writes (e.g. chat messages) never overtake earlier ones.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      for (final e in await _cache.pendingEntries()) {
        // Strict FIFO: an entry waiting on backoff holds back everything after it.
        if (e.nextAttemptAt.isAfter(_now())) break;
        final handler = _handlers[e.kind];
        if (handler == null) continue;
        try {
          await handler(e.payload);
          await _cache.completeEntry(e.id);
        } on PermanentOutboxError {
          await _cache.completeEntry(e.id);
        } catch (err) {
          if (e.attempts + 1 >= maxAttempts) {
            await _cache.completeEntry(e.id);
          } else {
            await _cache.failEntry(e, err.toString(), _now().add(backoff(e.attempts)));
          }
          break;
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _timer?.cancel();
  }
}
