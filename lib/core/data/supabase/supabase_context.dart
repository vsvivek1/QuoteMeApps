import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../features/auth/domain/auth_repository.dart';
import '../../cache/app_cache.dart';
import '../../cache/outbox.dart';
import '../../cache/swr.dart';
import '../../config/country_config.dart';
import '../../services/device_services.dart';
import 'edge_functions.dart';
import 'mappers.dart';

/// Storage buckets (API.md section 4).
abstract final class Buckets {
  static const sellerMedia = 'seller-media'; // public: {user_id}/...
  static const requestMedia = 'request-media'; // private: {request_id}/... and {request_id}/quotes/{seller_id}/...
  static const verificationDocs = 'verification-docs'; // private: {seller_id}/...
  static const chatMedia = 'chat-media'; // private: {chat_id}/{uuid}.jpg
}

/// Topics for local refreshes of data that has no Realtime publication
/// (profiles, sellers, orders, templates) or that we just changed ourselves.
abstract final class Topics {
  static const profile = 'profile';
  static const seller = 'seller';
  static const orders = 'orders';
  static const chats = 'chats';
  static const requests = 'requests';
  static const quotes = 'quotes';
  static const notifications = 'notifications';
}

/// Shared plumbing for every Supabase repository: client, cache, outbox,
/// storage, a local change bus and the live-query helper.
class SupabaseContext {
  SupabaseContext({
    required this.client,
    required this.config,
    this.cache,
    this.outbox,
    MediaService? media,
    EdgeFunctions? functions,
  }) : media = media ?? MediaService(),
       functions = functions ?? EdgeFunctions(client);

  final SupabaseClient client;
  final CountryConfig config;
  final AppCache? cache;
  final Outbox? outbox;
  final MediaService media;
  final EdgeFunctions functions;
  final _uuid = const Uuid();
  final _bus = StreamController<String>.broadcast();
  final _signed = <String, ({String url, DateTime expires})>{};
  var _channelSeq = 0;

  String get currency => config.currencyCode;
  String newId() => _uuid.v4();

  String? get uidOrNull => client.auth.currentUser?.id;

  String get uid {
    final id = uidOrNull;
    if (id == null) throw const AuthFailure('not_signed_in');
    return id;
  }

  /// Emits [topic] so live queries listening for it re-fetch.
  void changed(String topic) {
    if (!_bus.isClosed) _bus.add(topic);
  }

  Stream<void> topic(Set<String> topics) => _bus.stream.where(topics.contains);

  void clearMemory() => _signed.clear();

  void dispose() => _bus.close();

  // ------------------------------------------------------------- realtime

  /// Emits [fetch] now, then again (debounced) whenever a Realtime event
  /// bound by [bind] arrives, the channel re-subscribes after a reconnect,
  /// or a local [topics] change is signalled. One channel per listener;
  /// it is removed when the listener cancels.
  Stream<T> liveQuery<T>({
    required String name,
    required Future<T> Function() fetch,
    void Function(RealtimeChannel channel, void Function() refresh)? bind,
    Set<String> topics = const {},
    Duration debounce = const Duration(milliseconds: 300),
  }) {
    late StreamController<T> controller;
    RealtimeChannel? channel;
    StreamSubscription<void>? busSub;
    Timer? timer;
    var running = false;
    var again = false;
    var subscribedOnce = false;

    Future<void> run() async {
      if (controller.isClosed) return;
      if (running) {
        again = true;
        return;
      }
      running = true;
      try {
        final v = await fetch();
        if (!controller.isClosed) controller.add(v);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      } finally {
        running = false;
        if (again) {
          again = false;
          unawaited(run());
        }
      }
    }

    void refresh() {
      timer?.cancel();
      timer = Timer(debounce, run);
    }

    controller = StreamController<T>(
      onListen: () {
        unawaited(run());
        if (topics.isNotEmpty) busSub = topic(topics).listen((_) => refresh());
        if (bind != null) {
          try {
            final ch = client.channel('$name#${_channelSeq++}');
            bind(ch, refresh);
            channel = ch.subscribe((status, _) {
              if (status == RealtimeSubscribeStatus.subscribed) {
                // Catch up on anything missed while (re)connecting.
                if (subscribedOnce) refresh();
                subscribedOnce = true;
              }
            });
          } catch (e) {
            debugPrint('realtime $name: $e');
          }
        }
      },
      onCancel: () async {
        timer?.cancel();
        await busSub?.cancel();
        final ch = channel;
        channel = null;
        if (ch != null) {
          try {
            await client.removeChannel(ch);
          } catch (_) {}
        }
      },
    );
    return controller.stream;
  }

  /// Binds `postgres_changes` (all events) on [table], optionally filtered by
  /// `column=eq.value`.
  void Function(RealtimeChannel, void Function()) onTable(String table, {String? column, Object? equals}) =>
      (ch, refresh) => ch.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        filter: column == null
            ? null
            : PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: column, value: equals),
        callback: (_) => refresh(),
      );

  // ---------------------------------------------------------------- cache

  /// Stale-while-revalidate over raw server rows: cached rows (if any) first,
  /// then every live result, which is written back to the cache. Mapping
  /// happens after, so the cache always holds the server JSON.
  Stream<List<JsonRow>> cachedRows({
    required String kind,
    required String scope,
    required Stream<List<JsonRow>> live,
    String Function(JsonRow row)? idOf,
  }) {
    final c = cache;
    if (c == null) return live;
    return staleWhileRevalidate<List<JsonRow>>(
      readCache: () async {
        final rows = await c.rowsInScope(kind, scope);
        if (rows.isEmpty) return null;
        return [for (final r in rows) Map<String, dynamic>.from(jsonDecode(r) as Map)];
      },
      live: live,
      writeCache: (rows) => c.putRows(
        kind,
        {for (final r in rows) (idOf?.call(r) ?? r['id'].toString()): jsonEncode(r)},
        scope: scope,
        replaceScope: true,
      ),
    );
  }

  Stream<JsonRow?> cachedRow({required String kind, required String id, required Stream<JsonRow?> live}) {
    final c = cache;
    if (c == null) return live;
    return staleWhileRevalidate<JsonRow?>(
      // Single rows live under '<kind>:one' so they never move a row out of
      // a list scope; a row cached by a list is still found.
      readCache: () async {
        final r = await c.row('$kind:one', id) ?? await c.row(kind, id);
        return r == null ? null : Map<String, dynamic>.from(jsonDecode(r) as Map);
      },
      live: live,
      writeCache: (row) async {
        if (row != null) await c.putRows('$kind:one', {id: jsonEncode(row)}, scope: id);
      },
    );
  }

  // -------------------------------------------------------------- storage

  static String contentTypeFor(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  static String extensionOf(String path) {
    final name = path.split('/').last;
    final dot = name.lastIndexOf('.');
    return dot < 0 ? 'jpg' : name.substring(dot + 1).toLowerCase();
  }

  static bool isImagePath(String path) =>
      const {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'}.contains(extensionOf(path));

  /// A device file path (as opposed to a storage path or URL).
  static bool isLocalPath(String path) =>
      !path.startsWith('http://') && !path.startsWith('https://') && (path.startsWith('/') || path.contains(':\\'));

  /// Uploads a local file to `bucket/path`. Images that did not come out of
  /// [MediaService.compress] (always `.jpg`) are compressed first (max 1600
  /// px, ~75% JPEG); the stored object then uses `.jpg`.
  Future<String> upload(String bucket, String Function(String ext) pathFor, String localPath) async {
    var file = localPath;
    var ext = extensionOf(localPath);
    if (isImagePath(localPath) && ext != 'jpg') {
      file = await media.compress(localPath);
      ext = extensionOf(file);
    }
    final path = pathFor(ext);
    final bytes = await File(file).readAsBytes();
    await client.storage
        .from(bucket)
        .uploadBinary(path, bytes, fileOptions: FileOptions(contentType: contentTypeFor(path), upsert: false));
    return path;
  }

  String publicUrl(String bucket, String path) => client.storage.from(bucket).getPublicUrl(path);

  static const _signedTtl = Duration(hours: 1);

  /// Signed URLs (about 1 h, reused until 5 minutes before expiry) for
  /// objects in a private bucket. Missing objects are left out.
  Future<Map<String, String>> signedUrls(String bucket, Iterable<String> paths) async {
    final now = DateTime.now();
    final out = <String, String>{};
    final missing = <String>[];
    for (final p in paths.toSet()) {
      if (p.startsWith('http')) {
        out[p] = p;
        continue;
      }
      final hit = _signed['$bucket/$p'];
      if (hit != null && hit.expires.isAfter(now.add(const Duration(minutes: 5)))) {
        out[p] = hit.url;
      } else {
        missing.add(p);
      }
    }
    if (missing.isEmpty) return out;
    try {
      final res = await client.storage.from(bucket).createSignedUrlsResult(missing, _signedTtl.inSeconds);
      for (final r in res) {
        if (r is SignedUrlSuccess) {
          out[r.path] = r.signedUrl;
          _signed['$bucket/${r.path}'] = (url: r.signedUrl, expires: now.add(_signedTtl));
        }
      }
    } catch (e) {
      debugPrint('signed urls $bucket: $e');
    }
    return out;
  }

  Future<String?> signedUrl(String bucket, String path) async => (await signedUrls(bucket, [path]))[path];

  // ---------------------------------------------------------------- rpc

  Future<List<JsonRow>> rpcList(String fn, [Map<String, dynamic>? params]) async {
    final res = await client.rpc<dynamic>(fn, params: params);
    if (res is List) return [for (final r in res) Map<String, dynamic>.from(r as Map)];
    if (res is Map) return [Map<String, dynamic>.from(res)];
    return const [];
  }

  Future<JsonRow?> rpcRow(String fn, [Map<String, dynamic>? params]) async {
    final res = await client.rpc<dynamic>(fn, params: params);
    if (res is Map) return Map<String, dynamic>.from(res);
    if (res is List && res.isNotEmpty) return Map<String, dynamic>.from(res.first as Map);
    return null;
  }

  /// `get_profiles_public` display names (id -> row).
  Future<Map<String, JsonRow>> publicProfiles(Iterable<String> ids) async {
    final list = ids.toSet().toList();
    if (list.isEmpty) return const {};
    final rows = await rpcList('get_profiles_public', {'p_ids': list});
    return {for (final r in rows) r['id'].toString(): r};
  }
}
