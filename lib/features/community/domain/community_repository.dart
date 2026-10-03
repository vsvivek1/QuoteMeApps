import 'community.dart';

class CommunityFailure implements Exception {
  const CommunityFailure(this.code, [this.message]);

  /// post_not_found | comment_empty | comment_too_long | blocked_content |
  /// rate_limited | blocked | group_closed | invalid_qty | group_has_members |
  /// organiser_cannot_leave | invalid_tiers | not_authenticated | network
  final String code;
  final String? message;
  @override
  String toString() => 'CommunityFailure($code, $message)';
}

/// The public request feed: posts, likes, comments and group buys.
abstract interface class CommunityRepository {
  /// Newest first. Works signed out (read only).
  Stream<List<FeedPost>> watchFeed(FeedFilter filter, {int? categoryId});
  Stream<FeedPost?> watchPost(String requestId);
  Stream<List<FeedComment>> watchComments(String requestId);

  Future<FeedComment> addComment(String requestId, String body, {String? parentId, bool asSeller = false});
  Future<void> deleteComment(String commentId);

  /// Returns whether the viewer now likes the post.
  Future<bool> toggleLike(String requestId);

  /// Buyer's own request: show it on the feed or take it down.
  Future<void> publish(String requestId, {required bool public});

  /// Organiser: turn group buy on with their own quantity, or off.
  Future<void> setGroupBuy(String requestId, {required bool enabled, String? unit, num myQty = 1});
  Future<GroupBuy> joinGroupBuy(String requestId, num qty, {String? note});
  Future<GroupBuy> leaveGroupBuy(String requestId);

  /// Null when the request is not a group buy (or not visible).
  Future<GroupBuy?> getGroupBuy(String requestId);
  Future<List<GroupMember>> groupMembers(String requestId);

  /// Seller: per-unit price tiers on an own quote. Empty clears them.
  Future<void> setQuoteTiers(String quoteId, List<PriceTier> tiers);
  Future<List<PriceTier>> quoteTiers(String quoteId);
}
