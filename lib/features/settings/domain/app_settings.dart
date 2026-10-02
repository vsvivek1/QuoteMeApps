import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';

/// Flags from `app_settings` (backend) merged with Remote Config.
@freezed
abstract class AppFlags with _$AppFlags {
  const factory AppFlags({
    @Default(false) bool monetizationEnabled,
    @Default(10) int quoteCap,
    @Default(15) int priorityWindowMinutes,
    DateTime? earlyPartnerFreeUntil,
    @Default(10) int maxRequestsPerDay,
    @Default(false) bool webPurchaseLinksAllowed,

    /// `monthly` or `annual` (server default `annual`).
    @Default('annual') String paywallDefaultPeriod,
    @Default(false) bool whatsappNotifications,
    @Default('1.0') String termsVersion,
    @Default('1.0') String privacyVersion,
  }) = _AppFlags;
}

abstract interface class FlagsRepository {
  Future<AppFlags> load();
}
