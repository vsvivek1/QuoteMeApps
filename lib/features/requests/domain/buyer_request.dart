import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';

part 'buyer_request.freezed.dart';

enum RequestStatus { open, closed, awarded, expired, cancelled }

enum Audience { local, online, both }

enum QuoteWindow {
  h24(Duration(hours: 24)),
  h48(Duration(hours: 48)),
  d7(Duration(days: 7));

  const QuoteWindow(this.duration);
  final Duration duration;
}

@freezed
abstract class RequestMedia with _$RequestMedia {
  const factory RequestMedia({required String path, @Default('image') String type, String? url}) = _RequestMedia;
}

/// Row in `requests` as the buyer sees it.
@freezed
abstract class BuyerRequest with _$BuyerRequest {
  const factory BuyerRequest({
    required String id,
    required String buyerId,
    required int categoryId,
    required String title,
    @Default('') String description,
    @Default({}) Map<String, Object?> fields,
    Money? budgetMin,
    Money? budgetMax,
    @Default(true) bool budgetVisible,
    DateTime? neededBy,
    double? lat,
    double? lng,
    String? locationCode,
    String? locality,
    String? state,
    @Default(Audience.both) Audience audience,
    @Default(RequestStatus.open) RequestStatus status,
    @Default(0) int quoteCount,
    @Default(10) int maxQuotes,
    DateTime? quoteWindowEndsAt,
    DateTime? priorityUntil,
    String? acceptedQuoteId,
    String? referenceLink,
    @Default([]) List<RequestMedia> media,
    required DateTime createdAt,
    @Default(0) int notifiedSellers,
    @Default(0) int unreadQuotes,

    /// On the community feed (anyone can read it and comment).
    @Default(false) bool isPublic,
    @Default(false) bool groupBuy,
    @Default(0) int commentCount,
  }) = _BuyerRequest;

  const BuyerRequest._();

  bool get isOpen => status == RequestStatus.open;
  bool get isPast =>
      status == RequestStatus.expired || status == RequestStatus.cancelled || status == RequestStatus.closed;
}

/// What the post-request wizard produces.
@freezed
abstract class RequestDraft with _$RequestDraft {
  const factory RequestDraft({
    @Default('') String text,
    int? categoryId,
    @Default({}) Map<String, Object?> fields,
    @Default([]) List<String> localMediaPaths,
    String? referenceLink,
    Money? budgetMin,
    Money? budgetMax,
    @Default(true) bool budgetVisible,
    DateTime? neededBy,
    double? lat,
    double? lng,
    String? locationCode,
    String? locality,
    String? state,
    String? fullAddress,
    @Default(QuoteWindow.h48) QuoteWindow quoteWindow,
    @Default(Audience.both) Audience audience,
    String? invitedBySellerId,

    /// Publish to the community feed after posting.
    @Default(false) bool postToFeed,

    /// Group buy (implies [postToFeed]): others join with a quantity.
    @Default(false) bool groupBuy,
    String? groupUnit,
    @Default(1) num groupQty,
  }) = _RequestDraft;
}
