import '../../../features/community/domain/community.dart';
import '../../../features/community/domain/community_repository.dart';
import '../../../features/requests/domain/buyer_request.dart';
import '../../money/money.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// Community feed and group buys (API.md "Community feed"): reads through
/// `get_community_feed`, `get_feed_post`, `get_feed_comments`,
/// `get_group_buy` (anon too); writes through the matching RPCs. There is
/// no Realtime publication for comments, so screens refresh on the local
/// [Topics.community] signal and on pull-to-refresh.
class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this.ctx);
  final SupabaseContext ctx;

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw CommunityFailure(errorCode(e), e.toString());
    }
  }

  static Map<String, Object?> _filters(FeedFilter f, int? categoryId) => {
    'category_id': ?categoryId,
    if (f == FeedFilter.groupBuys) 'group_buy_only': true,
    if (f == FeedFilter.open) 'open_only': true,
    if (f == FeedFilter.mine) 'mine': true,
  };

  @override
  Stream<List<FeedPost>> watchFeed(FeedFilter filter, {int? categoryId}) => ctx.liveQuery(
    name: 'feed:${filter.name}:$categoryId',
    fetch: () async {
      final rows = await ctx.rpcList('get_community_feed', {'p_filters': _filters(filter, categoryId), 'p_limit': 50});
      return [for (final r in rows) mapFeedPost(r, fallbackCurrency: ctx.currency)];
    },
    topics: {Topics.community},
  );

  @override
  Stream<FeedPost?> watchPost(String requestId) => ctx.liveQuery(
    name: 'feed-post:$requestId',
    fetch: () async {
      try {
        final row = await ctx.rpcRow('get_feed_post', {'p_request_id': requestId});
        return row == null ? null : mapFeedPost(row, fallbackCurrency: ctx.currency);
      } catch (e) {
        if (serverErrorCode(e) == 'post_not_found') return null;
        rethrow;
      }
    },
    topics: {Topics.community},
  );

  @override
  Stream<List<FeedComment>> watchComments(String requestId) => ctx.liveQuery(
    name: 'feed-comments:$requestId',
    fetch: () async {
      final rows = await ctx.rpcList('get_feed_comments', {'p_request_id': requestId, 'p_limit': 200});
      return [for (final r in rows) mapFeedComment(r, requestId)];
    },
    topics: {Topics.community},
  );

  @override
  Future<FeedComment> addComment(String requestId, String body, {String? parentId, bool asSeller = false}) =>
      _guard(() async {
        final row = await ctx.rpcRow('post_comment', {
          'p_request_id': requestId,
          'p_body': body,
          'p_parent_id': parentId,
          'p_as_seller': asSeller,
        });
        ctx.changed(Topics.community);
        return FeedComment(
          id: row!['id'].toString(),
          requestId: requestId,
          parentId: asString(row['parent_id']),
          body: asString(row['body']) ?? body,
          createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
          asSeller: asBool(row['as_seller']),
          isMine: true,
        );
      });

  @override
  Future<void> deleteComment(String commentId) => _guard(() async {
    await ctx.client.rpc<dynamic>('delete_comment', params: {'p_comment_id': commentId});
    ctx.changed(Topics.community);
  });

  @override
  Future<bool> toggleLike(String requestId) => _guard(() async {
    final row = await ctx.rpcRow('toggle_request_like', {'p_request_id': requestId});
    ctx.changed(Topics.community);
    return asBool(row?['liked']);
  });

  @override
  Future<void> publish(String requestId, {required bool public}) => _guard(() async {
    await ctx.client.rpc<dynamic>('publish_request', params: {'p_request_id': requestId, 'p_public': public});
    ctx
      ..changed(Topics.community)
      ..changed(Topics.requests);
  });

  @override
  Future<void> setGroupBuy(String requestId, {required bool enabled, String? unit, num myQty = 1}) => _guard(() async {
    await ctx.client.rpc<dynamic>(
      'set_group_buy',
      params: {'p_request_id': requestId, 'p_enabled': enabled, 'p_unit': unit, 'p_my_qty': myQty},
    );
    ctx
      ..changed(Topics.community)
      ..changed(Topics.requests);
  });

  @override
  Future<GroupBuy> joinGroupBuy(String requestId, num qty, {String? note}) => _guard(() async {
    final row = await ctx.rpcRow('join_group_buy', {'p_request_id': requestId, 'p_qty': qty, 'p_note': note});
    ctx.changed(Topics.community);
    return mapGroupBuy(row ?? const {}, ctx.currency);
  });

  @override
  Future<GroupBuy> leaveGroupBuy(String requestId) => _guard(() async {
    final row = await ctx.rpcRow('leave_group_buy', {'p_request_id': requestId});
    ctx.changed(Topics.community);
    return mapGroupBuy(row ?? const {}, ctx.currency);
  });

  @override
  Future<GroupBuy?> getGroupBuy(String requestId) async {
    try {
      final row = await ctx.rpcRow('get_group_buy', {'p_request_id': requestId});
      return row == null ? null : mapGroupBuy(row, ctx.currency);
    } catch (e) {
      if (serverErrorCode(e) == 'post_not_found') return null;
      throw CommunityFailure(errorCode(e), e.toString());
    }
  }

  @override
  Future<List<GroupMember>> groupMembers(String requestId) => _guard(() async {
    final rows = await ctx.rpcList('get_group_members', {'p_request_id': requestId});
    return [
      for (final r in rows)
        GroupMember(
          userId: r['user_id'].toString(),
          name: asString(r['display_name']) ?? '',
          qty: num.tryParse('${r['qty']}') ?? 0,
          note: asString(r['note']),
          phone: asString(r['phone']),
        ),
    ];
  });

  @override
  Future<void> setQuoteTiers(String quoteId, List<PriceTier> tiers) => _guard(() async {
    await ctx.client.rpc<dynamic>(
      'set_quote_tiers',
      params: {
        'p_quote_id': quoteId,
        'p_tiers': [
          for (final t in tiers) {'min_qty': t.minQty, 'unit_price_minor': t.unitPrice.minorInt},
        ],
      },
    );
    ctx
      ..changed(Topics.community)
      ..changed(Topics.quotes);
  });

  @override
  Future<List<PriceTier>> quoteTiers(String quoteId) => _guard(() async {
    final rows = await ctx.client
        .from('quote_price_tiers')
        .select('min_qty, unit_price_minor')
        .eq('quote_id', quoteId)
        .order('min_qty');
    return [
      for (final r in rows)
        PriceTier(
          minQty: num.tryParse('${r['min_qty']}') ?? 1,
          unitPrice: moneyOrZero(r['unit_price_minor'], ctx.currency),
        ),
    ];
  });
}

// ---------------------------------------------------------------- mappers

GroupBuy mapGroupBuy(JsonRow row, String currency) {
  num? n(Object? v) => v == null ? null : num.tryParse('$v');
  final accepted = row['accepted'];
  return GroupBuy(
    unit: asString(row['unit']) ?? 'units',
    totalQty: n(row['total_qty']) ?? 0,
    members: asInt(row['members']) ?? 0,
    myQty: n(row['my_qty']),
    ladder: [
      if (row['ladder'] is List)
        for (final t in row['ladder'] as List)
          if (t is Map)
            PriceTier(minQty: n(t['min_qty']) ?? 1, unitPrice: moneyOrZero(t['unit_price_minor'], currency)),
    ],
    currentUnitPrice: moneyOrNull(row['current_unit_price_minor'], currency),
    nextMinQty: n(row['next_min_qty']),
    nextUnitPrice: moneyOrNull(row['next_unit_price_minor'], currency),
    qtyToNext: n(row['qty_to_next']),
    offers: asInt(row['offers']) ?? 0,
    winner: accepted is Map
        ? GroupWinner(
            sellerId: accepted['seller_id'].toString(),
            businessName: asString(accepted['business_name']) ?? '',
            verified: asBool(accepted['seller_verified']),
            unitPrice: moneyOrNull(accepted['unit_price_minor'], currency),
          )
        : null,
  );
}

FeedPost mapFeedPost(JsonRow row, {required String fallbackCurrency}) {
  final cur = currencyOf(row, fallbackCurrency);
  final group = row['group'];
  return FeedPost(
    id: row['request_id'].toString(),
    categoryId: asInt(row['category_id']) ?? 0,
    title: asString(row['title']) ?? '',
    description: asString(row['description']) ?? '',
    budgetMin: moneyOrNull(row['budget_min_minor'], cur),
    budgetMax: moneyOrNull(row['budget_max_minor'], cur),
    neededBy: parseDate(row['needed_by']),
    locality: asString(row['locality']),
    city: asString(row['city']),
    state: asString(row['state']),
    status: enumByName(RequestStatus.values, row['status'], RequestStatus.open),
    quoteCount: asInt(row['quote_count']) ?? 0,
    commentCount: asInt(row['comment_count']) ?? 0,
    likeCount: asInt(row['like_count']) ?? 0,
    likedByMe: asBool(row['liked_by_me']),
    isMine: asBool(row['is_mine']),
    authorName: asString(row['author_name']) ?? '',
    authorPhotoUrl: asString(row['author_photo_url']),
    quoteWindowEndsAt: parseTimestamp(row['quote_window_ends_at']),
    publishedAt: parseTimestamp(row['published_at']) ?? parseTimestamp(row['created_at']) ?? DateTime.now(),
    group: asBool(row['group_buy']) && group is Map ? mapGroupBuy(Map<String, dynamic>.from(group), cur) : null,
  );
}

FeedComment mapFeedComment(JsonRow row, String requestId) => FeedComment(
  id: row['id'].toString(),
  requestId: requestId,
  parentId: asString(row['parent_id']),
  body: asString(row['body']) ?? '',
  createdAt: parseTimestamp(row['created_at']) ?? DateTime.now(),
  authorName: asString(row['author_name']) ?? '',
  authorPhotoUrl: asString(row['author_photo_url']),
  asSeller: asBool(row['as_seller']),
  sellerId: asString(row['seller_id']),
  sellerVerified: asBool(row['seller_verified']),
  isMine: asBool(row['is_mine']),
  isPostAuthor: asBool(row['is_post_author']),
);
