import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/core/config/admin_country.dart';
import 'package:iwant_admin/features/outreach/domain/anti_spam.dart';
import 'package:iwant_admin/features/outreach/domain/composer.dart';
import 'package:iwant_admin/features/outreach/domain/outreach_models.dart';

import 'helpers.dart';

void main() {
  group('AntiSpam (Section 21.8)', () {
    test('a compliant first email passes every rule', () {
      final r = AntiSpam.check(goodLead(), goodMessage(), ctx());
      expect(r.blocking, isEmpty, reason: r.violations.toString());
      expect(r.allowed, isTrue);
    });

    test('never automatic: unconfirmed sends are blocked (rule 0)', () {
      final r = AntiSpam.check(goodLead(), goodMessage().copyWith(confirmedByAdmin: false), ctx());
      expect(r.has('not_confirmed'), isTrue);
      expect(r.allowed, isFalse);
    });

    test('rule 1: a business with no matching category is not contacted', () {
      final r = AntiSpam.check(goodLead().copyWith(matchedCategoryIds: []), goodMessage(), ctx());
      expect(r.has('not_relevant'), isTrue);
      final r2 = AntiSpam.check(goodLead(), goodMessage().copyWith(categoryId: 99), ctx());
      expect(r2.has('category_not_sold_by_business'), isTrue);
    });

    test('rule 2: at most 3 touches, never restart a finished conversation', () {
      final lead = goodLead().copyWith(touchesSent: 3, sequenceStatus: SequenceStatus.completed, stage: LeadStage.contacted);
      final r = AntiSpam.check(lead, goodMessage(step: 4), ctx());
      expect(r.has('max_touches'), isTrue);
      expect(r.has('conversation_finished'), isTrue);
      final replied = AntiSpam.check(goodLead().copyWith(stage: LeadStage.replied), goodMessage(), ctx());
      expect(replied.has('stage_replied'), isTrue);
    });

    test('rule 2: follow-ups respect the sequence delay', () {
      final lead = goodLead().copyWith(
        touchesSent: 1,
        stage: LeadStage.contacted,
        sequenceStatus: SequenceStatus.active,
        lastContactedAt: usBusinessHours.subtract(const Duration(days: 2)),
      );
      final body = 'Hi again Northside Cooling, here is a brochure on HVAC requests in Dallas: '
          'https://iwantusa.app/b/1 Is it worth a quick look?';
      expect(AntiSpam.check(lead, goodMessage(step: 2, body: body), ctx()).has('not_due'), isTrue);
      final later = lead.copyWith(lastContactedAt: usBusinessHours.subtract(const Duration(days: 5)));
      expect(AntiSpam.check(later, goodMessage(step: 2, body: body), ctx()).allowed, isTrue);
    });

    test('suppression always wins (rule 5)', () {
      final r = AntiSpam.check(goodLead(), goodMessage(), ctx(suppressed: true));
      expect(r.has('suppressed'), isTrue);
      expect(r.allowed, isFalse);
    });

    test('rule 3: unverified, disposable or unsourced addresses are blocked; free mail warns', () {
      expect(AntiSpam.check(goodLead().copyWith(emailStatus: EmailStatus.unverified), goodMessage(), ctx())
          .has('email_not_verified'), isTrue);
      expect(AntiSpam.check(goodLead().copyWith(email: 'x@mailinator.com'), goodMessage(), ctx())
          .has('disposable_domain'), isTrue);
      expect(AntiSpam.check(goodLead().copyWith(addressSource: null), goodMessage(), ctx())
          .has('unknown_address_source'), isTrue);
      final free = AntiSpam.check(goodLead().copyWith(email: 'northside@gmail.com'), goodMessage(), ctx());
      expect(free.has('free_mail_check_source'), isTrue);
      expect(free.warnings, isNotEmpty);
    });

    test('rule 4: length, links, caps, spam phrases, misleading subject, question', () {
      final long = List.filled(130, 'word').join(' ');
      final r = AntiSpam.check(goodLead(), goodMessage(body: 'Northside Cooling Dallas HVAC $long?'), ctx());
      expect(r.has('too_long'), isTrue);

      final links = AntiSpam.check(
          goodLead(),
          goodMessage(body: 'Northside Cooling, HVAC in Dallas? https://a.example https://b.example'),
          ctx());
      expect(links.has('too_many_links'), isTrue);

      final spammy = AntiSpam.check(
          goodLead(),
          goodMessage(
              subject: 'RE: FREE leads!!',
              body: 'Northside Cooling, ACT NOW: guaranteed leads for HVAC in Dallas. Click here.'),
          ctx());
      expect(spammy.has('misleading_subject'), isTrue);
      expect(spammy.has('spammy_subject'), isTrue);
      expect(spammy.has('all_caps'), isTrue);
      expect(spammy.has('spam_phrases'), isTrue);
      expect(spammy.has('no_question'), isTrue);

      final html = AntiSpam.check(
          goodLead(), goodMessage(body: 'Northside Cooling HVAC Dallas? <img src="t.gif">'), ctx());
      expect(html.has('not_plain_text'), isTrue);
    });

    test('rule 4: no brochure in the first email and no attachments', () {
      final r = AntiSpam.check(
          goodLead(),
          goodMessage(body: 'Northside Cooling, HVAC in Dallas: see our brochure? https://x.example')
              .copyWith(hasAttachment: true),
          ctx());
      expect(r.has('brochure_in_first_email'), isTrue);
      expect(r.has('attachment'), isTrue);
    });

    test('rule 4: personalised with name, city and category; placeholders filled', () {
      final r = AntiSpam.check(goodLead(), goodMessage(body: 'Hello {{business_name}}, want leads?'), ctx());
      expect(r.has('unfilled_placeholder'), isTrue);
      expect(r.has('not_personalised_name'), isTrue);
      expect(r.has('not_personalised_city'), isTrue);
      expect(r.has('not_personalised_category'), isTrue);
    });

    test('rule 5 and 8: footer must carry opt-out, company, address and privacy link', () {
      final r = AntiSpam.check(goodLead(), goodMessage().copyWith(footer: 'Sam'), ctx());
      expect(r.has('missing_opt_out'), isTrue);
      expect(r.has('missing_company'), isTrue);
      expect(r.has('missing_address'), isTrue);
      expect(r.has('missing_privacy_link'), isTrue);
    });

    test('rule 8: placeholder business address blocks sending', () {
      final s = SendStats(outreachEnabled: true, globalDailyCap: 50, perDomainDailyCap: 2, businessAddress: '{{US_BUSINESS_ADDRESS}}');
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(s: s)).has('business_address_not_configured'), isTrue);
    });

    test('rule 6: caps never lift automatically, weekdays in business hours only', () {
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(s: stats(sentToday: 50))).has('global_daily_cap'), isTrue);
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(s: stats(byDomain: {'northside.example': 2})))
          .has('domain_daily_cap'), isTrue);
      // Saturday
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(now: DateTime.utc(2026, 10, 10, 15)))
          .has('outside_business_hours'), isTrue);
      // Tuesday 07:00 in New York
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(now: DateTime.utc(2026, 10, 6, 11)))
          .has('outside_business_hours'), isTrue);
      final off = SendStats(outreachEnabled: false, globalDailyCap: 50, perDomainDailyCap: 2, businessAddress: address);
      expect(AntiSpam.check(goodLead(), goodMessage(), ctx(s: off)).has('outreach_disabled'), isTrue);
    });

    test('rule 6: inbox warm-up cap ramps slowly', () {
      expect(inbox.dailyCapOn(DateTime.utc(2026, 9, 1)), 20);
      expect(inbox.dailyCapOn(DateTime.utc(2026, 9, 15)), 40);
      expect(inbox.dailyCapOn(DateTime.utc(2030, 1, 1)), 150);
    });

    test('rule 7: paused campaign or brake thresholds block', () {
      final paused = AntiSpam.check(goodLead(), goodMessage(), ctx(camp: campaign.copyWith(status: 'paused')));
      expect(paused.has('campaign_paused'), isTrue);
      final bounces = AntiSpam.check(
          goodLead(), goodMessage(), ctx(s: stats(health: const CampaignHealth(sent: 100, bounced: 3))));
      expect(bounces.has('bounce_rate'), isTrue);
      final complaints = AntiSpam.check(
          goodLead(), goodMessage(), ctx(s: stats(health: const CampaignHealth(sent: 1000, complained: 1))));
      expect(complaints.has('complaint_rate'), isTrue);
    });

    test('rule 9: WhatsApp needs opt-in, an approved template and at most one per week', () {
      const wa = OutreachMessage(
        channel: 'whatsapp',
        step: 1,
        subject: '',
        body: 'Hello Northside Cooling, new HVAC requests in Dallas this week. Reply STOP to opt out.',
        footer: '',
        categoryId: 4,
        confirmedByAdmin: true,
      );
      final r = AntiSpam.check(goodLead(), wa, ctx(cfg: AdminCountryConfig.india, now: DateTime.utc(2026, 10, 6, 6)));
      expect(r.has('no_opt_in'), isTrue);
      expect(r.has('no_approved_template'), isTrue);
      final opted = goodLead().copyWith(
        timezone: 'Asia/Kolkata',
        whatsappOptInAt: DateTime.utc(2026, 9, 1),
        whatsappLastMarketingAt: DateTime.utc(2026, 10, 3),
      );
      final r2 = AntiSpam.check(opted, wa, ctx(cfg: AdminCountryConfig.india, now: DateTime.utc(2026, 10, 6, 6)));
      expect(r2.has('weekly_cap'), isTrue);
      // The USA app does not automate WhatsApp at all.
      expect(AntiSpam.check(opted, wa, ctx()).has('channel_not_automated'), isTrue);
    });

    test('rule 11: every send needs an audit reason', () {
      expect(AntiSpam.check(goodLead().copyWith(chosenReason: null), goodMessage(), ctx()).has('missing_reason_chosen'),
          isTrue);
    });
  });
}
