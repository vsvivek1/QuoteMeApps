import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/money/money.dart';

part 'seller.freezed.dart';

enum AreaType { radius, codes, nationwide }

enum VerificationStatus { none, pending, verified, rejected }

enum NotifyPreference { instant, hourly, quiet }

@freezed
abstract class Seller with _$Seller {
  const factory Seller({
    required String id,
    required String businessName,
    String? logoUrl,
    @Default([]) List<String> photos,
    @Default('') String description,
    int? yearsInBusiness,
    @Default([]) List<String> brands,
    @Default([]) List<int> categoryIds,
    @Default(AreaType.radius) AreaType areaType,
    double? lat,
    double? lng,
    @Default(10) int radiusKm,
    @Default([]) List<String> serviceCodes,
    String? state,
    String? locality,
    @Default(VerificationStatus.none) VerificationStatus verificationStatus,
    DateTime? verifiedAt,
    @Default(0) double ratingAvg,
    @Default(0) int ratingCount,
    @Default(0) int quotesSent,
    @Default(0) int quotesWon,
    int? avgResponseMins,
    @Default(NotifyPreference.instant) NotifyPreference notifyPreference,
    int? quietStartHour,
    int? quietEndHour,
    @Default(false) bool earlyPartner,
    DateTime? freeUntil,
    String? phone,

    /// `sellers.seo_directory_opt_in`: listed on the public website's seller
    /// directory (Section 21.9). Off by default.
    @Default(false) bool directoryOptIn,
  }) = _Seller;

  const Seller._();

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  double get winRate => quotesSent == 0 ? 0 : quotesWon / quotesSent;
}

@freezed
abstract class SellerDocument with _$SellerDocument {
  const factory SellerDocument({
    required String id,
    required String docType,
    String? docNumber,
    String? filePath,
    @Default(VerificationStatus.pending) VerificationStatus status,
    String? rejectionReason,
  }) = _SellerDocument;
}

@freezed
abstract class SellerLicence with _$SellerLicence {
  const factory SellerLicence({
    required String id,
    required String licenceType,
    required String number,
    String? issuer,
    String? state,
    @Default([]) List<int> categoryIds,
    DateTime? expiresAt,
    @Default(VerificationStatus.pending) VerificationStatus status,
  }) = _SellerLicence;
}

@freezed
abstract class QuoteTemplate with _$QuoteTemplate {
  const factory QuoteTemplate({required String id, required String name, required Map<String, Object?> payload}) =
      _QuoteTemplate;
}

@freezed
abstract class SellerStats with _$SellerStats {
  const factory SellerStats({
    @Default(0) int activeQuotes,
    @Default(0) int won,
    @Default(0) int lost,
    @Default(0) double winRate,
    int? avgResponseMins,
    Money? revenueLogged,
    @Default(0) double ratingAvg,
    @Default(0) int ratingCount,
    @Default(0) int quotesThisMonth,
  }) = _SellerStats;
}

/// Seller plan / entitlement (`entitlements`).
@freezed
abstract class Entitlement with _$Entitlement {
  const factory Entitlement({
    @Default('free') String tier,
    @Default('active') String status,
    String? store,
    String? productId,
    @Default(0) int creditsBalance,
    DateTime? renewsAt,
    @Default(false) bool inGracePeriod,
  }) = _Entitlement;

  const Entitlement._();

  bool get isPaid => tier != 'free' && status == 'active';
}
