import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';
import '../../requests/domain/buyer_request.dart';

part 'community.freezed.dart';

/// One step of a group-buy price ladder: from [minQty] units, [unitPrice] each.
@freezed
abstract class PriceTier with _$PriceTier {
  const factory PriceTier({required num minQty, required Money unitPrice}) = _PriceTier;
}

/// The seller a group buy's organiser picked (members only).
@freezed
abstract class GroupWinner with _$GroupWinner {
  const factory GroupWinner({
    required String sellerId,
    required String businessName,
    @Default(false) bool verified,
    Money? unitPrice,
  }) = _GroupWinner;
}

/// Group-buy summary on a public request (`get_group_buy`).
@freezed
abstract class GroupBuy with _$GroupBuy {
  const factory GroupBuy({
    @Default('units') String unit,
    @Default(0) num totalQty,
    @Default(0) int members,

    /// The viewer's quantity when they joined (the organiser included).
    num? myQty,

    /// Best per-unit price at each step any seller offered; prices drop.
    @Default([]) List<PriceTier> ladder,

    /// Best price for the group's current quantity.
    Money? currentUnitPrice,
    num? nextMinQty,
    Money? nextUnitPrice,
    num? qtyToNext,
    @Default(0) int offers,
    GroupWinner? winner,
  }) = _GroupBuy;

  const GroupBuy._();

  bool get joined => myQty != null;

  /// 0..1 progress towards the next cheaper tier.
  double get progressToNext {
    final next = nextMinQty;
    if (next == null || next <= 0) return 1;
    return (totalQty / next).clamp(0, 1).toDouble();
  }
}

/// A request on the community feed, as anyone may see it (no buyer id,
/// contact details, exact location or hidden budget).
@freezed
abstract class FeedPost with _$FeedPost {
  const factory FeedPost({
    required String id,
    required int categoryId,
    required String title,
    @Default('') String description,
    Money? budgetMin,
    Money? budgetMax,
    DateTime? neededBy,
    String? locality,
    String? city,
    String? state,
    @Default(RequestStatus.open) RequestStatus status,
    @Default(0) int quoteCount,
    @Default(0) int commentCount,
    @Default(0) int likeCount,
    @Default(false) bool likedByMe,
    @Default(false) bool isMine,
    @Default('') String authorName,
    String? authorPhotoUrl,
    DateTime? quoteWindowEndsAt,
    required DateTime publishedAt,
    GroupBuy? group,
  }) = _FeedPost;

  const FeedPost._();

  bool get isOpen => status == RequestStatus.open;
  bool get isGroupBuy => group != null;
  String get place => [locality, city].whereType<String>().where((s) => s.isNotEmpty).toSet().join(', ');
}

@freezed
abstract class FeedComment with _$FeedComment {
  const factory FeedComment({
    required String id,
    required String requestId,
    String? parentId,
    required String body,
    required DateTime createdAt,
    @Default('') String authorName,
    String? authorPhotoUrl,

    /// Posted as a business: [sellerId] links the seller profile.
    @Default(false) bool asSeller,
    String? sellerId,
    @Default(false) bool sellerVerified,
    @Default(false) bool isMine,
    @Default(false) bool isPostAuthor,
  }) = _FeedComment;
}

/// Feed filter chips.
enum FeedFilter { all, groupBuys, open, mine }

/// Member of a group buy as the organiser (or, after acceptance, the winning
/// seller) sees them. [phone] is only filled for the winning seller.
@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String userId,
    required String name,
    required num qty,
    String? note,
    String? phone,
  }) = _GroupMember;
}

/// Formats a quantity without trailing zeros (25.000 -> 25, 2.500 -> 2.5).
String formatQty(num q) {
  if (q == q.roundToDouble()) return q.round().toString();
  return q.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
}
