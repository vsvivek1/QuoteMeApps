import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/audit/domain/audit_models.dart';
import '../../../features/auth/domain/admin_auth_repository.dart';
import '../../../features/brochures/domain/brochure_models.dart';
import '../../../features/categories/domain/category_models.dart';
import '../../../features/dashboard/domain/metrics.dart';
import '../../../features/flags/domain/settings_models.dart';
import '../../../features/moderation/domain/moderation_models.dart';
import '../../../features/outreach/domain/composer.dart';
import '../../../features/outreach/domain/outreach_models.dart';
import '../../../features/outreach/domain/outreach_repository.dart';
import '../../../features/outreach/domain/stage_machine.dart';
import '../../../features/sellers/domain/manual_payment.dart';
import '../../../features/sellers/domain/seller_models.dart';
import '../../../features/verification/domain/verification_models.dart';
import '../../config/admin_country.dart';

// Supabase implementations. Every call runs as the signed-in admin with the
// anon/publishable key; RLS (`private.is_admin()`) and the admin_* RPCs
// (`private.require_admin()`) decide what is allowed. No service role key.

DateTime? _ts(Object? v) => v == null ? null : DateTime.tryParse(v.toString());
int? _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
double? _dbl(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
Map<String, String> _strMap(Object? v) =>
    v is Map ? {for (final e in v.entries) '${e.key}': '${e.value}'} : const {};

/// Decodes the JWT payload (no verification needed client side: the server
/// checks the signature on every request).
Map<String, dynamic> jwtClaims(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return const {};
  final normalized = base64Url.normalize(parts[1]);
  final decoded = jsonDecode(utf8.decode(base64Url.decode(normalized)));
  return decoded is Map<String, dynamic> ? decoded : const {};
}

class SupabaseAdminAuthRepository implements AdminAuthRepository {
  SupabaseAdminAuthRepository(this.c);
  final SupabaseClient c;
  AdminSession? _current;

  @override
  AdminSession? get current => _current;

  Future<AdminSession?> _verify(Session? session) async {
    if (session == null) return null;
    final roles = jwtClaims(session.accessToken)['roles'];
    final claimAdmin = roles is List && roles.contains('admin');
    if (!claimAdmin) return null;
    final row = await c.from('profiles').select('id, name, email, roles, status').eq('id', session.user.id).maybeSingle();
    final profileRoles = (row?['roles'] as List?)?.cast<String>() ?? const [];
    if (row == null || !profileRoles.contains('admin') || row['status'] != 'active') return null;
    return AdminSession(
      userId: session.user.id,
      email: session.user.email ?? (row['email'] as String? ?? ''),
      name: row['name'] as String?,
    );
  }

  @override
  Stream<AdminSession?> sessionChanges() async* {
    _current = await _verify(c.auth.currentSession);
    if (_current == null && c.auth.currentSession != null) await c.auth.signOut();
    yield _current;
    await for (final state in c.auth.onAuthStateChange) {
      if (state.event == AuthChangeEvent.signedOut) {
        _current = null;
        yield null;
      } else if (state.event == AuthChangeEvent.tokenRefreshed || state.event == AuthChangeEvent.signedIn) {
        _current = await _verify(state.session);
        yield _current;
      }
    }
  }

  @override
  Future<AdminSession> signIn({required String email, required String password}) async {
    final AuthResponse res;
    try {
      res = await c.auth.signInWithPassword(email: email.trim(), password: password);
    } on AuthException {
      throw const InvalidCredentialsException();
    }
    final session = await _verify(res.session);
    if (session == null) {
      await c.auth.signOut();
      throw const NotAdminException();
    }
    _current = session;
    return session;
  }

  @override
  Future<void> signOut() async {
    _current = null;
    await c.auth.signOut();
  }
}

class SupabaseMetricsRepository implements MetricsRepository {
  SupabaseMetricsRepository(this.c);
  final SupabaseClient c;

  @override
  Future<DashboardMetrics> load() async {
    final m = Map<String, dynamic>.from(await c.rpc('admin_metrics') as Map);
    Map<String, dynamic> kpi = const {};
    try {
      // Optional Section 13 KPIs (see BACKEND_NEEDS.md); shown as n/a if missing.
      kpi = Map<String, dynamic>.from(await c.rpc('admin_kpis') as Map);
    } on PostgrestException {
      kpi = const {};
    }
    final perStage = <String, int>{};
    for (final st in LeadStage.values) {
      perStage[st.wire] = await c.from('outreach_leads').count().eq('stage', st.wire);
    }
    final retention = <String, double>{};
    final r = kpi['retention'];
    if (r is Map) {
      for (final e in r.entries) {
        final v = _dbl(e.value);
        if (v != null) retention['${e.key}'] = v;
      }
    }
    return DashboardMetrics(
      users: _int(m['users']),
      sellers: _int(m['sellers']),
      verifiedSellers: _int(m['verified_sellers']),
      pendingVerifications: _int(m['pending_verifications']),
      pendingLicences: _int(m['pending_licences']),
      openReports: _int(m['open_reports']),
      openRequests: _int(m['open_requests']),
      requests7d: _int(m['requests_7d']),
      quotes7d: _int(m['quotes_7d']),
      orders7d: _int(m['orders_7d']),
      requestsWith3QuotesPct: _dbl(m['requests_with_3_quotes_pct']),
      medianFirstQuoteMins: _dbl(m['median_first_quote_mins']),
      requestToAcceptancePct: _dbl(kpi['request_to_acceptance_pct']),
      sellerResponseRatePct: _dbl(kpi['seller_response_rate_pct']),
      freeToPaidPct: _dbl(kpi['free_to_paid_pct']),
      retention: retention,
      revenuePerSellerMinor: _int(kpi['revenue_per_seller_minor']),
      refunds30d: _int(kpi['refunds_30d']),
      leadsPerStage: perStage,
      outreachSentToday: _int(kpi['outreach_sent_today']),
      outreachDailyCapacity: _int(kpi['outreach_daily_capacity']),
      outreachQueue: _int(kpi['outreach_queue']),
      replyRatePct: _dbl(kpi['outreach_reply_rate_pct']),
      signupRatePct: _dbl(kpi['outreach_signup_rate_pct']),
    );
  }
}

class SupabaseVerificationRepository implements VerificationRepository {
  SupabaseVerificationRepository(this.c);
  final SupabaseClient c;

  @override
  Future<List<VerificationItem>> pending() async {
    final docs = await c
        .from('seller_documents')
        .select('id, seller_id, doc_type, doc_number, file_path, created_at, sellers(business_name, city, state, verification_status)')
        .eq('status', 'pending')
        .order('created_at');
    final lics = await c
        .from('seller_licences')
        .select('id, seller_id, licence_type, number, issuer, state, category_ids, file_path, expires_at, created_at, '
            'sellers(business_name, city, state, verification_status)')
        .eq('status', 'pending')
        .order('created_at');
    Map<String, dynamic> seller(Map<String, dynamic> r) => Map<String, dynamic>.from((r['sellers'] as Map?) ?? const {});
    return [
      for (final r in docs)
        VerificationItem(
          id: r['id'] as String,
          kind: VerificationKind.document,
          sellerId: r['seller_id'] as String,
          businessName: seller(r)['business_name'] as String? ?? '?',
          docType: r['doc_type'] as String,
          docNumber: r['doc_number'] as String?,
          filePath: r['file_path'] as String?,
          city: seller(r)['city'] as String?,
          state: seller(r)['state'] as String?,
          sellerStatus: seller(r)['verification_status'] as String?,
          submittedAt: _ts(r['created_at'])!,
        ),
      for (final r in lics)
        VerificationItem(
          id: r['id'] as String,
          kind: VerificationKind.licence,
          sellerId: r['seller_id'] as String,
          businessName: seller(r)['business_name'] as String? ?? '?',
          docType: r['licence_type'] as String,
          docNumber: r['number'] as String?,
          filePath: r['file_path'] as String?,
          issuer: r['issuer'] as String?,
          city: seller(r)['city'] as String?,
          state: r['state'] as String? ?? seller(r)['state'] as String?,
          expiresAt: _ts(r['expires_at']),
          categoryIds: ((r['category_ids'] as List?) ?? const []).map((e) => _int(e)!).toList(),
          sellerStatus: seller(r)['verification_status'] as String?,
          submittedAt: _ts(r['created_at'])!,
        ),
    ];
  }

  @override
  Future<Uri?> documentUrl(String filePath) async {
    final url = await c.storage.from('verification-docs').createSignedUrl(filePath, 300);
    return Uri.parse(url);
  }

  @override
  Future<void> review(VerificationItem item, {required bool approve, String? reason}) async {
    if (item.kind == VerificationKind.document) {
      await c.rpc('admin_review_document', params: {
        'p_document_id': item.id,
        'p_approve': approve,
        'p_reason': reason,
      });
    } else {
      await c.rpc('admin_review_licence', params: {
        'p_licence_id': item.id,
        'p_approve': approve,
        'p_reason': reason,
      });
    }
  }
}

class SupabaseSellerRepository implements SellerRepository {
  SupabaseSellerRepository(this.c);
  final SupabaseClient c;

  static const _sellerCols = 'id, business_name, city, state, verification_status, early_partner, free_until, hidden, '
      'created_at, profiles(name, phone, email), seller_contacts(business_phone)';
  static const _entCols =
      'id, seller_id, store, provider, product_id, tier, status, credits_balance, renews_at, expires_at, raw, created_at';

  /// Strips PostgREST / LIKE syntax from free text.
  static String _clean(String q) => q.replaceAll(RegExp(r'[%_,()*\\]'), ' ').trim();

  SellerSummary _seller(Map<String, dynamic> r) {
    final p = r['profiles'] is Map ? Map<String, dynamic>.from(r['profiles'] as Map) : const <String, dynamic>{};
    final contacts = r['seller_contacts'];
    final ct = contacts is Map
        ? Map<String, dynamic>.from(contacts)
        : contacts is List && contacts.isNotEmpty
            ? Map<String, dynamic>.from(contacts.first as Map)
            : const <String, dynamic>{};
    return SellerSummary(
      id: r['id'] as String,
      businessName: r['business_name'] as String? ?? '?',
      ownerName: p['name'] as String?,
      phone: p['phone'] as String?,
      email: p['email'] as String?,
      businessPhone: ct['business_phone'] as String?,
      city: r['city'] as String?,
      state: r['state'] as String?,
      verificationStatus: r['verification_status'] as String? ?? 'unverified',
      earlyPartner: r['early_partner'] == true,
      freeUntil: _ts(r['free_until']),
      hidden: r['hidden'] == true,
      createdAt: _ts(r['created_at']),
    );
  }

  EntitlementRecord _ent(Map<String, dynamic> r) {
    final raw = r['raw'];
    return EntitlementRecord(
      id: r['id'] as String,
      sellerId: r['seller_id'] as String,
      store: r['store'] as String,
      provider: r['provider'] as String?,
      productId: r['product_id'] as String,
      tier: r['tier'] as String,
      status: r['status'] as String,
      creditsBalance: _int(r['credits_balance']) ?? 0,
      renewsAt: _ts(r['renews_at']),
      expiresAt: _ts(r['expires_at']),
      note: raw is Map ? raw['note']?.toString() : null,
      createdAt: _ts(r['created_at'])!,
    );
  }

  @override
  Future<List<SellerSummary>> search(String query) async {
    final digits = phoneDigits(query)?.replaceFirst(RegExp(r'^0+'), '');
    if (digits != null && digits.length >= 4) {
      final byProfile = await c.from('profiles').select('id').ilike('phone', '%$digits%').limit(50);
      final byContact =
          await c.from('seller_contacts').select('seller_id').ilike('business_phone', '%$digits%').limit(50);
      final ids = {
        for (final r in byProfile) r['id'] as String,
        for (final r in byContact) r['seller_id'] as String,
      };
      if (ids.isEmpty) return const [];
      final rows = await c.from('sellers').select(_sellerCols).inFilter('id', ids.toList()).order('business_name');
      return [for (final r in rows) _seller(r)];
    }
    final q = _clean(query);
    if (q.length < 2) return const [];
    final rows = await c.from('sellers').select(_sellerCols).ilike('business_name', '%$q%').order('business_name').limit(50);
    return [for (final r in rows) _seller(r)];
  }

  @override
  Future<SellerSummary> seller(String id) async =>
      _seller(await c.from('sellers').select(_sellerCols).eq('id', id).single());

  @override
  Future<List<EntitlementRecord>> entitlements(String sellerId) async {
    final rows =
        await c.from('entitlements').select(_entCols).eq('seller_id', sellerId).order('created_at', ascending: false);
    return [for (final r in rows) _ent(r)];
  }

  @override
  Future<List<EntitlementRecord>> grantsWithReference(String reference) async {
    // Coarse match on the note text (references are [A-Z0-9._/-] only; a `_`
    // just widens the LIKE), then an exact check on the parsed note.
    final rows = await c
        .from('entitlements')
        .select(_entCols)
        .eq('store', 'manual')
        .ilike('raw->>note', '%$reference%')
        .limit(20);
    return [
      for (final r in rows)
        if (_ent(r).manualPayment?['ref'] == reference) _ent(r),
    ];
  }

  @override
  Future<EntitlementRecord> grant(ManualPaymentGrant grant) async {
    final r = await c.rpc('admin_grant_entitlement', params: {
      'p_seller_id': grant.sellerId,
      'p_tier': grant.tier,
      'p_credits': grant.credits,
      'p_expires_at': grant.expiresAt?.toIso8601String(),
      'p_note': grant.note,
    });
    return _ent(Map<String, dynamic>.from(r as Map));
  }
}

class SupabaseModerationRepository implements ModerationRepository {
  SupabaseModerationRepository(this.c);
  final SupabaseClient c;

  static const _targets = {
    'request': ('requests', 'title', 'buyer_id'),
    'quote': ('quotes', 'notes', 'seller_id'),
    'message': ('messages', 'body', 'sender_id'),
    'review': ('reviews', 'text', 'from_id'),
    'seller': ('sellers', 'business_name', 'id'),
    'user': ('profiles', 'name', 'id'),
    'comment': ('request_comments', 'body', 'author_id'), // community feed
  };

  @override
  Future<List<ReportItem>> openReports() async {
    final rows = await c
        .from('reports')
        .select('id, reporter_id, target_type, target_id, reason, details, created_at')
        .eq('status', 'open')
        .order('created_at');
    final counts = <String, int>{};
    for (final r in rows) {
      final k = '${r['target_type']}:${r['target_id']}';
      counts[k] = (counts[k] ?? 0) + 1;
    }
    final seen = <String>{};
    final out = <ReportItem>[];
    for (final r in rows) {
      final type = r['target_type'] as String;
      final id = r['target_id'] as String;
      if (!seen.add('$type:$id')) continue;
      String? preview;
      String? owner;
      final t = _targets[type];
      if (t != null) {
        final row = await c.from(t.$1).select('${t.$2}, ${t.$3}').eq('id', id).maybeSingle();
        preview = row?[t.$2] as String?;
        owner = row?[t.$3] as String?;
      }
      out.add(ReportItem(
        id: r['id'] as String,
        targetType: type,
        targetId: id,
        reason: r['reason'] as String,
        details: r['details'] as String?,
        reporterId: r['reporter_id'] as String?,
        targetPreview: preview,
        targetOwnerId: owner,
        reportCount: counts['$type:$id'] ?? 1,
        createdAt: _ts(r['created_at'])!,
      ));
    }
    return out;
  }

  @override
  Future<int> resolve(String reportId, ReportAction action, {String? note}) async {
    final n = await c.rpc('admin_resolve_report', params: {
      'p_report_id': reportId,
      'p_action': action.name,
      'p_note': note,
    });
    return _int(n) ?? 0;
  }

  UserSummary _user(Map<String, dynamic> r) => UserSummary(
        id: r['id'] as String,
        name: r['name'] as String?,
        email: r['email'] as String?,
        phone: r['phone'] as String?,
        roles: ((r['roles'] as List?) ?? const []).cast<String>(),
        status: r['status'] as String? ?? 'active',
        suspendedUntil: _ts(r['suspended_until']),
        statusReason: r['status_reason'] as String?,
      );

  @override
  Future<List<UserSummary>> searchUsers(String query) async {
    const cols = 'id, name, email, phone, roles, status, suspended_until, status_reason';
    final q = query.trim().replaceAll(RegExp(r'[,()%*]'), ' ');
    final base = c.from('profiles').select(cols);
    final rows = q.isEmpty
        ? await base.order('created_at', ascending: false).limit(50)
        : await base.or('name.ilike.*$q*,email.ilike.*$q*,phone.ilike.*$q*').limit(50);
    return rows.map(_user).toList();
  }

  @override
  Future<UserSummary> setUserStatus(String userId, String status, {DateTime? until, String? reason}) async {
    final r = await c.rpc('admin_set_user_status', params: {
      'p_user_id': userId,
      'p_status': status,
      'p_until': until?.toUtc().toIso8601String(),
      'p_reason': reason,
    });
    return _user(Map<String, dynamic>.from(r as Map));
  }
}

class SupabaseAuditRepository implements AuditRepository {
  SupabaseAuditRepository(this.c);
  final SupabaseClient c;

  @override
  Future<List<AuditEntry>> recent({int limit = 200, String? targetType}) async {
    var q = c.from('admin_audit_log').select('id, actor_id, actor_email, action, target_type, target_id, details, created_at');
    if (targetType != null) q = q.eq('target_type', targetType);
    final rows = await q.order('created_at', ascending: false).limit(limit);
    return [
      for (final r in rows)
        AuditEntry(
          id: '${r['id']}',
          action: r['action'] as String,
          actorId: r['actor_id'] as String?,
          actorEmail: r['actor_email'] as String?,
          targetType: r['target_type'] as String?,
          targetId: r['target_id']?.toString(),
          details: Map<String, dynamic>.from((r['details'] as Map?) ?? const {}),
          createdAt: _ts(r['created_at'])!,
        ),
    ];
  }
}

class SupabaseCategoryRepository implements CategoryAdminRepository {
  SupabaseCategoryRepository(this.c);
  final SupabaseClient c;

  AdminCategory _cat(Map<String, dynamic> r) => AdminCategory(
        id: _int(r['id'])!,
        parentId: _int(r['parent_id']),
        slug: r['slug'] as String,
        names: _strMap(r['names']),
        policy: CategoryPolicy.values.byName(r['policy'] as String),
        requiredLicenceType: r['required_licence_type'] as String?,
        disclaimer: _strMap(r['disclaimer']),
        policyReason: _strMap(r['policy_reason']),
        active: r['active'] as bool? ?? true,
        sort: _int(r['sort']) ?? 0,
      );

  @override
  Future<List<AdminCategory>> list() async {
    final rows = await c
        .from('categories')
        .select('id, parent_id, slug, names, policy, required_licence_type, disclaimer, policy_reason, active, sort')
        .order('sort')
        .order('id');
    return rows.map(_cat).toList();
  }

  @override
  Future<AdminCategory> setPolicy(int categoryId, CategoryPolicy policy,
      {String? requiredLicenceType, Map<String, String>? disclaimer, Map<String, String>? policyReason}) async {
    final r = await c.rpc('admin_set_category_policy', params: {
      'p_category_id': categoryId,
      'p_policy': policy.name,
      'p_required_licence_type': requiredLicenceType,
      'p_disclaimer': disclaimer,
      'p_policy_reason': policyReason,
    });
    return _cat(Map<String, dynamic>.from(r as Map));
  }

  @override
  Future<AdminCategory> update(int categoryId, {Map<String, String>? names, bool? active}) async {
    final r = await c.rpc('admin_upsert_category', params: {
      'p_id': categoryId,
      'p_slug': null,
      'p_names': names,
      'p_active': active,
    });
    return _cat(Map<String, dynamic>.from(r as Map));
  }
}

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this.c);
  final SupabaseClient c;

  AppSetting _s(Map<String, dynamic> r) => AppSetting(
        key: r['key'] as String,
        value: r['value'],
        description: r['description'] as String?,
        isPublic: r['is_public'] as bool? ?? false,
      );

  @override
  Future<List<AppSetting>> list() async {
    final rows = await c.rpc('admin_get_settings') as List;
    return rows.map((r) => _s(Map<String, dynamic>.from(r as Map))).toList();
  }

  @override
  Future<AppSetting> set(String key, Object? value) async {
    final r = await c.rpc('admin_set_setting', params: {'p_key': key, 'p_value': value});
    return _s(Map<String, dynamic>.from(r as Map));
  }
}

class SupabaseBrochureRepository implements BrochureRepository {
  SupabaseBrochureRepository(this.c, this.config);
  final SupabaseClient c;
  final AdminCountryConfig config;

  BrochureRecord _b(Map<String, dynamic> r) => BrochureRecord(
        id: r['id'] as String,
        cityName: r['city_name'] as String,
        state: r['state'] as String?,
        categoryId: _int(r['category_id']),
        language: r['language'] as String,
        format: r['format'] as String,
        storagePath: r['storage_path'] as String,
        publicUrl: r['public_url'] as String?,
        signupUrl: r['signup_url'] as String?,
        version: _int(r['version']) ?? 1,
        createdAt: _ts(r['created_at'])!,
      );

  @override
  Future<List<BrochureRecord>> list() async {
    final rows = await c.from('brochures').select().order('created_at', ascending: false).limit(200);
    return rows.map(_b).toList();
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
    var q = c.from('brochures').count().eq('city_name', cityName).eq('language', language).eq('format', format);
    q = categoryId == null ? q.isFilter('category_id', null) : q.eq('category_id', categoryId);
    final version = (await q) + 1;
    final slug = cityName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final ext = format == 'image' ? 'png' : 'pdf';
    final path = '${config.countryCode.toLowerCase()}/$slug/$categorySlug/$language/$format-v$version.$ext';
    final bucket = c.storage.from('brochures');
    await bucket.uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(contentType: ext == 'png' ? 'image/png' : 'application/pdf', upsert: false),
    );
    final row = await c
        .from('brochures')
        .insert({
          'city_name': cityName,
          'state': state,
          'category_id': categoryId,
          'language': language,
          'format': format,
          'storage_path': path,
          'public_url': bucket.getPublicUrl(path),
          'signup_url': signupUrl,
          'utm': utm,
          'version': version,
        })
        .select()
        .single();
    return _b(row);
  }
}

class SupabaseOutreachRepository implements OutreachRepository {
  SupabaseOutreachRepository(this.c);
  final SupabaseClient c;

  static const _leadCols = 'id, business_key, business_name, categories_source, matched_category_ids, email, email_domain, '
      'email_status, address_source, phone, website, website_domain, place_id, osm_id, address, city, state, '
      'postal_code, timezone, rating, rating_count, source, source_ref, lawful_basis, chosen_reason, stage, owner_id, '
      'next_action, next_action_due, notes, priority, campaign_id, sequence_status, touches_sent, contacted_at, '
      'last_contacted_at, remind_after, whatsapp_opt_in_at, whatsapp_opt_in_channel, whatsapp_opt_in_proof, '
      'whatsapp_last_marketing_at, signup_token, unsubscribe_token, seller_id, created_at';

  @override
  Future<List<OutreachLead>> leads(LeadFilter f) async {
    var q = c.from('outreach_leads').select(_leadCols);
    if (f.state != null) q = q.eq('state', f.state!);
    if (f.city != null) q = q.eq('city', f.city!);
    if (f.categoryId != null) q = q.contains('matched_category_ids', [f.categoryId]);
    if (f.source != null) q = q.eq('source', f.source!.name);
    final text = f.query?.trim().replaceAll(RegExp(r'[,()%*]'), ' ');
    if (text != null && text.isNotEmpty) {
      q = q.or('business_name.ilike.*$text*,email.ilike.*$text*,phone.ilike.*$text*');
    }
    final rows = await q.order('priority', nullsFirst: false).order('created_at').limit(1000);
    return rows.map(OutreachLead.fromJson).toList();
  }

  @override
  Future<OutreachLead> lead(String id) async =>
      OutreachLead.fromJson(await c.from('outreach_leads').select(_leadCols).eq('id', id).single());

  @override
  Future<List<OutreachEvent>> events(String leadId) async {
    final rows = await c
        .from('outreach_events')
        .select('id, lead_id, campaign_id, inbox_id, channel, event_type, sequence_step, template_variant, subject, '
            'body_preview, recipient, reason_chosen, address_source, lawful_basis, meta, created_by, created_at')
        .eq('lead_id', leadId)
        .order('created_at', ascending: false);
    return rows.map(OutreachEvent.fromJson).toList();
  }

  @override
  Future<OutreachLead> moveStage(OutreachLead lead, LeadStage to, TransitionResult result, {String? note}) async {
    if (!result.allowed) throw StateError('transition_refused');
    // Atomic server-side move (supabase/migrations/20261002001020_outreach_safety.sql):
    // the RPC re-applies the same forward-only rules as StageMachine, stops the
    // sequence, adds do-not-contact leads to suppression_list, records the
    // stage_change event and writes the audit log in one transaction.
    await c.rpc('admin_outreach_set_stage', params: {'p_lead_id': lead.id, 'p_stage': to.wire, 'p_note': note});
    return this.lead(lead.id);
  }

  @override
  Future<OutreachLead> updateLead(String id,
      {String? notes, String? nextAction, DateTime? nextActionDue, bool clearNextAction = false}) async {
    await c.from('outreach_leads').update({
      'notes': ?notes,
      if (clearNextAction) ...{'next_action': null, 'next_action_due': null} else ...{
        'next_action': ?nextAction,
        if (nextActionDue != null) 'next_action_due': nextActionDue.toIso8601String().split('T').first,
      },
    }).eq('id', id);
    return lead(id);
  }

  @override
  Future<void> logContact(String leadId, ManualContact kind, String text) async {
    await c.from('outreach_events').insert({
      'lead_id': leadId,
      'channel': kind.channel,
      'event_type': kind.eventType,
      'body_preview': text.length > 500 ? text.substring(0, 500) : text,
      'created_by': c.auth.currentUser?.id,
    });
  }

  @override
  Future<OutreachLead> recordOptIn(String leadId, {required String channel, required String proof}) async {
    await c.from('outreach_leads').update({
      'whatsapp_opt_in_at': DateTime.now().toUtc().toIso8601String(),
      'whatsapp_opt_in_channel': channel,
      'whatsapp_opt_in_proof': proof,
    }).eq('id', leadId);
    await logContact(leadId, ManualContact.note, 'Opt-in recorded ($channel): $proof');
    return lead(leadId);
  }

  @override
  Future<void> enrol(List<String> leadIds, String campaignId) async {
    if (leadIds.isEmpty) return;
    await c
        .from('outreach_leads')
        .update({'campaign_id': campaignId})
        .inFilter('id', leadIds)
        .inFilter('sequence_status', ['none', 'active']);
  }

  @override
  Future<ImportResult> importLeads(List<LeadDraft> drafts) async {
    var inserted = 0;
    var dupes = 0;
    final rejected = <String>[];
    for (final d in drafts) {
      try {
        final id = await c.rpc('outreach_upsert_lead', params: {'p_lead': d.toRpcJson()});
        id == null ? dupes++ : inserted++;
      } on PostgrestException catch (e) {
        rejected.add('${d.businessName}: ${e.message}');
      }
    }
    return ImportResult(inserted: inserted, duplicates: dupes, rejected: rejected);
  }

  @override
  Future<List<SuppressionEntry>> suppression() async {
    final rows = await c
        .from('suppression_list')
        .select('id, email, email_domain, phone, business_key, reason, source, note, created_at')
        .order('created_at', ascending: false)
        .limit(1000);
    return rows.map(SuppressionEntry.fromJson).toList();
  }

  @override
  Future<void> suppress(
      {String? email, String? emailDomain, String? phone, String? businessKey, required String reason, String? note}) async {
    await c.from('suppression_list').insert({
      'email': email?.toLowerCase(),
      'email_domain': emailDomain?.toLowerCase(),
      'phone': phone,
      'business_key': businessKey,
      'reason': reason,
      'source': 'admin',
      'note': note,
    });
  }

  @override
  Future<bool> isSuppressed(OutreachLead lead) async {
    final r = await c.rpc('outreach_is_suppressed', params: {
      'p_email': lead.email,
      'p_phone': lead.phone,
      'p_business_key': lead.businessKey,
    });
    return r == true;
  }

  @override
  Future<List<OutreachCampaign>> campaigns() async {
    final rows = await c
        .from('outreach_campaigns')
        .select('id, name, sequence_id, status, category_ids, states, inbox_ids, daily_cap, paused_reason, paused_at')
        .order('created_at', ascending: false);
    return rows.map(OutreachCampaign.fromJson).toList();
  }

  @override
  Future<void> setCampaignStatus(String campaignId, String status) async {
    await c.from('outreach_campaigns').update({
      'status': status,
      'paused_reason': status == 'paused' ? 'manual' : null,
      'paused_at': status == 'paused' ? DateTime.now().toUtc().toIso8601String() : null,
    }).eq('id', campaignId);
  }

  @override
  Future<List<OutreachSequence>> sequences() async {
    final rows = await c.from('outreach_sequences').select('id, name, channel, language, steps');
    return rows.map(OutreachSequence.fromJson).toList();
  }

  @override
  Future<List<OutreachInbox>> inboxes() async {
    final rows = await c
        .from('outreach_inboxes')
        .select('id, email, display_name, provider, daily_cap_start, daily_cap_max, ramp_per_week, warmup_started_on, active');
    return rows.map(OutreachInbox.fromJson).toList();
  }

  @override
  Future<SendStats> sendStats() async {
    final settings = {
      for (final r in await c.rpc('admin_get_settings') as List) (r as Map)['key'] as String: r['value'],
    };
    num n(String k, num d) => settings[k] is num ? settings[k] as num : num.tryParse('${settings[k]}') ?? d;
    final dayStart = DateTime.now().toUtc();
    final since = DateTime.utc(dayStart.year, dayStart.month, dayStart.day).toIso8601String();
    final sent = await c
        .from('outreach_events')
        .select('campaign_id, inbox_id, recipient_domain')
        .eq('event_type', 'sent')
        .gte('created_at', since);
    final byDomain = <String, int>{};
    final byCampaign = <String, int>{};
    final byInbox = <String, int>{};
    for (final e in sent) {
      void inc(Map<String, int> m, Object? k) {
        if (k != null) m['$k'] = (m['$k'] ?? 0) + 1;
      }

      inc(byDomain, e['recipient_domain']);
      inc(byCampaign, e['campaign_id']);
      inc(byInbox, e['inbox_id']);
    }
    final since30 = DateTime.now().toUtc().subtract(const Duration(days: 30)).toIso8601String();
    final recent = await c
        .from('outreach_events')
        .select('campaign_id, event_type')
        .inFilter('event_type', ['sent', 'bounced', 'complained', 'negative_reply'])
        .gte('created_at', since30)
        .not('campaign_id', 'is', null);
    final counts = <String, Map<String, int>>{};
    for (final e in recent) {
      final m = counts.putIfAbsent(e['campaign_id'] as String, () => {});
      m[e['event_type'] as String] = (m[e['event_type'] as String] ?? 0) + 1;
    }
    return SendStats(
      outreachEnabled: settings['outreach_enabled'] == true,
      globalDailyCap: n('outreach_global_daily_cap', 50).toInt(),
      perDomainDailyCap: n('outreach_per_domain_daily_cap', 2).toInt(),
      sentTodayGlobal: sent.length,
      sentTodayByDomain: byDomain,
      sentTodayByCampaign: byCampaign,
      sentTodayByInbox: byInbox,
      bounceBrakePct: n('outreach_bounce_brake_pct', 2).toDouble(),
      complaintBrakePct: n('outreach_complaint_brake_pct', 0.08).toDouble(),
      negativeBrakePct: n('outreach_negative_brake_pct', 5).toDouble(),
      campaignHealth: {
        for (final e in counts.entries)
          e.key: CampaignHealth(
            sent: e.value['sent'] ?? 0,
            bounced: e.value['bounced'] ?? 0,
            complained: e.value['complained'] ?? 0,
            negative: e.value['negative_reply'] ?? 0,
          ),
      },
      businessAddress: settings['outreach_business_address'] is String ? settings['outreach_business_address'] as String : '',
    );
  }

  @override
  Future<List<CoverageCell>> coverage({int minSellers = 5}) async {
    final rows = await c.rpc('admin_seller_coverage', params: {'p_min_sellers': minSellers}) as List;
    return [
      for (final r in rows.cast<Map>())
        CoverageCell(
          city: r['city'] as String,
          state: r['state'] as String?,
          categoryId: _int(r['category_id'])!,
          sellers: _int(r['sellers'])!,
          needsSellers: r['needs_sellers'] == true,
        ),
    ];
  }

  @override
  Future<ServerGate> serverCanSend(String leadId, String channel, String? inboxId) async {
    final rows = await c.rpc('outreach_can_send', params: {
      'p_lead_id': leadId,
      'p_channel': channel,
      'p_inbox_id': inboxId,
    }) as List;
    if (rows.isEmpty) return const ServerGate(false, 'no_answer');
    final r = rows.first as Map;
    return ServerGate(r['allowed'] == true, '${r['reason']}');
  }

  @override
  Future<SendResult> send(OutreachLead lead, OutreachMessage message) async {
    try {
      // `send_one`: one admin-confirmed send (see BACKEND_NEEDS.md). The
      // function re-runs the content rules and outreach_can_send, builds the
      // authoritative identity footer and List-Unsubscribe headers, sends via
      // the provider and records it with outreach_record_send.
      final res = await c.functions.invoke('outreach-send', body: {
        'action': 'send_one',
        'lead_id': lead.id,
        'campaign_id': lead.campaignId,
        'inbox_id': message.inboxId,
        'channel': message.channel,
        'step': message.step,
        'variant': message.variantIndex,
        'category_id': message.categoryId,
        'subject': message.subject,
        'body': message.body,
        'footer': message.footer,
        'whatsapp_template': message.whatsappTemplate,
        'confirmed_by_admin': message.confirmedByAdmin,
      });
      final data = res.data is Map ? Map<String, dynamic>.from(res.data as Map) : const <String, dynamic>{};
      return SendResult(ok: data['ok'] == true, eventId: data['event_id'] as String?, reason: data['reason'] as String?);
    } on FunctionException catch (e) {
      final d = e.details;
      return SendResult(ok: false, reason: d is Map ? '${d['reason'] ?? d['error'] ?? e.status}' : 'http_${e.status}');
    }
  }
}
