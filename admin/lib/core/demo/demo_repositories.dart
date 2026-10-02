import 'dart:async';

import '../../features/audit/domain/audit_models.dart';
import '../../features/auth/domain/admin_auth_repository.dart';
import '../../features/brochures/domain/brochure_models.dart';
import '../../features/categories/domain/category_models.dart';
import '../../features/dashboard/domain/metrics.dart';
import '../../features/flags/domain/settings_models.dart';
import '../../features/moderation/domain/moderation_models.dart';
import '../../features/outreach/domain/anti_spam.dart';
import '../../features/outreach/domain/composer.dart';
import '../../features/outreach/domain/outreach_models.dart';
import '../../features/outreach/domain/outreach_repository.dart';
import '../../features/outreach/domain/stage_machine.dart';
import '../../features/verification/domain/verification_models.dart';
import 'demo_store.dart';

Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 120));

class DemoAdminAuthRepository implements AdminAuthRepository {
  DemoAdminAuthRepository(this.s);
  final DemoStore s;
  final _ctrl = StreamController<AdminSession?>.broadcast();
  AdminSession? _current;

  @override
  AdminSession? get current => _current;

  @override
  Stream<AdminSession?> sessionChanges() async* {
    yield _current;
    yield* _ctrl.stream;
  }

  @override
  Future<AdminSession> signIn({required String email, required String password}) async {
    await _latency();
    final e = email.trim().toLowerCase();
    if (e == DemoStore.adminEmail && password == DemoStore.adminPassword) {
      _current = const AdminSession(userId: 'u-admin', email: DemoStore.adminEmail, name: 'Demo Admin');
      s.currentAdminId = _current!.userId;
      s.currentAdminEmail = _current!.email;
      _ctrl.add(_current);
      return _current!;
    }
    if (e == DemoStore.sellerEmail && password == DemoStore.sellerPassword) {
      // Valid account without the admin role: refused like the real backend.
      throw const NotAdminException();
    }
    throw const InvalidCredentialsException();
  }

  @override
  Future<void> signOut() async {
    _current = null;
    s.currentAdminId = null;
    _ctrl.add(null);
  }
}

class DemoMetricsRepository implements MetricsRepository {
  DemoMetricsRepository(this.s);
  final DemoStore s;

  @override
  Future<DashboardMetrics> load() async {
    await _latency();
    final perStage = <String, int>{for (final st in LeadStage.values) st.wire: 0};
    for (final l in s.leads.values) {
      perStage[l.stage.wire] = perStage[l.stage.wire]! + 1;
    }
    final contacted = s.leads.values.where((l) => l.touchesSent > 0).length;
    final replied = s.leads.values
        .where((l) => const {LeadStage.replied, LeadStage.onboarding, LeadStage.liveSeller, LeadStage.active}.contains(l.stage))
        .length;
    final signed = s.leads.values.where((l) => l.sellerId != null).length;
    final today = DateTime.now();
    final sentToday = s.events
        .where((e) => e.eventType == 'sent' && e.createdAt.year == today.year && e.createdAt.month == today.month && e.createdAt.day == today.day)
        .length;
    return DashboardMetrics(
      users: 1240,
      sellers: 312,
      verifiedSellers: 201,
      pendingVerifications: s.verification.where((v) => v.kind == VerificationKind.document).length,
      pendingLicences: s.verification.where((v) => v.kind == VerificationKind.licence).length,
      openReports: s.reports.length,
      openRequests: 87,
      requests7d: 164,
      quotes7d: 512,
      orders7d: 41,
      requestsWith3QuotesPct: 58.4,
      medianFirstQuoteMins: 96,
      requestToAcceptancePct: 27.5,
      sellerResponseRatePct: 44.1,
      freeToPaidPct: null,
      retention: const {'buyer_d1': 38.0, 'buyer_d7': 21.5, 'buyer_d30': 12.0, 'seller_d1': 61.0, 'seller_d7': 47.0, 'seller_d30': 35.0},
      revenuePerSellerMinor: 0,
      refunds30d: 0,
      leadsPerStage: perStage,
      outreachSentToday: sentToday,
      outreachDailyCapacity: (s.settings['outreach_global_daily_cap']?.value as num?)?.toInt(),
      outreachQueue: s.leads.values.where((l) => l.stage == LeadStage.sourced && l.campaignId != null).length,
      replyRatePct: contacted == 0 ? null : 100.0 * replied / contacted,
      signupRatePct: contacted == 0 ? null : 100.0 * signed / contacted,
    );
  }
}

class DemoVerificationRepository implements VerificationRepository {
  DemoVerificationRepository(this.s);
  final DemoStore s;

  @override
  Future<List<VerificationItem>> pending() async {
    await _latency();
    return List.of(s.verification)..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  @override
  Future<Uri?> documentUrl(String filePath) async => null; // no files in demo mode

  @override
  Future<void> review(VerificationItem item, {required bool approve, String? reason}) async {
    await _latency();
    if (!approve && (reason == null || reason.trim().isEmpty)) throw ArgumentError('reason_required');
    s.verification.removeWhere((v) => v.id == item.id);
    s.log(item.kind == VerificationKind.document ? 'admin_review_document' : 'admin_review_licence',
        targetType: item.kind.name, targetId: item.id, details: {'approve': approve, 'reason': ?reason});
    s.touch();
  }
}

class DemoModerationRepository implements ModerationRepository {
  DemoModerationRepository(this.s);
  final DemoStore s;

  @override
  Future<List<ReportItem>> openReports() async {
    await _latency();
    return List.of(s.reports);
  }

  @override
  Future<int> resolve(String reportId, ReportAction action, {String? note}) async {
    await _latency();
    final r = s.reports.firstWhere((r) => r.id == reportId);
    final n = s.reports.where((x) => x.targetType == r.targetType && x.targetId == r.targetId).length;
    s.reports.removeWhere((x) => x.targetType == r.targetType && x.targetId == r.targetId);
    s.log('admin_resolve_report', targetType: r.targetType, targetId: r.targetId, details: {'action': action.name, 'note': ?note});
    s.touch();
    return n;
  }

  @override
  Future<List<UserSummary>> searchUsers(String query) async {
    await _latency();
    final q = query.trim().toLowerCase();
    return s.users
        .where((u) => q.isEmpty || '${u.name} ${u.email} ${u.phone} ${u.id}'.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<UserSummary> setUserStatus(String userId, String status, {DateTime? until, String? reason}) async {
    await _latency();
    if (userId == s.currentAdminId) throw StateError('cannot_change_own_status');
    final i = s.users.indexWhere((u) => u.id == userId);
    if (i < 0) throw StateError('user_not_found');
    final u = s.users[i];
    final updated = UserSummary(
      id: u.id,
      name: u.name,
      email: u.email,
      phone: u.phone,
      roles: u.roles,
      status: status,
      suspendedUntil: status == 'suspended' ? until : null,
      statusReason: reason,
    );
    s.users[i] = updated;
    s.log('admin_set_user_status', targetType: 'user', targetId: userId, details: {'status': status, 'reason': ?reason});
    s.touch();
    return updated;
  }
}

class DemoAuditRepository implements AuditRepository {
  DemoAuditRepository(this.s);
  final DemoStore s;

  @override
  Future<List<AuditEntry>> recent({int limit = 200, String? targetType}) async {
    await _latency();
    return s.audit.where((a) => targetType == null || a.targetType == targetType).take(limit).toList();
  }
}

class DemoCategoryRepository implements CategoryAdminRepository {
  DemoCategoryRepository(this.s);
  final DemoStore s;

  @override
  Future<List<AdminCategory>> list() async {
    await _latency();
    return List.of(s.categories);
  }

  @override
  Future<AdminCategory> setPolicy(int categoryId, CategoryPolicy policy,
      {String? requiredLicenceType, Map<String, String>? disclaimer, Map<String, String>? policyReason}) async {
    await _latency();
    if (policy == CategoryPolicy.restricted && (requiredLicenceType ?? '').trim().isEmpty) {
      throw ArgumentError('licence_type_required');
    }
    final i = s.categories.indexWhere((c) => c.id == categoryId);
    final c = s.categories[i].copyWith(
      policy: policy,
      requiredLicenceType: requiredLicenceType,
      disclaimer: disclaimer,
      policyReason: policyReason,
    );
    s.categories[i] = c;
    s.log('admin_set_category_policy', targetType: 'category', targetId: '$categoryId', details: {'policy': policy.name});
    s.touch();
    return c;
  }

  @override
  Future<AdminCategory> update(int categoryId, {Map<String, String>? names, bool? active}) async {
    await _latency();
    final i = s.categories.indexWhere((c) => c.id == categoryId);
    final c = s.categories[i].copyWith(names: names, active: active);
    s.categories[i] = c;
    s.log('admin_upsert_category', targetType: 'category', targetId: '$categoryId', details: {'active': ?active});
    s.touch();
    return c;
  }
}

class DemoSettingsRepository implements SettingsRepository {
  DemoSettingsRepository(this.s);
  final DemoStore s;

  @override
  Future<List<AppSetting>> list() async {
    await _latency();
    return s.settings.values.toList()..sort((a, b) => a.key.compareTo(b.key));
  }

  @override
  Future<AppSetting> set(String key, Object? value) async {
    await _latency();
    final cur = s.settings[key];
    if (cur == null) throw ArgumentError('unknown_setting');
    if (cur.value is bool && value is! bool) throw ArgumentError('invalid_setting_value');
    if (cur.value is num && (value is! num || value < 0)) throw ArgumentError('invalid_setting_value');
    final wasOn = s.settings['monetization_enabled']?.value == true;
    s.settings[key] = cur.withValue(value);
    if (key == 'monetization_enabled' && value == true && !wasOn) {
      final until = s.settings['early_partner_free_until']?.value ??
          DateTime.now().add(const Duration(days: 182)).toUtc().toIso8601String();
      s.settings['early_partner_free_until'] = s.settings['early_partner_free_until']!.withValue(until);
    }
    s.log('admin_set_setting', targetType: 'setting', targetId: key, details: {'value': value});
    s.touch();
    return s.settings[key]!;
  }
}

class DemoBrochureRepository implements BrochureRepository {
  DemoBrochureRepository(this.s);
  final DemoStore s;

  @override
  Future<List<BrochureRecord>> list() async {
    await _latency();
    return List.of(s.brochures.reversed);
  }

  @override
  Future<BrochureRecord> save({
    required String cityName,
    String? state,
    int? categoryId,
    required String categorySlug,
    required String language,
    required String format,
    required List<int> bytes,
    required String signupUrl,
    required Map<String, String> utm,
  }) async {
    await _latency();
    final version = s.brochures
            .where((b) => b.cityName == cityName && b.categoryId == categoryId && b.language == language && b.format == format)
            .length +
        1;
    final ext = format == 'image' ? 'png' : 'pdf';
    final rec = BrochureRecord(
      id: s.nextId('bro'),
      cityName: cityName,
      state: state,
      categoryId: categoryId,
      language: language,
      format: format,
      storagePath: '${s.config.countryCode.toLowerCase()}/${_slug(cityName)}/$categorySlug/$language/$format-v$version.$ext',
      signupUrl: signupUrl,
      version: version,
      createdAt: DateTime.now(),
    );
    s.brochures.add(rec);
    s.log('brochure_generated', targetType: 'brochure', targetId: rec.id, details: {'path': rec.storagePath});
    s.touch();
    return rec;
  }
}

String _slug(String v) => v.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

class DemoOutreachRepository implements OutreachRepository {
  DemoOutreachRepository(this.s);
  final DemoStore s;

  @override
  Future<List<OutreachLead>> leads(LeadFilter f) async {
    await _latency();
    final q = f.query?.trim().toLowerCase();
    return s.leads.values.where((l) {
      if (f.state != null && l.state != f.state) return false;
      if (f.city != null && l.city != f.city) return false;
      if (f.categoryId != null && !l.matchedCategoryIds.contains(f.categoryId)) return false;
      if (f.source != null && l.source != f.source) return false;
      if (q != null && q.isNotEmpty && !'${l.businessName} ${l.email} ${l.phone} ${l.city}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => (a.priority ?? 999).compareTo(b.priority ?? 999));
  }

  @override
  Future<OutreachLead> lead(String id) async {
    await _latency();
    return s.leads[id] ?? (throw StateError('lead_not_found'));
  }

  @override
  Future<List<OutreachEvent>> events(String leadId) async {
    await _latency();
    return s.events.where((e) => e.leadId == leadId).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  void _event(String leadId, String channel, String type, {String? body, Map<String, dynamic> meta = const {}}) {
    s.events.add(OutreachEvent(
      id: s.nextId('ev'),
      leadId: leadId,
      channel: channel,
      eventType: type,
      bodyPreview: body,
      meta: meta,
      createdBy: s.currentAdminId,
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<OutreachLead> moveStage(OutreachLead lead, LeadStage to, TransitionResult result, {String? note}) async {
    await _latency();
    final current = s.leads[lead.id]!;
    final next = StageMachine.apply(current, to, result);
    s.leads[lead.id] = next;
    _event(lead.id, 'system', 'stage_change', body: note, meta: {'from': current.stage.wire, 'to': to.wire});
    if (result.effects.contains(TransitionEffect.suppress)) {
      _addSuppression(email: current.email, phone: current.phone, businessKey: current.businessKey, reason: 'do_not_contact');
    }
    s.log('outreach_stage_change', targetType: 'outreach_lead', targetId: lead.id, details: {'from': current.stage.wire, 'to': to.wire});
    s.touch();
    return s.leads[lead.id]!;
  }

  @override
  Future<OutreachLead> updateLead(String id,
      {String? notes, String? nextAction, DateTime? nextActionDue, bool clearNextAction = false}) async {
    await _latency();
    final l = s.leads[id]!;
    final next = l.copyWith(
      notes: notes ?? l.notes,
      nextAction: clearNextAction ? null : (nextAction ?? l.nextAction),
      nextActionDue: clearNextAction ? null : (nextActionDue ?? l.nextActionDue),
    );
    s.leads[id] = next;
    s.touch();
    return next;
  }

  @override
  Future<void> logContact(String leadId, ManualContact kind, String text) async {
    await _latency();
    _event(leadId, kind.channel, kind.eventType, body: text);
    s.log('outreach_${kind.eventType}', targetType: 'outreach_lead', targetId: leadId);
    s.touch();
  }

  @override
  Future<OutreachLead> recordOptIn(String leadId, {required String channel, required String proof}) async {
    await _latency();
    final l = s.leads[leadId]!.copyWith(
      whatsappOptInAt: DateTime.now(),
      whatsappOptInChannel: channel,
      whatsappOptInProof: proof,
    );
    s.leads[leadId] = l;
    _event(leadId, 'whatsapp', 'note', body: 'Opt-in recorded ($channel): $proof');
    s.log('outreach_opt_in', targetType: 'outreach_lead', targetId: leadId, details: {'channel': channel});
    s.touch();
    return l;
  }

  @override
  Future<void> enrol(List<String> leadIds, String campaignId) async {
    await _latency();
    for (final id in leadIds) {
      final l = s.leads[id];
      if (l == null) continue;
      // Finished conversations are never re-enrolled (rule 2).
      if (l.sequenceStatus == SequenceStatus.completed || l.sequenceStatus == SequenceStatus.stopped) continue;
      s.leads[id] = l.copyWith(campaignId: campaignId);
    }
    s.log('outreach_enrol', targetType: 'outreach_campaign', targetId: campaignId, details: {'leads': leadIds.length});
    s.touch();
  }

  @override
  Future<ImportResult> importLeads(List<LeadDraft> drafts) async {
    await _latency();
    var inserted = 0;
    var dupes = 0;
    for (final d in drafts) {
      final exists = s.leads.values.any((l) =>
          l.businessKey == d.businessKey ||
          (d.email != null && l.email?.toLowerCase() == d.email!.toLowerCase()) ||
          (d.phone != null && l.phone == d.phone) ||
          (d.websiteDomain != null && l.websiteDomain == d.websiteDomain));
      if (exists) {
        dupes++;
        continue;
      }
      final id = s.nextId('lead');
      final domain = d.email?.split('@').last;
      final suppressed = _suppressed(d.email, d.phone, d.businessKey);
      s.leads[id] = OutreachLead(
        id: id,
        businessKey: d.businessKey,
        businessName: d.businessName,
        categoriesSource: d.categoriesSource,
        matchedCategoryIds: d.matchedCategoryIds,
        email: d.email,
        emailDomain: domain,
        addressSource: d.addressSource,
        phone: d.phone,
        website: d.website,
        websiteDomain: d.websiteDomain,
        placeId: d.placeId,
        osmId: d.osmId,
        address: d.address,
        city: d.city,
        state: d.state,
        postalCode: d.postalCode,
        timezone: d.timezone,
        rating: d.rating,
        ratingCount: d.ratingCount,
        source: d.source,
        sourceRef: d.sourceRef,
        lawfulBasis: d.lawfulBasis,
        chosenReason: d.chosenReason,
        priority: d.priority,
        stage: suppressed ? LeadStage.doNotContact : LeadStage.sourced,
        sequenceStatus: suppressed ? SequenceStatus.stopped : SequenceStatus.none,
        signupToken: 'demo-signup-$id',
        unsubscribeToken: 'demo-unsub-$id',
        createdAt: DateTime.now(),
      );
      inserted++;
    }
    s.log('outreach_import', targetType: 'outreach_lead', details: {'inserted': inserted, 'duplicates': dupes});
    s.touch();
    return ImportResult(inserted: inserted, duplicates: dupes, rejected: const []);
  }

  @override
  Future<List<SuppressionEntry>> suppression() async {
    await _latency();
    return List.of(s.suppression.reversed);
  }

  void _addSuppression({String? email, String? emailDomain, String? phone, String? businessKey, required String reason, String? note}) {
    s.suppression.add(SuppressionEntry(
      id: s.nextId('sup'),
      email: email?.toLowerCase(),
      emailDomain: emailDomain?.toLowerCase(),
      phone: phone,
      businessKey: businessKey,
      reason: reason,
      source: 'admin',
      note: note,
      createdAt: DateTime.now(),
    ));
    // Same effect as the suppression_after_insert trigger.
    for (final l in s.leads.values.toList()) {
      final hit = (email != null && l.email?.toLowerCase() == email.toLowerCase()) ||
          (email == null && emailDomain != null && l.recipientDomain == emailDomain.toLowerCase()) ||
          (phone != null && l.phone == phone) ||
          (businessKey != null && l.businessKey == businessKey);
      if (!hit) continue;
      final keepStage = const {LeadStage.liveSeller, LeadStage.active, LeadStage.onboarding}.contains(l.stage);
      s.leads[l.id] = l.copyWith(
        stage: keepStage ? l.stage : LeadStage.doNotContact,
        sequenceStatus: l.sequenceStatus == SequenceStatus.completed ? l.sequenceStatus : SequenceStatus.stopped,
      );
    }
  }

  @override
  Future<void> suppress(
      {String? email, String? emailDomain, String? phone, String? businessKey, required String reason, String? note}) async {
    await _latency();
    if (email == null && emailDomain == null && phone == null && businessKey == null) {
      throw ArgumentError('empty_suppression');
    }
    _addSuppression(email: email, emailDomain: emailDomain, phone: phone, businessKey: businessKey, reason: reason, note: note);
    s.log('suppression_add', targetType: 'suppression', details: {'reason': reason});
    s.touch();
  }

  bool _suppressed(String? email, String? phone, String? businessKey) => s.suppression.any((e) =>
      (email != null && e.email != null && e.email!.toLowerCase() == email.toLowerCase()) ||
      (email != null && e.email == null && e.emailDomain != null && email.toLowerCase().endsWith('@${e.emailDomain}')) ||
      (phone != null && e.phone == phone) ||
      (businessKey != null && e.businessKey == businessKey));

  @override
  Future<bool> isSuppressed(OutreachLead lead) async => _suppressed(lead.email, lead.phone, lead.businessKey);

  @override
  Future<List<OutreachCampaign>> campaigns() async {
    await _latency();
    return s.campaigns.values.toList();
  }

  @override
  Future<void> setCampaignStatus(String campaignId, String status) async {
    await _latency();
    final c = s.campaigns[campaignId]!;
    s.campaigns[campaignId] = c.copyWith(
      status: status,
      pausedReason: status == 'paused' ? 'manual' : null,
      pausedAt: status == 'paused' ? DateTime.now() : null,
    );
    s.log('outreach_campaign_status', targetType: 'outreach_campaign', targetId: campaignId, details: {'status': status});
    s.touch();
  }

  @override
  Future<List<OutreachSequence>> sequences() async => s.sequences.values.toList();

  @override
  Future<List<OutreachInbox>> inboxes() async => s.inboxes.values.toList();

  @override
  Future<SendStats> sendStats() async {
    await _latency();
    num setting(String k, num d) => (s.settings[k]?.value as num?) ?? d;
    final today = DateTime.now();
    bool isToday(DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;
    final sentToday = s.events.where((e) => e.eventType == 'sent' && isToday(e.createdAt)).toList();
    final byDomain = <String, int>{};
    final byCampaign = <String, int>{};
    final byInbox = <String, int>{};
    for (final e in sentToday) {
      final d = e.recipient?.split('@').last;
      if (d != null) byDomain[d] = (byDomain[d] ?? 0) + 1;
      if (e.campaignId != null) byCampaign[e.campaignId!] = (byCampaign[e.campaignId!] ?? 0) + 1;
      if (e.inboxId != null) byInbox[e.inboxId!] = (byInbox[e.inboxId!] ?? 0) + 1;
    }
    final health = <String, CampaignHealth>{};
    for (final c in s.campaigns.keys) {
      final ev = s.events.where((e) => e.campaignId == c && today.difference(e.createdAt).inDays <= 30);
      health[c] = CampaignHealth(
        sent: ev.where((e) => e.eventType == 'sent').length,
        bounced: ev.where((e) => e.eventType == 'bounced').length,
        complained: ev.where((e) => e.eventType == 'complained').length,
        negative: ev.where((e) => e.eventType == 'negative_reply').length,
      );
    }
    return SendStats(
      outreachEnabled: s.settings['outreach_enabled']?.value == true,
      globalDailyCap: setting('outreach_global_daily_cap', 50).toInt(),
      perDomainDailyCap: setting('outreach_per_domain_daily_cap', 2).toInt(),
      sentTodayGlobal: sentToday.length,
      sentTodayByDomain: byDomain,
      sentTodayByCampaign: byCampaign,
      sentTodayByInbox: byInbox,
      bounceBrakePct: setting('outreach_bounce_brake_pct', 2).toDouble(),
      complaintBrakePct: setting('outreach_complaint_brake_pct', 0.08).toDouble(),
      negativeBrakePct: setting('outreach_negative_brake_pct', 5).toDouble(),
      campaignHealth: health,
      businessAddress: (s.settings['outreach_business_address']?.value as String?) ?? '',
    );
  }

  @override
  Future<List<CoverageCell>> coverage({int minSellers = 5}) async {
    await _latency();
    return s.coverage
        .map((c) => CoverageCell(
            city: c.city, state: c.state, categoryId: c.categoryId, sellers: c.sellers, needsSellers: c.sellers < minSellers))
        .toList()
      ..sort((a, b) => a.sellers.compareTo(b.sellers));
  }

  @override
  Future<ServerGate> serverCanSend(String leadId, String channel, String? inboxId) async {
    await _latency();
    final l = s.leads[leadId];
    if (l == null) return const ServerGate(false, 'lead_not_found');
    if (s.settings['outreach_enabled']?.value != true) return const ServerGate(false, 'outreach_disabled');
    if (_suppressed(l.email, l.phone, l.businessKey)) return const ServerGate(false, 'suppressed');
    if (l.touchesSent >= 3) return const ServerGate(false, 'max_touches');
    if (l.stage != LeadStage.sourced && l.stage != LeadStage.contacted) return ServerGate(false, 'stage_${l.stage.wire}');
    return const ServerGate(true, 'ok');
  }

  /// Simulates the `outreach-send` Edge Function: re-checks the rulebook,
  /// "sends" nothing, and records the event like the database triggers do.
  @override
  Future<SendResult> send(OutreachLead lead, OutreachMessage message) async {
    await _latency();
    final current = s.leads[lead.id]!;
    final campaign = current.campaignId == null ? null : s.campaigns[current.campaignId];
    final report = AntiSpam.check(
      current,
      message,
      SendContext(
        config: s.config,
        stats: await sendStats(),
        now: DateTime.now(),
        isSuppressed: _suppressed(current.email, current.phone, current.businessKey),
        campaign: campaign,
        sequence: campaign == null ? null : s.sequences[campaign.sequenceId],
        inbox: message.inboxId == null ? null : s.inboxes[message.inboxId],
      ),
    );
    if (!report.allowed) return SendResult(ok: false, reason: report.blocking.first.code);
    final id = s.nextId('ev');
    s.events.add(OutreachEvent(
      id: id,
      leadId: current.id,
      campaignId: current.campaignId,
      inboxId: message.inboxId,
      channel: message.channel,
      eventType: 'sent',
      sequenceStep: message.step,
      templateVariant: message.variantIndex,
      subject: message.subject,
      bodyPreview: message.body.length > 500 ? message.body.substring(0, 500) : message.body,
      recipient: message.channel == 'email' ? current.email : current.phone,
      reasonChosen: current.chosenReason,
      addressSource: current.addressSource,
      lawfulBasis: current.lawfulBasis.wire,
      createdBy: s.currentAdminId,
      createdAt: DateTime.now(),
    ));
    final steps = campaign == null ? 3 : s.sequences[campaign.sequenceId]?.steps.length ?? 3;
    final touches = current.touchesSent + 1;
    s.leads[current.id] = current.copyWith(
      touchesSent: touches,
      contactedAt: current.contactedAt ?? DateTime.now(),
      lastContactedAt: DateTime.now(),
      stage: current.stage == LeadStage.sourced ? LeadStage.contacted : current.stage,
      sequenceStatus: touches >= steps ? SequenceStatus.completed : SequenceStatus.active,
      whatsappLastMarketingAt: message.channel == 'whatsapp' ? DateTime.now() : current.whatsappLastMarketingAt,
    );
    s.log('outreach_send', targetType: 'outreach_lead', targetId: current.id, details: {'step': message.step, 'channel': message.channel});
    s.touch();
    return SendResult(ok: true, eventId: id);
  }
}
