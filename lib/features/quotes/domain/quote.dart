import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';
import '../../../core/money/tax.dart';

part 'quote.freezed.dart';

enum QuoteStatus { sent, revised, shortlisted, declined, accepted, withdrawn, expired }

enum QuoteSort { price, rating, deliveryDate, distance }

/// Seller summary shown on quote cards (joined from `sellers`).
@freezed
abstract class SellerSummary with _$SellerSummary {
  const factory SellerSummary({
    required String id,
    required String businessName,
    String? logoUrl,
    @Default(0) double ratingAvg,
    @Default(0) int ratingCount,
    @Default(false) bool verified,
    int? avgResponseMins,
    double? distanceKm,
    @Default(false) bool earlyPartner,
  }) = _SellerSummary;
}

@freezed
abstract class Quote with _$Quote {
  const factory Quote({
    required String id,
    required String requestId,
    required SellerSummary seller,
    @Default([]) List<QuoteLine> lines,
    required Money subtotal,
    required Money tax,
    @Default(NoTaxBreakdown()) TaxBreakdown taxBreakdown,
    required Money delivery,
    required Money total,
    String? offeredBrandModel,
    DateTime? deliveryDate,
    String? warranty,
    DateTime? validUntil,
    String? notes,
    @Default(QuoteStatus.sent) QuoteStatus status,
    Money? counterOfferTarget,
    String? counterOfferNote,
    String? declineReason,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default(false) bool viewedByBuyer,
  }) = _Quote;

  const Quote._();

  bool get isActive => status == QuoteStatus.sent || status == QuoteStatus.revised || status == QuoteStatus.shortlisted;

  /// Minutes between the request being posted and this quote, for display.
  int responseMinutes(DateTime requestCreatedAt) => createdAt.difference(requestCreatedAt).inMinutes;
}

/// The seller's quote form output.
@freezed
abstract class QuoteDraft with _$QuoteDraft {
  const factory QuoteDraft({
    required String requestId,
    required List<QuoteLine> lines,
    required Money delivery,

    /// India: GST rate in basis points (sent per line).
    @Default(0) int taxRateBp,

    /// USA: sales tax rate in parts per million (8.875% = 88750).
    @Default(0) int salesTaxRatePpm,
    String? offeredBrandModel,
    DateTime? deliveryDate,
    String? warranty,
    required int validDays,
    String? notes,
    @Default([]) List<String> attachmentPaths,
  }) = _QuoteDraft;
}

List<Quote> sortQuotes(List<Quote> quotes, QuoteSort sort) {
  final list = [...quotes];
  int byDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  switch (sort) {
    case QuoteSort.price:
      list.sort((a, b) => a.total.minorUnits.compareTo(b.total.minorUnits));
    case QuoteSort.rating:
      list.sort((a, b) => b.seller.ratingAvg.compareTo(a.seller.ratingAvg));
    case QuoteSort.deliveryDate:
      list.sort((a, b) => byDate(a.deliveryDate, b.deliveryDate));
    case QuoteSort.distance:
      list.sort((a, b) => (a.seller.distanceKm ?? double.infinity).compareTo(b.seller.distanceKm ?? double.infinity));
  }
  return list;
}
