import 'package:iwant_admin/core/config/admin_country.dart';
import 'package:iwant_admin/features/outreach/domain/anti_spam.dart';
import 'package:iwant_admin/features/outreach/domain/composer.dart';
import 'package:iwant_admin/features/outreach/domain/outreach_models.dart';

/// Tuesday 2026-10-06 11:00 in New York (EDT, UTC-4).
final usBusinessHours = DateTime.utc(2026, 10, 6, 15);

const config = AdminCountryConfig.usa;
const address = '1 Test Street, Testville';

final inbox = OutreachInbox(
  id: 'inbox-1',
  email: 'hello@try-brand.example',
  displayName: 'Sam (Partnerships, I Want USA)',
  provider: 'resend',
  warmupStartedOn: DateTime.utc(2026, 9, 1),
);

const sequence = OutreachSequence(id: 'seq', name: 'seq', steps: [
  SequenceStep(step: 1, variants: [TemplateVariant(subject: 's', body: 'b')]),
  SequenceStep(step: 2, delayDays: 4, variants: [TemplateVariant(subject: 's', body: 'b')]),
  SequenceStep(step: 3, delayDays: 7, variants: [TemplateVariant(subject: 's', body: 'b')]),
]);

const campaign = OutreachCampaign(id: 'camp', name: 'c', sequenceId: 'seq', status: 'active', categoryIds: [4]);

OutreachLead goodLead() => const OutreachLead(
      id: 'lead-1',
      businessKey: 'domain:northside.example',
      businessName: 'Northside Cooling',
      matchedCategoryIds: [4],
      email: 'info@northside.example',
      emailDomain: 'northside.example',
      emailStatus: EmailStatus.valid,
      addressSource: 'https://northside.example/contact',
      city: 'Dallas',
      state: 'Texas',
      timezone: 'America/New_York',
      rating: 4.6,
      source: LeadSource.osm,
      lawfulBasis: LawfulBasis.legitimateInterest,
      chosenReason: 'Tagged craft=hvac in Dallas (osm)',
      campaignId: 'camp',
      unsubscribeToken: 'tok',
    );

SendStats stats({int sentToday = 0, Map<String, int> byDomain = const {}, CampaignHealth? health}) => SendStats(
      outreachEnabled: true,
      globalDailyCap: 50,
      perDomainDailyCap: 2,
      sentTodayGlobal: sentToday,
      sentTodayByDomain: byDomain,
      campaignHealth: {'camp': ?health},
      businessAddress: address,
    );

OutreachMessage goodMessage({String? body, String? subject, int step = 1}) {
  const composer = OutreachComposer(config);
  return OutreachMessage(
    channel: 'email',
    step: step,
    subject: subject ?? 'HVAC requests in Dallas',
    body: body ??
        'Hi Northside Cooling team,\n\nI saw your 4.6-star listing. People in Dallas post what they need on '
            'I Want USA and local HVAC businesses send them quotes.\n\nShall I set up your shop? '
            'https://iwantusa.app/sell?t=x\n\nSam',
    footer: composer.footer(senderName: inbox.displayName, businessAddress: address, unsubscribeToken: 'tok'),
    categoryId: 4,
    categoryName: 'HVAC',
    inboxId: inbox.id,
    campaignId: 'camp',
    confirmedByAdmin: true,
  );
}

SendContext ctx({SendStats? s, bool suppressed = false, OutreachCampaign? camp, DateTime? now, AdminCountryConfig? cfg}) =>
    SendContext(
      config: cfg ?? config,
      stats: s ?? stats(),
      now: now ?? usBusinessHours,
      isSuppressed: suppressed,
      campaign: camp ?? campaign,
      sequence: sequence,
      inbox: inbox,
    );
