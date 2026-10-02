import 'package:freezed_annotation/freezed_annotation.dart';

part 'outreach_models.freezed.dart';
part 'outreach_models.g.dart';

/// CRM pipeline stages (Section 21.5), stored in `outreach_leads.stage`.
@JsonEnum(fieldRename: FieldRename.snake)
enum LeadStage {
  sourced,
  contacted,
  replied,
  onboarding,
  liveSeller,
  active,
  notInterested,
  doNotContact;

  String get wire => switch (this) {
        liveSeller => 'live_seller',
        notInterested => 'not_interested',
        doNotContact => 'do_not_contact',
        _ => name,
      };

  static LeadStage fromWire(String v) =>
      LeadStage.values.firstWhere((s) => s.wire == v, orElse: () => LeadStage.sourced);
}

@JsonEnum(fieldRename: FieldRename.snake)
enum SequenceStatus { none, active, completed, stopped }

@JsonEnum(fieldRename: FieldRename.snake)
enum EmailStatus { unverified, valid, invalid, disposable, roleBounced }

/// Compliant lead sources only (21.1). There is deliberately no value for
/// scraped directories or bought lists.
@JsonEnum(fieldRename: FieldRename.snake)
enum LeadSource {
  osm,
  places,
  registry,
  website,
  inbound,
  referral,
  manual,
  field;

  static LeadSource? tryParse(String v) {
    final t = v.trim().toLowerCase();
    for (final s in LeadSource.values) {
      if (s.name == t) return s;
    }
    return null;
  }
}

@JsonEnum(fieldRename: FieldRename.snake)
enum LawfulBasis {
  legitimateInterest,
  consent,
  publicRegistry,
  inboundRequest;

  String get wire => switch (this) {
        legitimateInterest => 'legitimate_interest',
        consent => 'consent',
        publicRegistry => 'public_registry',
        inboundRequest => 'inbound_request',
      };

  static LawfulBasis? tryParse(String v) {
    final t = v.trim().toLowerCase();
    for (final b in LawfulBasis.values) {
      if (b.wire == t || b.name.toLowerCase() == t) return b;
    }
    return null;
  }
}

/// A business lead in the CRM (`outreach_leads`). Businesses only: there is
/// no consumer lead type (21.7).
@freezed
abstract class OutreachLead with _$OutreachLead {
  const OutreachLead._();

  const factory OutreachLead({
    required String id,
    required String businessKey,
    required String businessName,
    @Default(<String>[]) List<String> categoriesSource,
    @Default(<int>[]) List<int> matchedCategoryIds,
    String? email,
    String? emailDomain,
    @Default(EmailStatus.unverified) EmailStatus emailStatus,
    String? addressSource,
    String? phone,
    String? website,
    String? websiteDomain,
    String? placeId,
    String? osmId,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? timezone,
    double? rating,
    int? ratingCount,
    required LeadSource source,
    String? sourceRef,
    required LawfulBasis lawfulBasis,
    String? chosenReason,
    @Default(LeadStage.sourced) LeadStage stage,
    String? ownerId,
    String? nextAction,
    DateTime? nextActionDue,
    String? notes,
    int? priority,
    String? campaignId,
    @Default(SequenceStatus.none) SequenceStatus sequenceStatus,
    @Default(0) int touchesSent,
    DateTime? contactedAt,
    DateTime? lastContactedAt,
    DateTime? remindAfter,
    DateTime? whatsappOptInAt,
    String? whatsappOptInChannel,
    String? whatsappOptInProof,
    DateTime? whatsappLastMarketingAt,
    String? signupToken,
    String? unsubscribeToken,
    String? sellerId,
    DateTime? createdAt,
  }) = _OutreachLead;

  factory OutreachLead.fromJson(Map<String, dynamic> json) => _$OutreachLeadFromJson(json);

  String? get recipientDomain =>
      emailDomain ?? (email != null && email!.contains('@') ? email!.split('@').last.toLowerCase() : null);
}

@freezed
abstract class OutreachEvent with _$OutreachEvent {
  const factory OutreachEvent({
    required String id,
    required String leadId,
    String? campaignId,
    String? inboxId,
    required String channel,
    required String eventType,
    int? sequenceStep,
    int? templateVariant,
    String? subject,
    String? bodyPreview,
    String? recipient,
    String? reasonChosen,
    String? addressSource,
    String? lawfulBasis,
    @Default(<String, dynamic>{}) Map<String, dynamic> meta,
    String? createdBy,
    required DateTime createdAt,
  }) = _OutreachEvent;

  factory OutreachEvent.fromJson(Map<String, dynamic> json) => _$OutreachEventFromJson(json);
}

/// Reasons accepted by `suppression_list.reason`.
const suppressionReasons = [
  'unsubscribe',
  'hard_bounce',
  'complaint',
  'negative_reply',
  'manual',
  'do_not_contact',
  'deletion_request',
];

@freezed
abstract class SuppressionEntry with _$SuppressionEntry {
  const factory SuppressionEntry({
    required String id,
    String? email,
    String? emailDomain,
    String? phone,
    String? businessKey,
    required String reason,
    String? source,
    String? note,
    DateTime? createdAt,
  }) = _SuppressionEntry;

  factory SuppressionEntry.fromJson(Map<String, dynamic> json) => _$SuppressionEntryFromJson(json);
}

@freezed
abstract class TemplateVariant with _$TemplateVariant {
  const factory TemplateVariant({
    @Default('') String subject,
    required String body,
  }) = _TemplateVariant;

  factory TemplateVariant.fromJson(Map<String, dynamic> json) => _$TemplateVariantFromJson(json);
}

@freezed
abstract class SequenceStep with _$SequenceStep {
  const factory SequenceStep({
    required int step,
    @Default(0) int delayDays,
    @Default(false) bool includeBrochure,
    @Default(<TemplateVariant>[]) List<TemplateVariant> variants,
  }) = _SequenceStep;

  factory SequenceStep.fromJson(Map<String, dynamic> json) => _$SequenceStepFromJson(json);
}

@freezed
abstract class OutreachSequence with _$OutreachSequence {
  const factory OutreachSequence({
    required String id,
    required String name,
    @Default('email') String channel,
    @Default('en') String language,
    @Default(<SequenceStep>[]) List<SequenceStep> steps,
  }) = _OutreachSequence;

  factory OutreachSequence.fromJson(Map<String, dynamic> json) => _$OutreachSequenceFromJson(json);
}

@freezed
abstract class OutreachCampaign with _$OutreachCampaign {
  const factory OutreachCampaign({
    required String id,
    required String name,
    required String sequenceId,
    @Default('draft') String status,
    @Default(<int>[]) List<int> categoryIds,
    @Default(<String>[]) List<String> states,
    @Default(<String>[]) List<String> inboxIds,
    @Default(50) int dailyCap,
    String? pausedReason,
    DateTime? pausedAt,
  }) = _OutreachCampaign;

  factory OutreachCampaign.fromJson(Map<String, dynamic> json) => _$OutreachCampaignFromJson(json);
}

@freezed
abstract class OutreachInbox with _$OutreachInbox {
  const OutreachInbox._();

  const factory OutreachInbox({
    required String id,
    required String email,
    required String displayName,
    required String provider,
    @Default(20) int dailyCapStart,
    @Default(150) int dailyCapMax,
    @Default(10) int rampPerWeek,
    required DateTime warmupStartedOn,
    @Default(true) bool active,
  }) = _OutreachInbox;

  factory OutreachInbox.fromJson(Map<String, dynamic> json) => _$OutreachInboxFromJson(json);

  /// Warm-up cap, same formula as `private.outreach_inbox_daily_cap`.
  int dailyCapOn(DateTime at) {
    final days = DateTime.utc(at.year, at.month, at.day)
        .difference(DateTime.utc(warmupStartedOn.year, warmupStartedOn.month, warmupStartedOn.day))
        .inDays;
    final weeks = days < 0 ? 0 : days ~/ 7;
    final cap = dailyCapStart + rampPerWeek * weeks;
    return cap > dailyCapMax ? dailyCapMax : cap;
  }
}

/// Last-30-day health of one campaign (automatic brakes, rule 7).
class CampaignHealth {
  const CampaignHealth({this.sent = 0, this.bounced = 0, this.complained = 0, this.negative = 0});
  final int sent;
  final int bounced;
  final int complained;
  final int negative;

  double pct(int n) => sent == 0 ? 0 : 100.0 * n / sent;
  double get bouncePct => pct(bounced);
  double get complaintPct => pct(complained);
  double get negativePct => pct(negative);
}

/// Volume and brake inputs for the pre-send checks. Thresholds come from
/// `app_settings` (outreach_*), never from code.
class SendStats {
  const SendStats({
    required this.outreachEnabled,
    required this.globalDailyCap,
    required this.perDomainDailyCap,
    this.sentTodayGlobal = 0,
    this.sentTodayByDomain = const {},
    this.sentTodayByCampaign = const {},
    this.sentTodayByInbox = const {},
    this.bounceBrakePct = 2,
    this.complaintBrakePct = 0.08,
    this.negativeBrakePct = 5,
    this.campaignHealth = const {},
    this.businessAddress = '',
  });

  final bool outreachEnabled;
  final int globalDailyCap;
  final int perDomainDailyCap;
  final int sentTodayGlobal;
  final Map<String, int> sentTodayByDomain;
  final Map<String, int> sentTodayByCampaign;
  final Map<String, int> sentTodayByInbox;
  final double bounceBrakePct;
  final double complaintBrakePct;
  final double negativeBrakePct;
  final Map<String, CampaignHealth> campaignHealth;

  /// `outreach_business_address` setting: the physical postal address.
  final String businessAddress;
}

/// Filters for the kanban board.
@freezed
abstract class LeadFilter with _$LeadFilter {
  const factory LeadFilter({
    String? state,
    String? city,
    int? categoryId,
    LeadSource? source,
    String? query,
  }) = _LeadFilter;
}

/// A row parsed from an imported CSV, before it becomes a lead.
@freezed
abstract class LeadDraft with _$LeadDraft {
  const LeadDraft._();

  const factory LeadDraft({
    required String businessKey,
    required String businessName,
    @Default(<String>[]) List<String> categoriesSource,
    @Default(<int>[]) List<int> matchedCategoryIds,
    String? email,
    String? addressSource,
    String? phone,
    String? website,
    String? websiteDomain,
    String? placeId,
    String? osmId,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? timezone,
    double? rating,
    int? ratingCount,
    required LeadSource source,
    String? sourceRef,
    required LawfulBasis lawfulBasis,
    String? chosenReason,
    int? priority,
  }) = _LeadDraft;

  /// Payload for `outreach_upsert_lead(p_lead jsonb)`.
  Map<String, dynamic> toRpcJson() => {
        'business_key': businessKey,
        'business_name': businessName,
        'categories_source': categoriesSource,
        'matched_category_ids': matchedCategoryIds,
        'email': email,
        'address_source': addressSource,
        'phone': phone,
        'website': website,
        'website_domain': websiteDomain,
        'place_id': placeId,
        'osm_id': osmId,
        'address': address,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'timezone': timezone,
        'rating': rating,
        'rating_count': ratingCount,
        'source': source.name,
        'source_ref': sourceRef,
        'lawful_basis': lawfulBasis.wire,
        'chosen_reason': chosenReason,
        'priority': priority,
      }..removeWhere((_, v) => v == null);
}

class ImportResult {
  const ImportResult({required this.inserted, required this.duplicates, required this.rejected});
  final int inserted;
  final int duplicates;
  final List<String> rejected;
}

/// A coverage cell: sellers per city x category (21.5 liquidity view).
class CoverageCell {
  const CoverageCell({
    required this.city,
    required this.state,
    required this.categoryId,
    required this.sellers,
    required this.needsSellers,
  });
  final String city;
  final String? state;
  final int categoryId;
  final int sellers;
  final bool needsSellers;
}
