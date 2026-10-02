import 'dart:async';

import '../../features/audit/domain/audit_models.dart';
import '../../features/brochures/domain/brochure_models.dart';
import '../../features/categories/domain/category_models.dart';
import '../../features/flags/domain/settings_models.dart';
import '../../features/moderation/domain/moderation_models.dart';
import '../../features/outreach/domain/outreach_models.dart';
import '../../features/sellers/domain/seller_models.dart';
import '../../features/verification/domain/verification_models.dart';
import '../config/admin_country.dart';

/// In-memory data for demo mode (no SUPABASE_URL). Fictional businesses and
/// people only; nothing here is sent anywhere.
class DemoStore {
  DemoStore(this.config, {DateTime? now}) : now = now ?? DateTime.now() {
    _seed();
  }

  final AdminCountryConfig config;
  final DateTime now;

  /// Demo accounts. Passwords are demo-only and work only in demo mode.
  static const adminEmail = 'admin@demo.local';
  static const adminPassword = 'demo-admin';
  static const sellerEmail = 'seller@demo.local';
  static const sellerPassword = 'demo-seller';

  final categories = <AdminCategory>[];
  final verification = <VerificationItem>[];
  final reports = <ReportItem>[];
  final users = <UserSummary>[];
  final settings = <String, AppSetting>{};
  final leads = <String, OutreachLead>{};
  final events = <OutreachEvent>[];
  final suppression = <SuppressionEntry>[];
  final campaigns = <String, OutreachCampaign>{};
  final sequences = <String, OutreachSequence>{};
  final inboxes = <String, OutreachInbox>{};
  final audit = <AuditEntry>[];
  final brochures = <BrochureRecord>[];
  final coverage = <CoverageCell>[];
  final sellers = <SellerSummary>[];
  final entitlements = <EntitlementRecord>[];

  String? currentAdminId;
  String? currentAdminEmail;
  var _id = 1000;
  String nextId(String prefix) => '$prefix-${_id++}';

  final _changes = StreamController<void>.broadcast();
  Stream<void> get changes => _changes.stream;
  void touch() => _changes.add(null);

  void log(String action, {String? targetType, String? targetId, Map<String, dynamic> details = const {}}) {
    audit.insert(
      0,
      AuditEntry(
        id: nextId('audit'),
        action: action,
        actorId: currentAdminId,
        actorEmail: currentAdminEmail,
        targetType: targetType,
        targetId: targetId,
        details: details,
        createdAt: DateTime.now(),
      ),
    );
  }

  void dispose() => _changes.close();

  bool get _india => config.country == Country.india;

  void _seed() {
    _seedCategories();
    _seedSettings();
    _seedUsers();
    _seedVerification();
    _seedSellers();
    _seedReports();
    _seedOutreach();
    _seedCoverage();
    audit.add(AuditEntry(
      id: nextId('audit'),
      action: 'admin_set_setting',
      actorEmail: adminEmail,
      targetType: 'setting',
      targetId: 'outreach_global_daily_cap',
      details: const {'value': 50},
      createdAt: now.subtract(const Duration(days: 2)),
    ));
  }

  void _seedCategories() {
    AdminCategory c(int id, String slug, String en, CategoryPolicy p,
            {int? parent, String? licence, String? hi, String? es, String? reason}) =>
        AdminCategory(
          id: id,
          parentId: parent,
          slug: slug,
          names: {'en': en, 'hi': ?hi, 'es': ?es},
          policy: p,
          requiredLicenceType: licence,
          policyReason: reason == null ? const {} : {'en': reason},
          sort: id,
        );
    if (_india) {
      categories.addAll([
        c(1, 'appliances', 'Appliances', CategoryPolicy.allowed, hi: 'उपकरण'),
        c(2, 'refrigerators', 'Refrigerators', CategoryPolicy.allowed, parent: 1, hi: 'फ्रिज'),
        c(3, 'water-purifiers', 'Water purifiers', CategoryPolicy.allowed, parent: 1),
        c(4, 'home-services', 'Home services', CategoryPolicy.allowed),
        c(5, 'ac-repair', 'AC repair', CategoryPolicy.allowed, parent: 4),
        c(6, 'plumbing', 'Plumbing', CategoryPolicy.allowed, parent: 4),
        c(7, 'packers-movers', 'Packers and movers', CategoryPolicy.allowed, parent: 4),
        c(8, 'printing', 'Printing', CategoryPolicy.allowed),
        c(9, 'real-estate', 'Real estate', CategoryPolicy.restricted, licence: 'rera'),
        c(10, 'medical', 'Doctors and clinics', CategoryPolicy.restricted, licence: 'nmc_registration'),
        c(11, 'insurance', 'Insurance', CategoryPolicy.blocked, reason: 'Blocked until legal sign-off (IRDAI).'),
        c(12, 'loans', 'Loans and credit', CategoryPolicy.blocked, reason: 'RBI digital lending rules.'),
        c(13, 'legal-services', 'Legal services', CategoryPolicy.blocked, reason: 'Bar Council of India rules.'),
        c(14, 'medicines', 'Medicines and pharmacy', CategoryPolicy.blocked),
      ]);
    } else {
      categories.addAll([
        c(1, 'appliances', 'Appliances', CategoryPolicy.allowed, es: 'Electrodomésticos'),
        c(2, 'refrigerators', 'Refrigerators', CategoryPolicy.allowed, parent: 1, es: 'Refrigeradores'),
        c(3, 'home-services', 'Home services', CategoryPolicy.allowed),
        c(4, 'hvac', 'HVAC', CategoryPolicy.restricted, parent: 3, licence: 'state_contractor_licence'),
        c(5, 'plumbing', 'Plumbing', CategoryPolicy.restricted, parent: 3, licence: 'state_contractor_licence'),
        c(6, 'roofing', 'Roofing', CategoryPolicy.restricted, parent: 3, licence: 'state_contractor_licence'),
        c(7, 'handyman', 'Handyman', CategoryPolicy.allowed, parent: 3),
        c(8, 'moving', 'Moving', CategoryPolicy.allowed, parent: 3),
        c(9, 'printing', 'Printing', CategoryPolicy.allowed),
        c(10, 'legal-services', 'Legal services', CategoryPolicy.restricted, licence: 'state_bar_admission'),
        c(11, 'insurance', 'Insurance', CategoryPolicy.blocked, reason: 'Blocked until legal sign-off (state licensing).'),
        c(12, 'loans', 'Loans and credit', CategoryPolicy.blocked, reason: 'State lending licences.'),
        c(13, 'investments', 'Investments and crypto', CategoryPolicy.blocked, reason: 'SEC/FINRA.'),
        c(14, 'medicines', 'Medicines and pharmacy', CategoryPolicy.blocked),
      ]);
    }
  }

  void _seedSettings() {
    void s(String k, Object? v, String d, {bool public = false}) =>
        settings[k] = AppSetting(key: k, value: v, description: d, isPublic: public);
    s('country', config.countryCode, 'ISO country of this project', public: true);
    s('currency', config.currencyCode, 'ISO currency of this project', public: true);
    s('default_timezone', config.defaultTimezone, 'Fallback time zone', public: true);
    s('monetization_enabled', false, 'Section 7 switch. false = all seller features free', public: true);
    s('early_partner_free_until', null, 'Early partners stay free until this date', public: true);
    s('free_quotes_per_month', _india ? 10 : 5, 'Free tier quotes per seller per month', public: true);
    s('quote_cap', 10, 'Default max quotes per request', public: true);
    s('priority_window_minutes', 15, 'Verified-first priority window', public: true);
    s('max_requests_per_buyer_per_day', 10, 'Rate limit for create_request', public: true);
    s('max_quotes_per_seller_per_hour', 20, 'Rate limit for submit_quote', public: true);
    s('auto_hide_report_threshold', 3, 'Distinct open reports before auto-hide');
    s('match_push_cap', 200, 'Max sellers notified per new request');
    s('outreach_enabled', true, 'Section 21 feature flag');
    s('outreach_global_daily_cap', 50, 'Global daily ceiling for outreach emails');
    s('outreach_per_domain_daily_cap', 2, 'Max outreach emails per recipient domain per day');
    s('outreach_bounce_brake_pct', 2, 'Pause campaign above this bounce %');
    s('outreach_complaint_brake_pct', 0.08, 'Pause campaign above this complaint %');
    s('outreach_negative_brake_pct', 5, 'Pause campaign above this negative-reply %');
    s('outreach_uncontacted_retention_days', 90, 'Delete uncontacted leads after N days');
    s('outreach_business_address', '100 Demo Street, Demo City (demo data, not a real address)',
        'Physical postal address in every outreach email');
    s('places_monthly_budget_usd', 150, 'Hard cap for Google Places spend per month');
    s('seo_thresholds', {'min_quotes': 10, 'min_sellers': 3, 'window_days': 90, 'stale_days': 90},
        'SEO price-page gates (Section 21.9)');
    s('seo_ai_guides_weekly_cap', 10, 'Max new AI-assisted buying guides per rolling 7 days');
  }

  void _seedUsers() {
    users.addAll([
      const UserSummary(id: 'u-admin', name: 'Demo Admin', email: adminEmail, roles: ['buyer', 'admin'], status: 'active'),
      const UserSummary(id: 'u-1', name: 'Asha Demo', email: 'asha@example.com', roles: ['buyer'], status: 'active'),
      const UserSummary(id: 'u-2', name: 'Ben Demo', email: 'ben@example.com', roles: ['buyer'], status: 'active'),
      const UserSummary(id: 'u-3', name: 'Spammy Seller (demo)', email: 'spam@example.com', roles: ['buyer', 'seller'], status: 'active'),
      const UserSummary(id: 'u-4', name: 'Chen Demo', email: 'chen@example.com', roles: ['buyer', 'seller'], status: 'suspended'),
      const UserSummary(id: 'u-seller', name: 'Demo Seller', email: sellerEmail, roles: ['buyer', 'seller'], status: 'active'),
    ]);
  }

  void _seedVerification() {
    final cities = config.priorityCities;
    final types = config.verificationDocTypes;
    final names = _india
        ? ['Sharma Cooling Services (demo)', 'Bright Prints (demo)', 'Metro Packers (demo)', 'Aqua Pure Store (demo)']
        : ['Lone Star HVAC (demo)', 'Hudson Print Co (demo)', 'Sunbelt Movers (demo)', 'Peachtree Plumbing (demo)'];
    for (var i = 0; i < names.length; i++) {
      verification.add(VerificationItem(
        id: 'doc-$i',
        kind: VerificationKind.document,
        sellerId: 's-$i',
        businessName: names[i],
        docType: types[i % types.length],
        docNumber: _india ? '29ABCDE${1234 + i}F1Z5' : '12-34567${i}9',
        filePath: i.isEven ? 's-$i/doc_$i.pdf' : null,
        city: cities[i % cities.length].name,
        state: cities[i % cities.length].state,
        sellerStatus: 'pending',
        submittedAt: now.subtract(Duration(hours: 5 * (i + 1))),
      ));
    }
    verification.add(VerificationItem(
      id: 'lic-1',
      kind: VerificationKind.licence,
      sellerId: 's-0',
      businessName: names.first,
      docType: _india ? 'rera' : 'state_contractor_licence',
      docNumber: _india ? 'PRM/KA/RERA/1251/309/AG/000000' : 'TACLA00000000C',
      issuer: _india ? 'Karnataka RERA' : 'Texas Dept. of Licensing and Regulation',
      state: cities.first.state,
      expiresAt: now.add(const Duration(days: 300)),
      categoryIds: const [9],
      sellerStatus: 'pending',
      filePath: 's-0/licence.pdf',
      submittedAt: now.subtract(const Duration(hours: 30)),
    ));
  }

  void _seedSellers() {
    final byId = <String, VerificationItem>{
      for (final v in verification)
        if (v.kind == VerificationKind.document) v.sellerId: v,
    };
    var i = 0;
    for (final v in byId.values) {
      sellers.add(SellerSummary(
        id: v.sellerId,
        businessName: v.businessName,
        ownerName: 'Owner ${i + 1} (demo)',
        phone: _india ? '+9198765${43210 + i}' : '+1512555${1200 + i}',
        businessPhone: _india ? '+9180412${34560 + i}' : '+1512555${3400 + i}',
        email: 'owner${i + 1}@example.com',
        city: v.city,
        state: v.state,
        verificationStatus: 'pending',
        earlyPartner: i == 0,
        createdAt: now.subtract(Duration(days: 10 + i)),
      ));
      i++;
    }
    final city = config.priorityCities.first;
    sellers.add(SellerSummary(
      id: 'u-seller',
      businessName: _india ? 'Demo Electricals (demo)' : 'Demo Electric (demo)',
      ownerName: 'Demo Seller',
      phone: _india ? '+919000000001' : '+15125550001',
      email: sellerEmail,
      city: city.name,
      state: city.state,
      verificationStatus: 'verified',
      createdAt: now.subtract(const Duration(days: 40)),
    ));
    entitlements.add(EntitlementRecord(
      id: 'ent-1',
      sellerId: 'u-seller',
      store: 'manual',
      provider: 'admin',
      productId: 'admin_grant_credits',
      tier: 'credits',
      status: 'active',
      creditsBalance: 4,
      createdAt: now.subtract(const Duration(days: 20)),
    ));
  }

  void _seedReports() {
    reports.addAll([
      ReportItem(
        id: 'rep-1',
        targetType: 'quote',
        targetId: 'q-1',
        reason: 'spam',
        details: 'Same copy-paste quote on every request, asks to call outside the app.',
        targetPreview: 'Best price!!! Call me now on my personal number for a deal',
        targetOwnerId: 'u-3',
        reportCount: 3,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      ReportItem(
        id: 'rep-2',
        targetType: 'request',
        targetId: 'r-7',
        reason: 'prohibited_item',
        details: 'Looks like a request for prescription medicine.',
        targetPreview: 'Need antibiotics delivered, no prescription',
        targetOwnerId: 'u-2',
        createdAt: now.subtract(const Duration(hours: 9)),
      ),
      ReportItem(
        id: 'rep-3',
        targetType: 'review',
        targetId: 'rv-2',
        reason: 'abusive',
        targetPreview: 'Terrible people, [insult removed]',
        targetOwnerId: 'u-1',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ReportItem(
        id: 'rep-4',
        targetType: 'message',
        targetId: 'm-19',
        reason: 'fraud',
        details: 'Asked for advance payment to a personal account.',
        targetPreview: 'Send 50% advance to this account first',
        targetOwnerId: 'u-3',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }

  void _seedOutreach() {
    final cities = config.priorityCities;
    final brand = config.appName;
    sequences['seq-1'] = OutreachSequence(
      id: 'seq-1',
      name: 'Founding partners (${config.countryCode})',
      steps: [
        SequenceStep(step: 1, delayDays: 0, variants: [
          TemplateVariant(
            subject: 'Quote requests for {{category}} in {{city}}',
            body: 'Hi {{business_name}} team,\n\n'
                'I saw your {{rating}}-star listing. People in {{city}} post what they need on $brand '
                'and local {{category}} businesses send them quotes. Founding partners use it free until {{founding_until}}.\n\n'
                'Shall I set up your shop? {{signup_link}}\n\n{{sender_name}}',
          ),
          TemplateVariant(
            subject: '{{category}} leads in {{city}}?',
            body: 'Hello {{business_name}},\n\n'
                '$brand lets buyers in {{city}} ask several local {{category}} businesses for a quote at once. '
                'Listing is free for founding partners until {{founding_until}}.\n\n'
                'Would you like me to create your shop page? {{signup_link}}\n\n{{sender_name}}',
          ),
        ]),
        const SequenceStep(step: 2, delayDays: 4, includeBrochure: true, variants: [
          TemplateVariant(
            subject: 'Short follow-up for {{business_name}}',
            body: 'Hi again {{business_name}},\n\n'
                'Here is a one-page brochure on how {{category}} businesses in {{city}} get requests: {{brochure_link}}\n\n'
                'Is it worth a quick look?\n\n{{sender_name}}',
          ),
        ]),
        SequenceStep(step: 3, delayDays: 7, variants: [
          TemplateVariant(
            subject: 'Last note from $brand',
            body: 'Hi {{business_name}},\n\n'
                'This is my last note. If {{category}} requests from {{city}} would help later, '
                'is it okay if I keep your spot open until {{founding_until}}?\n\n{{sender_name}}',
          ),
        ]),
      ],
    );
    final relevant = _india ? [5, 6, 7, 2] : [4, 5, 7, 8, 2];
    campaigns['camp-1'] = OutreachCampaign(
      id: 'camp-1',
      name: '${cities.first.name} home services',
      sequenceId: 'seq-1',
      status: 'active',
      categoryIds: relevant,
      dailyCap: 40,
    );
    campaigns['camp-2'] = OutreachCampaign(
      id: 'camp-2',
      name: '${cities[1].name} printing',
      sequenceId: 'seq-1',
      status: 'paused',
      categoryIds: [_india ? 8 : 9],
      dailyCap: 20,
      pausedReason: 'auto_brake:bounce_rate',
      pausedAt: now.subtract(const Duration(days: 1)),
    );
    inboxes['inbox-1'] = OutreachInbox(
      id: 'inbox-1',
      email: 'hello@try-${config.webDomain.split('.').first}.example',
      displayName: _india ? 'Priya (Partnerships, $brand)' : 'Sam (Partnerships, $brand)',
      provider: 'resend',
      warmupStartedOn: now.subtract(const Duration(days: 30)),
    );

    final c0 = cities[0];
    final c1 = cities[1];
    final c2 = cities[2];
    var n = 0;
    OutreachLead lead(
      String name,
      PriorityCity city,
      LeadStage stage, {
      String? email,
      EmailStatus emailStatus = EmailStatus.valid,
      List<int>? cats,
      LeadSource source = LeadSource.osm,
      int touches = 0,
      SequenceStatus seq = SequenceStatus.none,
      String? campaign = 'camp-1',
      String? sellerId,
      double? rating,
      String? phone,
      DateTime? lastContacted,
      DateTime? optIn,
      String? nextAction,
    }) {
      n++;
      final domain = email?.split('@').last;
      return OutreachLead(
        id: 'lead-$n',
        businessKey: domain != null ? 'domain:$domain' : 'name:${name.toLowerCase().replaceAll(' ', '-')}',
        businessName: name,
        categoriesSource: const ['craft=hvac'],
        matchedCategoryIds: cats ?? [relevant[n % relevant.length]],
        email: email,
        emailDomain: domain,
        emailStatus: email == null ? EmailStatus.unverified : emailStatus,
        addressSource: email == null ? null : 'https://$domain/contact',
        phone: phone,
        website: domain == null ? null : 'https://$domain',
        websiteDomain: domain,
        city: city.name,
        state: city.state,
        timezone: city.timezone,
        rating: rating,
        source: source,
        sourceRef: source == LeadSource.osm ? 'node/${900000 + n}' : null,
        lawfulBasis: source == LeadSource.inbound ? LawfulBasis.inboundRequest : LawfulBasis.legitimateInterest,
        chosenReason: 'Tagged as a matching trade in ${city.name} (${source.name})',
        stage: stage,
        campaignId: campaign,
        sequenceStatus: seq,
        touchesSent: touches,
        contactedAt: lastContacted,
        lastContactedAt: lastContacted,
        whatsappOptInAt: optIn,
        whatsappOptInChannel: optIn == null ? null : 'brochure_qr',
        whatsappOptInProof: optIn == null ? null : 'Scanned brochure QR and replied YES',
        sellerId: sellerId,
        nextAction: nextAction,
        signupToken: 'demo-signup-$n',
        unsubscribeToken: 'demo-unsub-$n',
        priority: cities.indexOf(city) + 1,
        createdAt: now.subtract(Duration(days: 20 - n)),
      );
    }

    final suffix = _india ? 'in.example' : 'us.example';
    final list = <OutreachLead>[
      lead('Northside Cooling (demo)', c0, LeadStage.sourced, email: 'info@northside-cooling.$suffix', rating: 4.6),
      lead('Quick Fix Plumbing (demo)', c0, LeadStage.sourced, email: 'hello@quickfix-plumbing.$suffix', rating: 4.2),
      lead('Corner Appliance Mart (demo)', c1, LeadStage.sourced, email: 'sales@corner-appliance.$suffix', emailStatus: EmailStatus.unverified),
      lead('Handy Hands (demo)', c2, LeadStage.sourced, email: 'handyhands.demo@gmail.com', rating: 4.9),
      lead('Old Town Movers (demo)', c1, LeadStage.sourced, phone: _india ? '+910000000101' : '+15550100101', email: null, campaign: null),
      lead('No Category Shop (demo)', c2, LeadStage.sourced, email: 'info@nocategory.$suffix', cats: const []),
      lead('Riverside Repairs (demo)', c0, LeadStage.contacted,
          email: 'office@riverside-repairs.$suffix', touches: 1, seq: SequenceStatus.active, rating: 4.4,
          lastContacted: now.subtract(const Duration(days: 6))),
      lead('Blue Line Services (demo)', c0, LeadStage.contacted,
          email: 'contact@blueline.$suffix', touches: 3, seq: SequenceStatus.completed,
          lastContacted: now.subtract(const Duration(days: 15))),
      lead('Sunrise Movers (demo)', c1, LeadStage.replied,
          email: 'team@sunrise-movers.$suffix', touches: 1, seq: SequenceStatus.stopped, nextAction: 'reply'),
      lead('Prime Prints (demo)', c1, LeadStage.onboarding,
          email: 'hi@primeprints.$suffix', touches: 2, seq: SequenceStatus.stopped,
          phone: _india ? '+910000000102' : '+15550100102', optIn: now.subtract(const Duration(days: 3)),
          nextAction: 'Finish shop profile call'),
      lead('Metro Fridge Care (demo)', c2, LeadStage.liveSeller,
          email: 'care@metrofridge.$suffix', touches: 1, seq: SequenceStatus.stopped, sellerId: 's-10'),
      lead('Elite Electricals (demo)', c0, LeadStage.active,
          email: 'admin@elite-elec.$suffix', touches: 2, seq: SequenceStatus.stopped, sellerId: 's-11', source: LeadSource.inbound),
      lead('Not Now Traders (demo)', c2, LeadStage.notInterested,
          email: 'owner@notnow.$suffix', touches: 1, seq: SequenceStatus.stopped),
      lead('Opted Out Co (demo)', c1, LeadStage.doNotContact,
          email: 'info@optedout.$suffix', touches: 1, seq: SequenceStatus.stopped),
    ];
    for (final l in list) {
      leads[l.id] = l;
    }

    suppression.addAll([
      SuppressionEntry(
          id: 'sup-1', email: 'info@optedout.$suffix', reason: 'unsubscribe', source: 'one-click',
          createdAt: now.subtract(const Duration(days: 4))),
      SuppressionEntry(
          id: 'sup-2', emailDomain: 'competitor.example', reason: 'manual', note: 'Asked us not to contact any branch',
          createdAt: now.subtract(const Duration(days: 9))),
    ]);

    for (final l in list.where((l) => l.touchesSent > 0)) {
      for (var step = 1; step <= l.touchesSent; step++) {
        events.add(OutreachEvent(
          id: nextId('ev'),
          leadId: l.id,
          campaignId: l.campaignId,
          inboxId: 'inbox-1',
          channel: 'email',
          eventType: 'sent',
          sequenceStep: step,
          subject: 'Step $step',
          recipient: l.email,
          reasonChosen: l.chosenReason,
          addressSource: l.addressSource,
          lawfulBasis: l.lawfulBasis.wire,
          createdAt: (l.lastContactedAt ?? now).subtract(Duration(days: 4 * (l.touchesSent - step))),
        ));
      }
    }
    events.add(OutreachEvent(
      id: nextId('ev'),
      leadId: 'lead-9',
      channel: 'email',
      eventType: 'replied',
      bodyPreview: 'Sounds interesting, how does it work for a small team?',
      createdAt: now.subtract(const Duration(days: 2)),
    ));
    events.add(OutreachEvent(
      id: nextId('ev'),
      leadId: 'lead-13',
      channel: 'email',
      eventType: 'not_now',
      bodyPreview: 'Not now, maybe after the festive season.',
      createdAt: now.subtract(const Duration(days: 5)),
    ));
  }

  void _seedCoverage() {
    final cats = categories.where((c) => c.policy != CategoryPolicy.blocked && c.parentId != null).toList();
    var k = 0;
    for (final city in config.priorityCities.take(5)) {
      for (final cat in cats) {
        final sellers = (k * 7 + 3) % 11;
        coverage.add(CoverageCell(
          city: city.name,
          state: city.state,
          categoryId: cat.id,
          sellers: sellers,
          needsSellers: sellers < 5,
        ));
        k++;
      }
    }
  }
}
