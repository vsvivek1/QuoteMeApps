import '../../../core/config/admin_country.dart';
import '../../../core/utils/local_time.dart';
import 'composer.dart';
import 'outreach_models.dart';

enum Severity { block, warn }

/// One failed check, tied to its rule in the Section 21.8 rulebook (1..11).
/// Rule 0 is the panel's own "never automatic" rule.
class RuleViolation {
  const RuleViolation(this.rule, this.code, {this.severity = Severity.block, this.detail});
  final int rule;
  final String code;
  final Severity severity;
  final String? detail;

  @override
  String toString() => 'R$rule:$code${detail == null ? '' : '($detail)'}';
}

class AntiSpamReport {
  const AntiSpamReport(this.violations);
  final List<RuleViolation> violations;

  List<RuleViolation> get blocking => violations.where((v) => v.severity == Severity.block).toList();
  List<RuleViolation> get warnings => violations.where((v) => v.severity == Severity.warn).toList();
  bool get allowed => blocking.isEmpty;
  bool has(String code) => violations.any((v) => v.code == code);

  /// Pass/fail per rule for the checklist UI.
  bool rulePassed(int rule) => !blocking.any((v) => v.rule == rule);
}

/// Everything the checks need besides the lead and the message.
class SendContext {
  const SendContext({
    required this.config,
    required this.stats,
    required this.now,
    required this.isSuppressed,
    this.campaign,
    this.sequence,
    this.inbox,
  });

  final AdminCountryConfig config;
  final SendStats stats;
  final DateTime now;

  /// Matches `outreach_is_suppressed(email, phone, business_key)`.
  final bool isSuppressed;
  final OutreachCampaign? campaign;
  final OutreachSequence? sequence;
  final OutreachInbox? inbox;
}

/// The Section 21.8 anti-spam rulebook, enforced in code before any send.
///
/// This runs in the admin panel before the "Send" button is enabled; the
/// `outreach-send` Edge Function and the database (`outreach_can_send`, the
/// `outreach_events` triggers) enforce the same rules again server side, so a
/// modified client still cannot spam.
abstract final class AntiSpam {
  static const maxTouches = 3;
  static const maxWords = 120;
  static const maxSubjectLength = 80;

  static const compliantSources = LeadSource.values;

  static const disposableDomains = {
    'mailinator.com', 'guerrillamail.com', '10minutemail.com', 'tempmail.com',
    'temp-mail.org', 'yopmail.com', 'trashmail.com', 'getnada.com',
    'sharklasers.com', 'dispostable.com', 'maildrop.cc', 'throwawaymail.com',
  };

  /// Free webmail: allowed only when the business published it itself, so
  /// it is a warning that asks the admin to double-check the source.
  static const freeMailDomains = {
    'gmail.com', 'yahoo.com', 'yahoo.co.in', 'hotmail.com', 'outlook.com',
    'live.com', 'aol.com', 'icloud.com', 'rediffmail.com', 'proton.me', 'protonmail.com',
  };

  static const spamPhrases = [
    'act now', 'click here', 'buy now', 'order now', 'limited time', 'urgent',
    'winner', 'congratulations', 'you have been selected', '100%', 'guarantee',
    'no cost', 'cash bonus', 'earn money', 'make money', 'double your',
    'dear friend', 'once in a lifetime', 'special promotion', 'this is not spam',
    "this isn't spam", 'free for life', 'lifetime free', 'thousands of buyers',
    'millions of customers', 'guaranteed leads', 'risk free money', '!!!', r'$$$',
  ];

  /// Upper-case tokens that are fine (acronyms, the opt-out keyword).
  static const capsAllowList = {'STOP', 'GSTIN', 'GST', 'HVAC', 'UDYAM', 'FSSAI', 'USDOT', 'FMCSA', 'NIPR', 'RERA', 'LLC', 'OPC', 'USA', 'PIN', 'ZIP'};

  static final _emailRe = RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$");
  static final _linkRe = RegExp(r'(https?://|www\.)\S+', caseSensitive: false);
  static final _htmlRe = RegExp(r'<\s*/?\s*[a-z][^>]*>', caseSensitive: false);

  static bool isValidEmailSyntax(String email) => _emailRe.hasMatch(email.trim());

  static int wordCount(String text) => text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  static int linkCount(String text) => _linkRe.allMatches(text).length;

  static List<String> shoutingWords(String text) => RegExp(r'\b[A-Z]{4,}\b')
      .allMatches(text)
      .map((m) => m.group(0)!)
      .where((w) => !capsAllowList.contains(w))
      .toList();

  static List<String> spamPhrasesIn(String text) {
    final t = text.toLowerCase();
    return spamPhrases.where(t.contains).toList();
  }

  /// Runs every rule; returns all violations (not just the first).
  static AntiSpamReport check(OutreachLead lead, OutreachMessage msg, SendContext ctx) {
    final v = <RuleViolation>[];
    final isEmail = msg.channel == 'email';
    final isWhatsApp = msg.channel == 'whatsapp' || msg.channel == 'sms';

    // Rule 0: a person confirms every send. Nothing is sent automatically.
    if (!msg.confirmedByAdmin) v.add(const RuleViolation(0, 'not_confirmed'));
    if (!ctx.config.outreachChannels.contains(msg.channel)) {
      v.add(RuleViolation(0, 'channel_not_automated', detail: msg.channel));
    }

    // Rule 1: relevance only.
    if (lead.matchedCategoryIds.isEmpty) {
      v.add(const RuleViolation(1, 'not_relevant'));
    } else if (msg.categoryId != null && !lead.matchedCategoryIds.contains(msg.categoryId)) {
      v.add(const RuleViolation(1, 'category_not_sold_by_business'));
    }
    final campaign = ctx.campaign;
    if (campaign != null &&
        campaign.categoryIds.isNotEmpty &&
        !lead.matchedCategoryIds.any(campaign.categoryIds.contains)) {
      v.add(const RuleViolation(1, 'outside_campaign_categories'));
    }

    // Rule 2: one conversation per business, ever; at most 3 touches.
    if (lead.touchesSent >= maxTouches) v.add(const RuleViolation(2, 'max_touches'));
    if (lead.sequenceStatus == SequenceStatus.completed || lead.sequenceStatus == SequenceStatus.stopped) {
      v.add(const RuleViolation(2, 'conversation_finished'));
    }
    if (lead.stage != LeadStage.sourced && lead.stage != LeadStage.contacted) {
      v.add(RuleViolation(2, 'stage_${lead.stage.wire}'));
    }
    if (lead.sellerId != null) v.add(const RuleViolation(2, 'already_seller'));
    if (msg.step != lead.touchesSent + 1) {
      v.add(RuleViolation(2, 'wrong_step', detail: 'expected ${lead.touchesSent + 1}'));
    }
    final seq = ctx.sequence;
    if (seq != null) {
      if (seq.steps.length > maxTouches) v.add(const RuleViolation(2, 'sequence_too_long'));
      if (msg.step > seq.steps.length) v.add(const RuleViolation(2, 'sequence_done'));
      // Spacing between touches (about 3 touches over 2 weeks).
      if (lead.lastContactedAt != null && msg.step >= 2 && msg.step <= seq.steps.length) {
        final delay = seq.steps[msg.step - 1].delayDays;
        final due = lead.lastContactedAt!.add(Duration(days: delay < 1 ? 1 : delay));
        if (due.isAfter(ctx.now)) v.add(const RuleViolation(2, 'not_due'));
      }
    }
    if (lead.remindAfter != null && lead.remindAfter!.isAfter(ctx.now)) {
      v.add(const RuleViolation(5, 'remind_later'));
    }

    // Suppression always wins (rules 2, 3, 5).
    if (ctx.isSuppressed || lead.stage == LeadStage.doNotContact) {
      v.add(const RuleViolation(5, 'suppressed'));
    }

    // Rule 3: verified, business-published addresses only.
    if (isEmail) {
      final email = lead.email?.trim();
      if (email == null || email.isEmpty) {
        v.add(const RuleViolation(3, 'no_email'));
      } else {
        if (!isValidEmailSyntax(email)) v.add(const RuleViolation(3, 'invalid_syntax'));
        final domain = email.split('@').last.toLowerCase();
        if (disposableDomains.contains(domain)) v.add(const RuleViolation(3, 'disposable_domain'));
        if (freeMailDomains.contains(domain)) {
          v.add(const RuleViolation(3, 'free_mail_check_source', severity: Severity.warn));
        }
      }
      switch (lead.emailStatus) {
        case EmailStatus.valid:
          break;
        case EmailStatus.unverified:
          v.add(const RuleViolation(3, 'email_not_verified'));
        case EmailStatus.invalid:
          v.add(const RuleViolation(3, 'hard_bounced'));
        case EmailStatus.disposable:
          v.add(const RuleViolation(3, 'disposable_domain'));
        case EmailStatus.roleBounced:
          v.add(const RuleViolation(3, 'role_address_bounced'));
      }
      if (lead.addressSource == null || lead.addressSource!.trim().isEmpty) {
        v.add(const RuleViolation(3, 'unknown_address_source'));
      }
    }

    // Rule 4: short, plain, honest, personal.
    if (isEmail) {
      final body = msg.body;
      final subject = msg.subject.trim();
      final words = wordCount(body);
      if (words > maxWords) v.add(RuleViolation(4, 'too_long', detail: '$words words'));
      if (linkCount(body) > 1) v.add(RuleViolation(4, 'too_many_links', detail: '${linkCount(body)}'));
      if (msg.hasAttachment) v.add(const RuleViolation(4, 'attachment'));
      if (msg.step == 1 && body.toLowerCase().contains('brochure')) {
        v.add(const RuleViolation(4, 'brochure_in_first_email'));
      }
      if (_htmlRe.hasMatch(body) || body.toLowerCase().contains('pixel')) {
        v.add(const RuleViolation(4, 'not_plain_text'));
      }
      if (!body.contains('?')) v.add(const RuleViolation(4, 'no_question'));
      if (subject.isEmpty) v.add(const RuleViolation(4, 'empty_subject'));
      if (subject.length > maxSubjectLength) v.add(const RuleViolation(4, 'subject_too_long'));
      if (RegExp(r'^\s*(re|fw|fwd)\s*:', caseSensitive: false).hasMatch(subject)) {
        v.add(const RuleViolation(4, 'misleading_subject'));
      }
      if (subject.contains('!!') || subject.contains(r'$')) v.add(const RuleViolation(4, 'spammy_subject'));
      final nameTokens = lead.businessName.split(RegExp(r'\s+')).toSet();
      final shouting = [...shoutingWords(subject), ...shoutingWords(body)]
          .where((w) => !nameTokens.contains(w))
          .toList();
      if (shouting.isNotEmpty) v.add(RuleViolation(4, 'all_caps', detail: shouting.join(', ')));
      final phrases = spamPhrasesIn('$subject\n$body');
      if (phrases.isNotEmpty) v.add(RuleViolation(4, 'spam_phrases', detail: phrases.join(', ')));
      if (RegExp(r'\{\{\s*[a-z_]+\s*\}\}').hasMatch('$subject\n$body')) {
        v.add(const RuleViolation(4, 'unfilled_placeholder'));
      }
      final lower = body.toLowerCase();
      if (!lower.contains(lead.businessName.toLowerCase())) {
        v.add(const RuleViolation(4, 'not_personalised_name'));
      }
      if (lead.city != null && lead.city!.isNotEmpty && !lower.contains(lead.city!.toLowerCase())) {
        v.add(const RuleViolation(4, 'not_personalised_city'));
      }
      if (msg.categoryName != null && !lower.contains(msg.categoryName!.toLowerCase())) {
        v.add(const RuleViolation(4, 'not_personalised_category'));
      }
    }

    // Rule 5: easy, respected opt-out.
    final footer = msg.footer.toLowerCase();
    if (isEmail && !(footer.contains('no thanks') && footer.contains('unsubscribe'))) {
      v.add(const RuleViolation(5, 'missing_opt_out'));
    }
    if (isWhatsApp && !('${msg.body}\n${msg.footer}'.contains('STOP'))) {
      v.add(const RuleViolation(5, 'missing_stop'));
    }

    // Rule 6: volume caps that never lift automatically.
    final s = ctx.stats;
    if (!s.outreachEnabled) v.add(const RuleViolation(6, 'outreach_disabled'));
    if (s.sentTodayGlobal >= s.globalDailyCap) v.add(const RuleViolation(6, 'global_daily_cap'));
    if (campaign != null && (s.sentTodayByCampaign[campaign.id] ?? 0) >= campaign.dailyCap) {
      v.add(const RuleViolation(6, 'campaign_daily_cap'));
    }
    if (isEmail) {
      final domain = lead.recipientDomain;
      if (domain != null && (s.sentTodayByDomain[domain] ?? 0) >= s.perDomainDailyCap) {
        v.add(const RuleViolation(6, 'domain_daily_cap'));
      }
      final inbox = ctx.inbox;
      if (inbox == null) {
        v.add(const RuleViolation(6, 'no_inbox'));
      } else if (!inbox.active) {
        v.add(const RuleViolation(6, 'inbox_inactive'));
      } else if ((s.sentTodayByInbox[inbox.id] ?? 0) >= inbox.dailyCapOn(ctx.now)) {
        v.add(const RuleViolation(6, 'inbox_daily_cap'));
      }
    }
    final tz = isKnownTimezone(lead.timezone) ? lead.timezone : ctx.config.defaultTimezone;
    final local = localTimeIn(tz, ctx.now);
    if (local == null || !isBusinessHours(local)) {
      v.add(const RuleViolation(6, 'outside_business_hours'));
    }

    // Rule 7: automatic brakes.
    if (campaign == null) {
      v.add(const RuleViolation(7, 'no_campaign'));
    } else {
      if (campaign.status != 'active') v.add(RuleViolation(7, 'campaign_${campaign.status}'));
      final h = s.campaignHealth[campaign.id];
      if (h != null && h.sent > 0) {
        if (h.bouncePct > s.bounceBrakePct) v.add(const RuleViolation(7, 'bounce_rate'));
        if (h.complaintPct > s.complaintBrakePct) v.add(const RuleViolation(7, 'complaint_rate'));
        if (h.negativePct > s.negativeBrakePct) v.add(const RuleViolation(7, 'negative_reply_rate'));
      }
    }

    // Rule 8: honest identity.
    if (isEmail) {
      final address = s.businessAddress.trim();
      if (address.isEmpty || address.contains('{{')) {
        v.add(const RuleViolation(8, 'business_address_not_configured'));
      } else if (!msg.footer.contains(address)) {
        v.add(const RuleViolation(8, 'missing_address'));
      }
      if (!msg.footer.contains(ctx.config.legalEntity)) v.add(const RuleViolation(8, 'missing_company'));
      if (!msg.footer.contains(ctx.config.privacyUrl.toString())) v.add(const RuleViolation(8, 'missing_privacy_link'));
      if (ctx.inbox != null && ctx.inbox!.displayName.trim().isEmpty) {
        v.add(const RuleViolation(8, 'missing_sender_name'));
      }
    }

    // Rule 9: WhatsApp / SMS only after opt-in, approved templates, 1/week.
    if (isWhatsApp) {
      if (lead.whatsappOptInAt == null) v.add(const RuleViolation(9, 'no_opt_in'));
      if (lead.whatsappLastMarketingAt != null &&
          ctx.now.difference(lead.whatsappLastMarketingAt!) < const Duration(days: 7)) {
        v.add(const RuleViolation(9, 'weekly_cap'));
      }
      if (msg.whatsappTemplate == null || msg.whatsappTemplate!.trim().isEmpty) {
        v.add(const RuleViolation(9, 'no_approved_template'));
      }
    }

    // Rule 10: businesses only, never consumers.
    if (!compliantSources.contains(lead.source)) v.add(const RuleViolation(10, 'non_compliant_source'));
    if (lead.businessName.trim().isEmpty) v.add(const RuleViolation(10, 'not_a_business'));

    // Rule 11: audit trail.
    if (lead.chosenReason == null || lead.chosenReason!.trim().isEmpty) {
      v.add(const RuleViolation(11, 'missing_reason_chosen'));
    }

    return AntiSpamReport(v);
  }
}
