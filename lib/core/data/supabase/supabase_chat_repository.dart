import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../features/chat/domain/chat.dart';
import '../../../features/chat/domain/chat_repository.dart';
import '../../cache/outbox.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// Chats and messages: `open_chat`, direct message inserts (text through
/// the outbox so they survive being offline), `chat-media` uploads,
/// `mark_read`, Realtime on `chats` and `messages`.
class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository(this.ctx) {
    ctx.outbox?.register(outboxKind, _sendQueued);
  }

  final SupabaseContext ctx;

  static const outboxKind = 'chat_text';
  static const pageSize = 50;
  static const _chatKind = 'chat';
  static const _msgKind = 'message';

  /// Messages not yet confirmed by the server, per chat (optimistic UI).
  final _pending = <String, List<ChatMessage>>{};

  /// Request titles a seller can't read from `requests` (RLS: buyer only).
  final _titles = <String, String>{};

  // ------------------------------------------------------------------ chats

  Future<List<JsonRow>> _fetchChatRows() async {
    final uid = ctx.uid;
    final rows = await ctx.client
        .from('chats')
        .select('*, request:requests(title), seller:sellers(business_name, logo_url)')
        .or('buyer_id.eq.$uid,seller_id.eq.$uid')
        .order('last_message_at', ascending: false, nullsFirst: false)
        .limit(100);
    return rows;
  }

  Future<List<Chat>> _decorate(List<JsonRow> rows) async {
    final uid = ctx.uidOrNull;
    if (uid == null || rows.isEmpty) return const [];
    final ids = [for (final r in rows) r['id'].toString()];

    // Titles for chats where I'm the seller come from get_my_quotes.
    final missing = [
      for (final r in rows)
        if (asMap(r['request'])['title'] == null && !_titles.containsKey(r['request_id'])) r['request_id'],
    ];
    if (missing.isNotEmpty) {
      try {
        for (final q in await ctx.rpcList('get_my_quotes', {'p_limit': 50})) {
          final req = asMap(q['request']);
          if (req['id'] != null) _titles[req['id'].toString()] = req['title']?.toString() ?? '';
        }
        // Don't ask again on every refresh for requests outside that page.
        for (final id in missing) {
          _titles.putIfAbsent(id.toString(), () => '');
        }
      } catch (e) {
        debugPrint('chat titles: $e');
      }
    }

    // Buyer display names for chats where I'm the seller.
    final buyerIds = [
      for (final r in rows)
        if (r['seller_id'] == uid) r['buyer_id'].toString(),
    ];
    final profiles = await ctx.publicProfiles(buyerIds).catchError((Object _) => const <String, JsonRow>{});

    final unread = <String, int>{};
    final accepted = <String>{};
    try {
      final msgs = await ctx.client
          .from('messages')
          .select('chat_id')
          .inFilter('chat_id', ids)
          .isFilter('read_at', null)
          .neq('sender_id', uid);
      for (final m in msgs) {
        unread.update(m['chat_id'].toString(), (n) => n + 1, ifAbsent: () => 1);
      }
      final orders = await ctx.client
          .from('orders')
          .select('request_id, seller_id, status')
          .or('buyer_id.eq.$uid,seller_id.eq.$uid')
          .neq('status', 'cancelled');
      for (final o in orders) {
        accepted.add('${o['request_id']}|${o['seller_id']}');
      }
    } catch (e) {
      debugPrint('chat decorations: $e');
    }

    return [
      for (final r in rows)
        () {
          final iAmBuyer = r['buyer_id'] == uid;
          final seller = asMap(r['seller']);
          final buyer = profiles[r['buyer_id']];
          final title = asMap(r['request'])['title']?.toString() ?? _titles[r['request_id']] ?? '';
          return mapChat(
            r,
            requestTitle: title,
            counterpartName: iAmBuyer
                ? seller['business_name']?.toString() ?? ''
                : buyer?['display_name']?.toString() ?? '',
            counterpartPhotoUrl: iAmBuyer ? seller['logo_url']?.toString() : buyer?['photo_url']?.toString(),
            unread: unread[r['id']] ?? 0,
            quoteAccepted: accepted.contains('${r['request_id']}|${r['seller_id']}'),
          );
        }(),
    ];
  }

  @override
  Stream<List<Chat>> watchMyChats() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(const []);
    final live = ctx.liveQuery<List<JsonRow>>(
      name: 'chats:$uid',
      fetch: _fetchChatRows,
      bind: ctx.onTable('chats'), // RLS: only my chats
      topics: {Topics.chats},
    );
    return ctx.cachedRows(kind: _chatKind, scope: uid, live: live).asyncMap(_decorate);
  }

  @override
  Future<Chat?> getChat(String chatId) async {
    final row = await ctx.client
        .from('chats')
        .select('*, request:requests(title), seller:sellers(business_name, logo_url)')
        .eq('id', chatId)
        .maybeSingle();
    if (row == null) return null;
    final list = await _decorate([row]);
    return list.firstOrNull;
  }

  @override
  Future<String> openChat({required String requestId, required String sellerId}) => guardState(() async {
    final uid = ctx.uid;
    final row = await ctx.rpcRow('open_chat', {
      'p_request_id': requestId,
      // Buyers name the seller; a seller opens their own chat with null.
      'p_seller_id': sellerId == uid ? null : sellerId,
    });
    final id = row?['id']?.toString();
    if (id == null) throw StateError('chat_not_found');
    ctx.changed(Topics.chats);
    return id;
  });

  // --------------------------------------------------------------- messages

  Future<List<ChatMessage>> _mapMessages(List<JsonRow> rows) async {
    final paths = [
      for (final r in rows)
        if (r['attachment_path'] != null) r['attachment_path'].toString(),
    ];
    final urls = paths.isEmpty ? const <String, String>{} : await ctx.signedUrls(Buckets.chatMedia, paths);
    return [for (final r in rows) mapChatMessage(r, attachmentUrl: urls[r['attachment_path']])];
  }

  final _pendingChanged = StreamController<String>.broadcast();

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    Future<List<JsonRow>> fetch() async {
      final rows = await ctx.client
          .from('messages')
          .select()
          .eq('chat_id', chatId)
          .order('created_at', ascending: false)
          .limit(pageSize);
      return rows.reversed.toList(); // oldest first, like the demo
    }

    final live = ctx.liveQuery<List<JsonRow>>(
      name: 'messages:$chatId',
      fetch: fetch,
      bind: ctx.onTable('messages', column: 'chat_id', equals: chatId),
    );
    final server = ctx.cachedRows(kind: _msgKind, scope: chatId, live: live).asyncMap(_mapMessages);

    // Merge the optimistic (unsent / failed) messages on top.
    late StreamController<List<ChatMessage>> out;
    StreamSubscription<List<ChatMessage>>? sub;
    StreamSubscription<String>? pendingSub;
    var last = const <ChatMessage>[];
    void emit() {
      if (out.isClosed) return;
      // A sent message stays as its optimistic copy until the server row
      // shows up, so it never blinks out between insert and refetch.
      final pending = _pending[chatId];
      pending?.removeWhere(
        (p) =>
            p.sendState == SendState.sent &&
            last.any(
              (m) =>
                  m.senderId == p.senderId &&
                  m.body == p.body &&
                  !m.createdAt.isBefore(p.createdAt.subtract(const Duration(minutes: 5))),
            ),
      );
      if (pending != null && pending.isEmpty) _pending.remove(chatId);
      out.add([...last, ...?_pending[chatId]]);
    }

    out = StreamController<List<ChatMessage>>(
      onListen: () {
        sub = server.listen((list) {
          last = list;
          emit();
        }, onError: out.addError);
        pendingSub = _pendingChanged.stream.where((c) => c == chatId).listen((_) => emit());
        if (_pending[chatId]?.isNotEmpty ?? false) emit();
      },
      onCancel: () async {
        await sub?.cancel();
        await pendingSub?.cancel();
      },
    );
    return out.stream;
  }

  @override
  Future<List<ChatMessage>> olderMessages(String chatId, DateTime before) async {
    final rows = await ctx.client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .lt('created_at', before.toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(pageSize);
    return _mapMessages(rows.reversed.toList());
  }

  void _setPending(String chatId, String clientId, ChatMessage? m) {
    final list = _pending.putIfAbsent(chatId, () => []);
    list.removeWhere((x) => x.clientId == clientId);
    if (m != null) list.add(m);
    if (list.isEmpty) _pending.remove(chatId);
    _pendingChanged.add(chatId);
  }

  void _markSent(String chatId, String clientId) {
    final m = _pending[chatId]?.where((x) => x.clientId == clientId).firstOrNull;
    if (m != null) _setPending(chatId, clientId, m.copyWith(sendState: SendState.sent));
  }

  Future<void> _insertText(Map<String, dynamic> p) => ctx.client.from('messages').insert({
    'chat_id': p['chat_id'],
    'sender_id': p['sender_id'],
    'type': 'text',
    'body': p['body'],
  });

  /// Outbox handler: replays a queued text message.
  Future<void> _sendQueued(String payload) async {
    final p = Map<String, dynamic>.from(jsonDecode(payload) as Map);
    final chatId = p['chat_id'].toString();
    final clientId = p['client_id'].toString();
    try {
      await _insertText(p);
      _markSent(chatId, clientId);
    } catch (e) {
      if (isNetworkError(e)) rethrow; // retried with backoff
      final m = _pending[chatId]?.where((x) => x.clientId == clientId).firstOrNull;
      if (m != null) _setPending(chatId, clientId, m.copyWith(sendState: SendState.failed));
      throw PermanentOutboxError(errorCode(e));
    }
  }

  @override
  Future<void> sendText(String chatId, String text) async {
    final body = text.trim();
    if (body.isEmpty) return;
    final uid = ctx.uid;
    final clientId = ctx.newId();
    final optimistic = ChatMessage(
      id: clientId,
      chatId: chatId,
      senderId: uid,
      body: body,
      createdAt: DateTime.now(),
      sendState: SendState.sending,
      clientId: clientId,
    );
    _setPending(chatId, clientId, optimistic);
    final payload = {'chat_id': chatId, 'sender_id': uid, 'body': body, 'client_id': clientId};
    try {
      await _insertText(payload);
      _markSent(chatId, clientId);
    } catch (e) {
      final outbox = ctx.outbox;
      if (isNetworkError(e) && outbox != null) {
        await outbox.add(outboxKind, jsonEncode(payload)); // stays "sending" until it goes out
        return;
      }
      _setPending(chatId, clientId, optimistic.copyWith(sendState: SendState.failed));
      throw toStateError(e);
    }
  }

  @override
  Future<void> sendImage(String chatId, String localPath) => guardState(() async {
    final uid = ctx.uid;
    // chat-media/{chat_id}/{uuid}.jpg (compressed on device first).
    final path = await ctx.upload(Buckets.chatMedia, (ext) => '$chatId/${ctx.newId()}.$ext', localPath);
    await ctx.client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': uid,
      'type': 'image',
      'attachment_path': path,
    });
  });

  @override
  Future<void> markRead(String chatId) async {
    try {
      final n = await ctx.client.rpc<dynamic>('mark_read', params: {'p_chat_id': chatId});
      if ((asInt(n) ?? 0) > 0) ctx.changed(Topics.chats);
    } catch (e) {
      debugPrint('mark_read: $e');
    }
  }

  // Typing indicators are not part of the backend contract yet.
  @override
  Stream<bool> typing(String chatId) => const Stream.empty();

  @override
  void setTyping(String chatId, bool typing) {}
}
