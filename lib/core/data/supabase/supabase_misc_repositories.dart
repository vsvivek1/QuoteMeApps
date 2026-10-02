import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../features/notifications/domain/app_notification.dart';
import '../../../features/notifications/domain/notification_repository.dart';
import '../../../features/orders/domain/order.dart';
import '../../../features/orders/domain/order_repository.dart';
import '../../../features/reviews/domain/review.dart';
import '../../../features/reviews/domain/review_repository.dart';
import '../../../features/safety/domain/safety_repository.dart';
import '../../../features/settings/domain/app_settings.dart';
import '../../money/money.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

// ------------------------------------------------------------------- orders

/// Orders (RLS: parties). `orders` has no Realtime publication, so lists
/// refresh on `order_status` notifications and on local changes.
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this.ctx);
  final SupabaseContext ctx;

  static const select =
      '*, order_events(status, at, note, created_at), reviews(role), '
      'seller:sellers(business_name), request:requests(title)';

  /// Request titles for orders where I'm the seller (`requests` is
  /// buyer-only under RLS; `get_my_quotes` carries a safe summary).
  Future<Map<String, String>> _sellerTitles(List<JsonRow> rows) async {
    final uid = ctx.uidOrNull;
    if (!rows.any((r) => r['seller_id'] == uid && asMap(r['request'])['title'] == null)) return const {};
    try {
      final quotes = await ctx.rpcList('get_my_quotes', {'p_tab': 'won', 'p_limit': 50});
      return {
        for (final q in quotes)
          if (q['order_id'] != null) q['order_id'].toString(): asMap(q['request'])['title']?.toString() ?? '',
      };
    } catch (e) {
      debugPrint('order titles: $e');
      return const {};
    }
  }

  @override
  Stream<List<Order>> watchMyOrders() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(const []);
    Future<List<Order>> fetch() async {
      final rows = await ctx.client
          .from('orders')
          .select(select)
          .or('buyer_id.eq.$uid,seller_id.eq.$uid')
          .order('created_at', ascending: false)
          .limit(100);
      final titles = await _sellerTitles(rows);
      return [for (final r in rows) mapOrder(r, fallbackCurrency: ctx.currency, title: titles[r['id']])];
    }

    return ctx.liveQuery(
      name: 'orders:$uid',
      fetch: fetch,
      bind: ctx.onTable('notifications', column: 'user_id', equals: uid),
      topics: {Topics.orders},
    );
  }

  @override
  Stream<Order?> watchOrder(String id) {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(null);
    Future<Order?> fetch() async {
      final row = await ctx.client.from('orders').select(select).eq('id', id).maybeSingle();
      if (row == null) return null;
      Map<String, Object?>? contacts;
      if (row['status'] != 'cancelled') {
        try {
          final c = await ctx.client.rpc<dynamic>('get_order_contacts', params: {'p_order_id': id});
          if (c is Map) contacts = asMap(c);
        } catch (e) {
          debugPrint('order contacts: $e');
        }
      }
      final titles = await _sellerTitles([row]);
      return mapOrder(row, fallbackCurrency: ctx.currency, title: titles[id], contacts: contacts);
    }

    return ctx.liveQuery(
      name: 'order:$id',
      fetch: fetch,
      bind: ctx.onTable('notifications', column: 'user_id', equals: uid),
      topics: {Topics.orders},
    );
  }

  @override
  Future<void> updateStatus(String orderId, OrderStatus status, {String? note}) => guardState(() async {
    await ctx.client.rpc<dynamic>(
      'update_order_status',
      params: {'p_order_id': orderId, 'p_status': status.name, 'p_note': note},
    );
    ctx.changed(Topics.orders);
  });

  /// Payment methods the server accepts; anything else is recorded as
  /// `other` (e.g. the USA app's `check`).
  static const serverPaymentMethods = {'cash', 'upi', 'card', 'bank_transfer', 'zelle', 'seller_link', 'other'};

  @override
  Future<void> recordPayment(String orderId, String method, Money amount) => guardState(() async {
    await ctx.client.rpc<dynamic>(
      'record_payment',
      params: {
        'p_order_id': orderId,
        'p_method': serverPaymentMethods.contains(method) ? method : 'other',
        'p_amount_minor': amount.minorInt,
      },
    );
    ctx.changed(Topics.orders);
  });
}

// ------------------------------------------------------------------ reviews

class SupabaseReviewRepository implements ReviewRepository {
  SupabaseReviewRepository(this.ctx);
  final SupabaseContext ctx;

  @override
  Future<void> submitReview({
    required String orderId,
    required int stars,
    List<String> tags = const [],
    String text = '',
    List<String> photoPaths = const [],
  }) => guardState(() async {
    final uid = ctx.uid;
    final photos = <String>[];
    for (final p in photoPaths.take(6)) {
      photos.add(
        SupabaseContext.isLocalPath(p)
            ? ctx.publicUrl(
                Buckets.sellerMedia,
                await ctx.upload(Buckets.sellerMedia, (ext) => '$uid/reviews/${ctx.newId()}.$ext', p),
              )
            : p,
      );
    }
    await ctx.client.rpc<dynamic>(
      'submit_review',
      params: {
        'p_order_id': orderId,
        'p_stars': stars,
        'p_tags': tags,
        'p_text': text.trim().isEmpty ? null : text.trim(),
        'p_photos': photos,
      },
    );
    ctx
      ..changed(Topics.orders)
      ..changed(Topics.seller);
  });

  @override
  Future<List<Review>> reviewsFor(String userId) async {
    final rows = await ctx.client
        .from('reviews')
        .select()
        .eq('to_id', userId)
        .eq('hidden', false)
        .order('created_at', ascending: false)
        .limit(100);
    Map<String, JsonRow> names = const {};
    if (ctx.uidOrNull != null) {
      try {
        names = await ctx.publicProfiles([
          for (final r in rows)
            if (r['from_id'] != null) r['from_id'].toString(),
        ]);
      } catch (_) {}
    }
    return [for (final r in rows) mapReview(r, authorName: names[r['from_id']]?['display_name']?.toString())];
  }

  @override
  Future<void> reply(String reviewId, String text) => guardState(() async {
    await ctx.client.rpc<dynamic>('seller_reply_review', params: {'p_review_id': reviewId, 'p_reply': text});
  });
}

// ------------------------------------------------------------ notifications

class SupabaseNotificationRepository implements NotificationRepository {
  SupabaseNotificationRepository(this.ctx);
  final SupabaseContext ctx;

  @override
  Stream<List<AppNotification>> watchInbox() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(const []);
    Future<List<AppNotification>> fetch() async {
      final rows = await ctx.client
          .from('notifications')
          .select('id, type, payload, read_at, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(100);
      return [for (final r in rows) mapNotification(r)];
    }

    return ctx.liveQuery(
      name: 'inbox:$uid',
      fetch: fetch,
      bind: ctx.onTable('notifications', column: 'user_id', equals: uid),
      topics: {Topics.notifications},
    );
  }

  @override
  Future<void> markRead(String id) => guardState(() async {
    await ctx.client.rpc<dynamic>(
      'mark_notifications_read',
      params: {
        'p_ids': [id],
      },
    );
    ctx.changed(Topics.notifications);
  });

  @override
  Future<void> markAllRead() => guardState(() async {
    await ctx.client.rpc<dynamic>('mark_notifications_read', params: {'p_ids': null});
    ctx.changed(Topics.notifications);
  });

  @override
  Future<void> registerDeviceToken(String token, String platform) => guardState(
    () => ctx.client.rpc<dynamic>(
      'register_device_token',
      params: {
        'p_token': token,
        'p_platform': platform,
        'p_locale': PlatformDispatcher.instance.locale.toLanguageTag(),
      },
    ),
  );

  @override
  Future<void> removeDeviceToken(String token) =>
      guardState(() => ctx.client.from('device_tokens').delete().eq('fcm_token', token));
}

// ------------------------------------------------------------------- safety

class SupabaseSafetyRepository implements SafetyRepository {
  SupabaseSafetyRepository(this.ctx);
  final SupabaseContext ctx;

  /// App reason keys -> `reports.reason` values.
  static String reasonJson(String reason) => switch (reason) {
    'abuse' => 'abusive',
    'prohibited' => 'prohibited_item',
    'spam' || 'fraud' || 'abusive' || 'inappropriate' || 'prohibited_item' || 'fake' => reason,
    _ => 'other',
  };

  @override
  Future<void> report(String targetType, String targetId, String reason, {String? details}) => guardState(
    () => ctx.client.rpc<dynamic>(
      'report_content',
      params: {
        'p_target_type': targetType,
        'p_target_id': targetId,
        'p_reason': reasonJson(reason),
        'p_details': details,
      },
    ),
  );

  @override
  Future<void> block(String userId) => guardState(() async {
    await ctx.client.rpc<dynamic>('block_user', params: {'p_user_id': userId});
    ctx
      ..changed(Topics.quotes)
      ..changed(Topics.chats);
  });

  @override
  Future<void> unblock(String userId) => guardState(() async {
    await ctx.client.rpc<dynamic>('unblock_user', params: {'p_user_id': userId});
    ctx
      ..changed(Topics.quotes)
      ..changed(Topics.chats);
  });

  @override
  Future<Set<String>> blockedUserIds() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const {};
    final rows = await ctx.client.from('blocks').select('blocked_id').eq('blocker_id', uid);
    return {for (final r in rows) r['blocked_id'].toString()};
  }
}

// -------------------------------------------------------------------- flags

/// Public `app_settings` via `get_app_settings()` (anon OK). Falls back to
/// the defaults when offline so start-up never blocks on it.
class SupabaseFlagsRepository implements FlagsRepository {
  SupabaseFlagsRepository(this.ctx);
  final SupabaseContext ctx;
  AppFlags? _last;

  @override
  Future<AppFlags> load() async {
    try {
      final s = await ctx.client.rpc<dynamic>('get_app_settings');
      return _last = mapFlags(s is Map ? Map<String, dynamic>.from(s) : const {});
    } catch (e) {
      debugPrint('get_app_settings: $e');
      return _last ?? const AppFlags();
    }
  }
}
