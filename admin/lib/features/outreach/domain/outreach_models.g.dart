// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outreach_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OutreachLead _$OutreachLeadFromJson(Map<String, dynamic> json) =>
    _OutreachLead(
      id: json['id'] as String,
      businessKey: json['business_key'] as String,
      businessName: json['business_name'] as String,
      categoriesSource:
          (json['categories_source'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      matchedCategoryIds:
          (json['matched_category_ids'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      email: json['email'] as String?,
      emailDomain: json['email_domain'] as String?,
      emailStatus:
          $enumDecodeNullable(_$EmailStatusEnumMap, json['email_status']) ??
          EmailStatus.unverified,
      addressSource: json['address_source'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      websiteDomain: json['website_domain'] as String?,
      placeId: json['place_id'] as String?,
      osmId: json['osm_id'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postal_code'] as String?,
      timezone: json['timezone'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: (json['rating_count'] as num?)?.toInt(),
      source: $enumDecode(_$LeadSourceEnumMap, json['source']),
      sourceRef: json['source_ref'] as String?,
      lawfulBasis: $enumDecode(_$LawfulBasisEnumMap, json['lawful_basis']),
      chosenReason: json['chosen_reason'] as String?,
      stage:
          $enumDecodeNullable(_$LeadStageEnumMap, json['stage']) ??
          LeadStage.sourced,
      ownerId: json['owner_id'] as String?,
      nextAction: json['next_action'] as String?,
      nextActionDue: json['next_action_due'] == null
          ? null
          : DateTime.parse(json['next_action_due'] as String),
      notes: json['notes'] as String?,
      priority: (json['priority'] as num?)?.toInt(),
      campaignId: json['campaign_id'] as String?,
      sequenceStatus:
          $enumDecodeNullable(
            _$SequenceStatusEnumMap,
            json['sequence_status'],
          ) ??
          SequenceStatus.none,
      touchesSent: (json['touches_sent'] as num?)?.toInt() ?? 0,
      contactedAt: json['contacted_at'] == null
          ? null
          : DateTime.parse(json['contacted_at'] as String),
      lastContactedAt: json['last_contacted_at'] == null
          ? null
          : DateTime.parse(json['last_contacted_at'] as String),
      remindAfter: json['remind_after'] == null
          ? null
          : DateTime.parse(json['remind_after'] as String),
      whatsappOptInAt: json['whatsapp_opt_in_at'] == null
          ? null
          : DateTime.parse(json['whatsapp_opt_in_at'] as String),
      whatsappOptInChannel: json['whatsapp_opt_in_channel'] as String?,
      whatsappOptInProof: json['whatsapp_opt_in_proof'] as String?,
      whatsappLastMarketingAt: json['whatsapp_last_marketing_at'] == null
          ? null
          : DateTime.parse(json['whatsapp_last_marketing_at'] as String),
      signupToken: json['signup_token'] as String?,
      unsubscribeToken: json['unsubscribe_token'] as String?,
      sellerId: json['seller_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OutreachLeadToJson(_OutreachLead instance) =>
    <String, dynamic>{
      'id': instance.id,
      'business_key': instance.businessKey,
      'business_name': instance.businessName,
      'categories_source': instance.categoriesSource,
      'matched_category_ids': instance.matchedCategoryIds,
      'email': instance.email,
      'email_domain': instance.emailDomain,
      'email_status': _$EmailStatusEnumMap[instance.emailStatus]!,
      'address_source': instance.addressSource,
      'phone': instance.phone,
      'website': instance.website,
      'website_domain': instance.websiteDomain,
      'place_id': instance.placeId,
      'osm_id': instance.osmId,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'postal_code': instance.postalCode,
      'timezone': instance.timezone,
      'rating': instance.rating,
      'rating_count': instance.ratingCount,
      'source': _$LeadSourceEnumMap[instance.source]!,
      'source_ref': instance.sourceRef,
      'lawful_basis': _$LawfulBasisEnumMap[instance.lawfulBasis]!,
      'chosen_reason': instance.chosenReason,
      'stage': _$LeadStageEnumMap[instance.stage]!,
      'owner_id': instance.ownerId,
      'next_action': instance.nextAction,
      'next_action_due': instance.nextActionDue?.toIso8601String(),
      'notes': instance.notes,
      'priority': instance.priority,
      'campaign_id': instance.campaignId,
      'sequence_status': _$SequenceStatusEnumMap[instance.sequenceStatus]!,
      'touches_sent': instance.touchesSent,
      'contacted_at': instance.contactedAt?.toIso8601String(),
      'last_contacted_at': instance.lastContactedAt?.toIso8601String(),
      'remind_after': instance.remindAfter?.toIso8601String(),
      'whatsapp_opt_in_at': instance.whatsappOptInAt?.toIso8601String(),
      'whatsapp_opt_in_channel': instance.whatsappOptInChannel,
      'whatsapp_opt_in_proof': instance.whatsappOptInProof,
      'whatsapp_last_marketing_at': instance.whatsappLastMarketingAt
          ?.toIso8601String(),
      'signup_token': instance.signupToken,
      'unsubscribe_token': instance.unsubscribeToken,
      'seller_id': instance.sellerId,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$EmailStatusEnumMap = {
  EmailStatus.unverified: 'unverified',
  EmailStatus.valid: 'valid',
  EmailStatus.invalid: 'invalid',
  EmailStatus.disposable: 'disposable',
  EmailStatus.roleBounced: 'role_bounced',
};

const _$LeadSourceEnumMap = {
  LeadSource.osm: 'osm',
  LeadSource.places: 'places',
  LeadSource.registry: 'registry',
  LeadSource.website: 'website',
  LeadSource.inbound: 'inbound',
  LeadSource.referral: 'referral',
  LeadSource.manual: 'manual',
  LeadSource.field: 'field',
};

const _$LawfulBasisEnumMap = {
  LawfulBasis.legitimateInterest: 'legitimate_interest',
  LawfulBasis.consent: 'consent',
  LawfulBasis.publicRegistry: 'public_registry',
  LawfulBasis.inboundRequest: 'inbound_request',
};

const _$LeadStageEnumMap = {
  LeadStage.sourced: 'sourced',
  LeadStage.contacted: 'contacted',
  LeadStage.replied: 'replied',
  LeadStage.onboarding: 'onboarding',
  LeadStage.liveSeller: 'live_seller',
  LeadStage.active: 'active',
  LeadStage.notInterested: 'not_interested',
  LeadStage.doNotContact: 'do_not_contact',
};

const _$SequenceStatusEnumMap = {
  SequenceStatus.none: 'none',
  SequenceStatus.active: 'active',
  SequenceStatus.completed: 'completed',
  SequenceStatus.stopped: 'stopped',
};

_OutreachEvent _$OutreachEventFromJson(Map<String, dynamic> json) =>
    _OutreachEvent(
      id: json['id'] as String,
      leadId: json['lead_id'] as String,
      campaignId: json['campaign_id'] as String?,
      inboxId: json['inbox_id'] as String?,
      channel: json['channel'] as String,
      eventType: json['event_type'] as String,
      sequenceStep: (json['sequence_step'] as num?)?.toInt(),
      templateVariant: (json['template_variant'] as num?)?.toInt(),
      subject: json['subject'] as String?,
      bodyPreview: json['body_preview'] as String?,
      recipient: json['recipient'] as String?,
      reasonChosen: json['reason_chosen'] as String?,
      addressSource: json['address_source'] as String?,
      lawfulBasis: json['lawful_basis'] as String?,
      meta: json['meta'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$OutreachEventToJson(_OutreachEvent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lead_id': instance.leadId,
      'campaign_id': instance.campaignId,
      'inbox_id': instance.inboxId,
      'channel': instance.channel,
      'event_type': instance.eventType,
      'sequence_step': instance.sequenceStep,
      'template_variant': instance.templateVariant,
      'subject': instance.subject,
      'body_preview': instance.bodyPreview,
      'recipient': instance.recipient,
      'reason_chosen': instance.reasonChosen,
      'address_source': instance.addressSource,
      'lawful_basis': instance.lawfulBasis,
      'meta': instance.meta,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
    };

_SuppressionEntry _$SuppressionEntryFromJson(Map<String, dynamic> json) =>
    _SuppressionEntry(
      id: json['id'] as String,
      email: json['email'] as String?,
      emailDomain: json['email_domain'] as String?,
      phone: json['phone'] as String?,
      businessKey: json['business_key'] as String?,
      reason: json['reason'] as String,
      source: json['source'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SuppressionEntryToJson(_SuppressionEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'email_domain': instance.emailDomain,
      'phone': instance.phone,
      'business_key': instance.businessKey,
      'reason': instance.reason,
      'source': instance.source,
      'note': instance.note,
      'created_at': instance.createdAt?.toIso8601String(),
    };

_TemplateVariant _$TemplateVariantFromJson(Map<String, dynamic> json) =>
    _TemplateVariant(
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String,
    );

Map<String, dynamic> _$TemplateVariantToJson(_TemplateVariant instance) =>
    <String, dynamic>{'subject': instance.subject, 'body': instance.body};

_SequenceStep _$SequenceStepFromJson(Map<String, dynamic> json) =>
    _SequenceStep(
      step: (json['step'] as num).toInt(),
      delayDays: (json['delay_days'] as num?)?.toInt() ?? 0,
      includeBrochure: json['include_brochure'] as bool? ?? false,
      variants:
          (json['variants'] as List<dynamic>?)
              ?.map((e) => TemplateVariant.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TemplateVariant>[],
    );

Map<String, dynamic> _$SequenceStepToJson(_SequenceStep instance) =>
    <String, dynamic>{
      'step': instance.step,
      'delay_days': instance.delayDays,
      'include_brochure': instance.includeBrochure,
      'variants': instance.variants.map((e) => e.toJson()).toList(),
    };

_OutreachSequence _$OutreachSequenceFromJson(Map<String, dynamic> json) =>
    _OutreachSequence(
      id: json['id'] as String,
      name: json['name'] as String,
      channel: json['channel'] as String? ?? 'email',
      language: json['language'] as String? ?? 'en',
      steps:
          (json['steps'] as List<dynamic>?)
              ?.map((e) => SequenceStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <SequenceStep>[],
    );

Map<String, dynamic> _$OutreachSequenceToJson(_OutreachSequence instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'channel': instance.channel,
      'language': instance.language,
      'steps': instance.steps.map((e) => e.toJson()).toList(),
    };

_OutreachCampaign _$OutreachCampaignFromJson(
  Map<String, dynamic> json,
) => _OutreachCampaign(
  id: json['id'] as String,
  name: json['name'] as String,
  sequenceId: json['sequence_id'] as String,
  status: json['status'] as String? ?? 'draft',
  categoryIds:
      (json['category_ids'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  states:
      (json['states'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  inboxIds:
      (json['inbox_ids'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  dailyCap: (json['daily_cap'] as num?)?.toInt() ?? 50,
  pausedReason: json['paused_reason'] as String?,
  pausedAt: json['paused_at'] == null
      ? null
      : DateTime.parse(json['paused_at'] as String),
);

Map<String, dynamic> _$OutreachCampaignToJson(_OutreachCampaign instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'sequence_id': instance.sequenceId,
      'status': instance.status,
      'category_ids': instance.categoryIds,
      'states': instance.states,
      'inbox_ids': instance.inboxIds,
      'daily_cap': instance.dailyCap,
      'paused_reason': instance.pausedReason,
      'paused_at': instance.pausedAt?.toIso8601String(),
    };

_OutreachInbox _$OutreachInboxFromJson(Map<String, dynamic> json) =>
    _OutreachInbox(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['display_name'] as String,
      provider: json['provider'] as String,
      dailyCapStart: (json['daily_cap_start'] as num?)?.toInt() ?? 20,
      dailyCapMax: (json['daily_cap_max'] as num?)?.toInt() ?? 150,
      rampPerWeek: (json['ramp_per_week'] as num?)?.toInt() ?? 10,
      warmupStartedOn: DateTime.parse(json['warmup_started_on'] as String),
      active: json['active'] as bool? ?? true,
    );

Map<String, dynamic> _$OutreachInboxToJson(_OutreachInbox instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'display_name': instance.displayName,
      'provider': instance.provider,
      'daily_cap_start': instance.dailyCapStart,
      'daily_cap_max': instance.dailyCapMax,
      'ramp_per_week': instance.rampPerWeek,
      'warmup_started_on': instance.warmupStartedOn.toIso8601String(),
      'active': instance.active,
    };
