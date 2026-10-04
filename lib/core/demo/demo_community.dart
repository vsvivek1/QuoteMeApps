import '../../features/auth/domain/auth_repository.dart';
import '../../features/community/domain/community.dart';
import '../../features/community/domain/community_repository.dart';
import '../../features/quotes/domain/quote.dart';
import '../../features/requests/domain/buyer_request.dart';
import 'demo_backend.dart';

/// In-memory community feed mirroring the server rules
/// (supabase/migrations/20261003400*_*.sql): public projection, comments with
/// one level of replies, likes, group buys priced by the best tier at the
/// group's quantity.
class DemoCommunityRepository implements CommunityRepository {
  DemoCommunityRepository(this.b);
  final DemoBackend b;

  DemoBackend get _b => b..seedCommunity();

  String get _uid {
    final id = b.currentUserId;
    if (id == null) throw const AuthFailure('not_signed_in');
    return id;
  }

  bool _visible(BuyerRequest r) =>
      r.isPublic && r.status != RequestStatus.cancelled && !{...?b.blocks[b.currentUserId]}.contains(r.buyerId);

  BuyerRequest _post(String id) {
    final r = _b.requests[id];
    if (r == null || !_visible(r)) throw const CommunityFailure('post_not_found');
    return r;
  }

  static String _displayName(String? name) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Member';
    return parts.length == 1 ? parts.first : '${parts.first} ${parts[1][0]}.';
  }

  // ------------------------------------------------------------ group pricing

  bool _activeQuote(Quote q) =>
      const {QuoteStatus.sent, QuoteStatus.revised, QuoteStatus.shortlisted, QuoteStatus.accepted}.contains(q.status);

  Iterable<Quote> _tiered(String requestId) =>
      b.quotes.values.where((q) => q.requestId == requestId && _activeQuote(q) && b.quoteTiers[q.id] != null);

  PriceTier? _tierAt(List<PriceTier> tiers, num qty) => tiers.where((t) => t.minQty <= qty).lastOrNull;

  PriceTier? _bestAt(String requestId, num qty) {
    PriceTier? best;
    for (final q in _tiered(requestId)) {
      final t = _tierAt(b.quoteTiers[q.id]!, qty);
      if (t != null && (best == null || t.unitPrice < best.unitPrice)) best = t;
    }
    return best;
  }

  GroupBuy _group(BuyerRequest r) {
    final members = b.groupMembers[r.id] ?? const {};
    final total = members.values.fold<num>(0, (a, q) => a + q);
    final thresholds = {for (final q in _tiered(r.id)) ...b.quoteTiers[q.id]!.map((t) => t.minQty)}.toList()..sort();
    final ladder = <PriceTier>[];
    for (final t in thresholds) {
      final best = _bestAt(r.id, t);
      if (best != null && (ladder.isEmpty || best.unitPrice < ladder.last.unitPrice)) {
        ladder.add(PriceTier(minQty: t, unitPrice: best.unitPrice));
      }
    }
    final current = _bestAt(r.id, total)?.unitPrice;
    final next = ladder.where((t) => t.minQty > total && (current == null || t.unitPrice < current)).firstOrNull;
    final me = b.currentUserId;
    GroupWinner? winner;
    final accepted = r.acceptedQuoteId == null ? null : b.quotes[r.acceptedQuoteId];
    if (accepted != null && me != null && (r.buyerId == me || members.containsKey(me))) {
      final tiers = b.quoteTiers[accepted.id] ?? const <PriceTier>[];
      winner = GroupWinner(
        sellerId: accepted.seller.id,
        businessName: accepted.seller.businessName,
        verified: accepted.seller.verified,
        unitPrice: (_tierAt(tiers, total) ?? tiers.firstOrNull)?.unitPrice,
      );
    }
    return GroupBuy(
      unit: b.groupUnits[r.id] ?? 'units',
      totalQty: total,
      members: members.length,
      myQty: me == null ? null : members[me],
      ladder: ladder,
      currentUnitPrice: current,
      nextMinQty: next?.minQty,
      nextUnitPrice: next?.unitPrice,
      qtyToNext: next == null ? null : next.minQty - total,
      offers: _tiered(r.id).length,
      winner: winner,
    );
  }

  FeedPost _map(BuyerRequest r) {
    final me = b.currentUserId;
    return FeedPost(
      id: r.id,
      categoryId: r.categoryId,
      title: r.title,
      description: r.description,
      budgetMin: r.budgetVisible ? r.budgetMin : null,
      budgetMax: r.budgetVisible ? r.budgetMax : null,
      neededBy: r.neededBy,
      locality: r.locality,
      state: r.state,
      status: r.status,
      quoteCount: r.quoteCount,
      commentCount: b.comments[r.id]?.length ?? 0,
      likeCount: b.likes[r.id]?.length ?? 0,
      likedByMe: me != null && (b.likes[r.id]?.contains(me) ?? false),
      isMine: me != null && r.buyerId == me,
      authorName: _displayName(b.profiles[r.buyerId]?.name),
      quoteWindowEndsAt: r.quoteWindowEndsAt,
      publishedAt: r.createdAt,
      group: r.groupBuy ? _group(r) : null,
    );
  }

  // --------------------------------------------------------------- reads

  @override
  Stream<List<FeedPost>> watchFeed(FeedFilter filter, {int? categoryId}) => _b.watch(() {
    final me = b.currentUserId;
    final list = b.requests.values.where((r) {
      if (!_visible(r)) return false;
      if (categoryId != null && r.categoryId != categoryId) return false;
      return switch (filter) {
        FeedFilter.all => true,
        FeedFilter.groupBuys => r.groupBuy,
        FeedFilter.open => r.isOpen,
        FeedFilter.mine => r.buyerId == me,
      };
    }).toList()..sort((x, y) => y.createdAt.compareTo(x.createdAt));
    return [for (final r in list) _map(r)];
  });

  @override
  Stream<FeedPost?> watchPost(String requestId) => _b.watch(() {
    final r = b.requests[requestId];
    return r == null || !(_visible(r) || r.buyerId == b.currentUserId) ? null : _map(r);
  });

  @override
  Stream<List<FeedComment>> watchComments(String requestId) => _b.watch(() {
    final me = b.currentUserId;
    final post = b.requests[requestId];
    return [
      for (final c in b.comments[requestId] ?? const <FeedComment>[])
        c.copyWith(
          isMine: c.isMine || (me != null && c.id.startsWith('$me:')),
          isPostAuthor: post != null && c.id.startsWith('${post.buyerId}:'),
        ),
    ];
  });

  // --------------------------------------------------------------- writes

  @override
  Future<FeedComment> addComment(String requestId, String body, {String? parentId, bool asSeller = false}) async {
    final uid = _uid;
    _post(requestId);
    final text = body.trim();
    if (text.isEmpty) throw const CommunityFailure('comment_empty');
    if (text.length > 1000) throw const CommunityFailure('comment_too_long');
    final seller = asSeller ? b.sellers[uid] : null;
    if (asSeller && seller == null) throw const CommunityFailure('not_a_seller');
    final list = b.comments.putIfAbsent(requestId, () => []);
    final parent = parentId == null ? null : list.where((c) => c.id == parentId).firstOrNull;
    final c = FeedComment(
      id: '$uid:${b.newId()}',
      requestId: requestId,
      parentId: parent == null ? null : (parent.parentId ?? parent.id),
      body: text,
      createdAt: DateTime.now(),
      authorName: seller?.businessName ?? _displayName(b.profiles[uid]?.name),
      asSeller: seller != null,
      sellerId: seller?.id,
      sellerVerified: seller?.isVerified ?? false,
      isMine: true,
    );
    list.add(c);
    final owner = b.requests[requestId]!.buyerId;
    if (owner != uid) {
      b.addNotification(owner, 'feed_comment', {'request_id': requestId, 'route': '/feed/$requestId'});
    } else {
      b.notify();
    }
    return c;
  }

  @override
  Future<void> deleteComment(String commentId) async {
    final uid = _uid;
    for (final entry in b.comments.entries) {
      final c = entry.value.where((c) => c.id == commentId).firstOrNull;
      if (c == null) continue;
      final ownerOfPost = b.requests[entry.key]?.buyerId == uid;
      if (!commentId.startsWith('$uid:') && !ownerOfPost) throw const CommunityFailure('comment_not_found');
      entry.value.removeWhere((x) => x.id == commentId || x.parentId == commentId);
      b.notify();
      return;
    }
    throw const CommunityFailure('comment_not_found');
  }

  @override
  Future<bool> toggleLike(String requestId) async {
    final uid = _uid;
    _post(requestId);
    final set = b.likes.putIfAbsent(requestId, () => {});
    final liked = set.add(uid) || !set.remove(uid);
    b.notify();
    return liked;
  }

  @override
  Future<void> publish(String requestId, {required bool public}) async {
    final r = b.requests[requestId];
    if (r == null || r.buyerId != _uid) throw const CommunityFailure('request_not_found');
    if (!public && r.groupBuy && (b.groupMembers[requestId]?.length ?? 0) > 1) {
      throw const CommunityFailure('group_has_members');
    }
    b.requests[requestId] = r.copyWith(isPublic: public, groupBuy: r.groupBuy && public);
    b.notify();
  }

  @override
  Future<void> setGroupBuy(String requestId, {required bool enabled, String? unit, num myQty = 1}) async {
    final uid = _uid;
    final r = b.requests[requestId];
    if (r == null || r.buyerId != uid) throw const CommunityFailure('request_not_found');
    if (!r.isOpen) throw const CommunityFailure('request_not_open');
    if (!enabled) {
      if ((b.groupMembers[requestId]?.length ?? 0) > 1) throw const CommunityFailure('group_has_members');
      b.groupMembers.remove(requestId);
      b.requests[requestId] = r.copyWith(groupBuy: false);
    } else {
      if (myQty <= 0 || myQty > 1000) throw const CommunityFailure('invalid_qty');
      b.requests[requestId] = r.copyWith(groupBuy: true, isPublic: true);
      b.groupUnits[requestId] = (unit ?? '').trim().isEmpty ? (b.groupUnits[requestId] ?? 'units') : unit!.trim();
      b.groupMembers.putIfAbsent(requestId, () => {})[uid] = myQty;
    }
    b.notify();
  }

  @override
  Future<GroupBuy> joinGroupBuy(String requestId, num qty, {String? note}) async {
    final uid = _uid;
    final r = _post(requestId);
    if (!r.groupBuy) throw const CommunityFailure('post_not_found');
    if (!r.isOpen || (r.quoteWindowEndsAt?.isBefore(DateTime.now()) ?? false)) {
      throw const CommunityFailure('group_closed');
    }
    if (qty <= 0 || qty > 1000) throw const CommunityFailure('invalid_qty');
    final isNew = !(b.groupMembers[requestId]?.containsKey(uid) ?? false);
    b.groupMembers.putIfAbsent(requestId, () => {})[uid] = qty;
    if (isNew && r.buyerId != uid) {
      b.addNotification(r.buyerId, 'group_joined', {'request_id': requestId, 'route': '/feed/$requestId'});
    } else {
      b.notify();
    }
    return _group(r);
  }

  @override
  Future<GroupBuy> leaveGroupBuy(String requestId) async {
    final uid = _uid;
    final r = b.requests[requestId];
    if (r == null || !r.groupBuy) throw const CommunityFailure('post_not_found');
    if (r.buyerId == uid) throw const CommunityFailure('organiser_cannot_leave');
    if (!r.isOpen) throw const CommunityFailure('group_closed');
    b.groupMembers[requestId]?.remove(uid);
    b.notify();
    return _group(r);
  }

  @override
  Future<GroupBuy?> getGroupBuy(String requestId) async {
    final r = b.requests[requestId];
    return r == null || !r.groupBuy ? null : _group(r);
  }

  @override
  Future<List<GroupMember>> groupMembers(String requestId) async {
    final uid = _uid;
    final r = b.requests[requestId];
    final winner = r?.acceptedQuoteId == null ? null : b.quoteSellerIds[r!.acceptedQuoteId];
    if (r == null || (r.buyerId != uid && winner != uid)) throw const CommunityFailure('request_not_found');
    return [
      for (final e in (b.groupMembers[requestId] ?? const <String, num>{}).entries)
        GroupMember(
          userId: e.key,
          name: _displayName(b.profiles[e.key]?.name),
          qty: e.value,
          phone: winner == uid ? b.profiles[e.key]?.phone : null,
        ),
    ];
  }

  @override
  Future<void> setQuoteTiers(String quoteId, List<PriceTier> tiers) async {
    final uid = _uid;
    final q = b.quotes[quoteId];
    if (q == null || b.quoteSellerIds[quoteId] != uid) throw const CommunityFailure('quote_not_found');
    if (!(b.requests[q.requestId]?.groupBuy ?? false)) throw const CommunityFailure('not_a_group_buy');
    for (var i = 1; i < tiers.length; i++) {
      if (tiers[i].minQty <= tiers[i - 1].minQty || tiers[i].unitPrice >= tiers[i - 1].unitPrice) {
        throw const CommunityFailure('invalid_tiers');
      }
    }
    if (tiers.isEmpty) {
      b.quoteTiers.remove(quoteId);
    } else {
      b.quoteTiers[quoteId] = [...tiers];
    }
    b.notify();
  }

  @override
  Future<List<PriceTier>> quoteTiers(String quoteId) async => [...?b.quoteTiers[quoteId]];
}
