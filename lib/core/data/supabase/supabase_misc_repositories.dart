import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show RealtimeChannel;

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

/// Orders (RLS: parties). Realtime on `orders` (RLS-filtered: only my
/// orders) plus my `notifications` (new reviews and anything else that
/// doesn't touch the order row), and local changes.
class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository(this.ctx);
  final SupabaseContext ctx;

  /// `orders.request_title` is kept in sync by the server, so sellers (who
  /// can't read `requests`) get the title without a join.
  static const select = '*, order_events(status, at, note, created_at), reviews(role), seller:sellers(business_name)';

  void Function(RealtimeChannel, void Function()) _bind(String uid, {String? orderId}) {
    final orders = orderId == null ? ctx.onTable('orders') : ctx.onTable('orders', column: 'id', equals: orderId);
    final inbox = ctx.onTable('notifications', column: 'user_id', equals: uid);
    return (ch, refresh) {
      orders(ch, refresh);
      inbox(ch, refresh);
    };
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
      return [for (final r in rows) mapOrder(r, fallbackCurrency: ctx.currency)];
    }

    return ctx.liveQuery(name: 'orders:$uid', fetch: fetch, bind: _bind(uid), topics: {Topics.orders});
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
      return mapOrder(row, fallbackCurrency: ctx.currency, contacts: contacts);
    }

    return ctx.liveQuery(
      name: 'order:$id',
      fetch: fetch,
      bind: _bind(uid, orderId: id),
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

  /// Payment methods `record_payment` accepts; anything else is recorded as
  /// `other`.
  static const serverPaymentMethods = {
    'cash',
    'upi',
    'card',
    'bank_transfer',
    'zelle',
    'check',
    'seller_link',
    'other',
  };

  static String serverPaymentMethod(String method) => serverPaymentMethods.contains(method) ? method : 'other';

  @override
  Future<void> recordPayment(String orderId, String method, Money amount) => guardState(() async {
    await ctx.client.rpc<dynamic>(
      'record_payment',
      params: {'p_order_id': orderId, 'p_method': serverPaymentMethod(method), 'p_amount_minor': amount.minorInt},
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
