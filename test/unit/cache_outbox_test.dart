import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/cache/app_cache.dart';
import 'package:iwant/core/cache/outbox.dart';
import 'package:iwant/core/cache/swr.dart';

void main() {
  late AppCache cache;
  setUp(() => cache = AppCache(NativeDatabase.memory()));
  tearDown(() => cache.close());

  test('rows are stored per scope in order and replaced on refresh', () async {
    await cache.putRows('quote', {'q1': '{"a":1}', 'q2': '{"a":2}'}, scope: 'r1');
    await cache.putRows('quote', {'q3': '{"a":3}'}, scope: 'r2');
    expect(await cache.rowsInScope('quote', 'r1'), ['{"a":1}', '{"a":2}']);
    await cache.putRows('quote', {'q2': '{"a":22}'}, scope: 'r1', replaceScope: true);
    expect(await cache.rowsInScope('quote', 'r1'), ['{"a":22}']);
    expect(await cache.row('quote', 'q3'), '{"a":3}');
  });

  test('outbox replays in order, retries with backoff and stops at a failure', () async {
    var now = DateTime(2026, 10, 2, 12);
    final net = StreamController<List<ConnectivityResult>>();
    final outbox = Outbox(cache, connectivity: net.stream, clock: () => now);
    final sent = <String>[];
    var online = false;
    outbox.register('msg', (p) async {
      if (!online) throw Exception('offline');
      sent.add(p);
    });

    await cache.enqueue('msg', 'one', at: now);
    await cache.enqueue('msg', 'two', at: now);
    await outbox.drain();
    expect(sent, isEmpty);
    expect(await outbox.pendingCount.first, 2);

    online = true;
    await outbox.drain(); // 'one' is backing off; nothing overtakes it
    expect(sent, isEmpty);

    now = now.add(Outbox.backoff(0));
    await outbox.drain();
    expect(sent, ['one', 'two']);
    expect(await outbox.pendingCount.first, 0);
    await outbox.dispose();
    unawaited(net.close());
  });

  test('permanent errors drop the entry', () async {
    final outbox = Outbox(cache, connectivity: const Stream.empty());
    outbox.register('msg', (_) async => throw const PermanentOutboxError('chat closed'));
    await cache.enqueue('msg', 'x');
    await outbox.drain();
    expect(await outbox.pendingCount.first, 0);
  });

  test('stale-while-revalidate shows cache, then live, and survives offline', () async {
    final live = StreamController<String>();
    final written = <String>[];
    final values = <String>[];
    final sub = staleWhileRevalidate<String>(
      readCache: () async => 'cached',
      live: live.stream,
      writeCache: (v) async => written.add(v),
    ).listen(values.add, onError: (_) => values.add('error'));
    await pumpEventQueue();
    live.addError(Exception('offline'));
    await pumpEventQueue();
    expect(values, ['cached']);
    live.add('fresh');
    await pumpEventQueue();
    expect(values, ['cached', 'fresh']);
    expect(written, ['fresh']);
    await sub.cancel();
  });
}
