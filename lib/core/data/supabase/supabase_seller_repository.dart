import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/seller/domain/lead.dart';
import '../../../features/seller/domain/seller.dart';
import '../../../features/seller/domain/seller_repository.dart';
import '../../money/money.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// Seller profile (`get_my_seller_profile`, `upsert_seller_profile`),
/// verification documents, licences and quote templates.
class SupabaseSellerRepository implements SellerRepository {
  SupabaseSellerRepository(this.ctx);
  final SupabaseContext ctx;

  Future<Seller?> _fetchMine() async {
    if (ctx.uidOrNull == null) return null;
    final row = await ctx.client.rpc<dynamic>('get_my_seller_profile');
    if (row is! Map) return null;
    return mapSeller(Map<String, dynamic>.from(row));
  }

  @override
  Stream<Seller?> watchMySeller() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(null);
    return ctx.liveQuery(name: 'seller:$uid', fetch: _fetchMine, topics: {Topics.seller});
  }

  @override
  Future<Seller> upsertSeller(Seller seller, {String? logoPath, List<String> newPhotoPaths = const []}) async {
    final uid = ctx.uid;
    Future<String> publicUpload(String local, String prefix) async => ctx.publicUrl(
      Buckets.sellerMedia,
      await ctx.upload(Buckets.sellerMedia, (ext) => '$uid/$prefix-${ctx.newId()}.$ext', local),
    );

    return guardState(() async {
      String? logoUrl = seller.logoUrl;
      if (logoPath != null) {
        logoUrl = SupabaseContext.isLocalPath(logoPath) ? await publicUpload(logoPath, 'logo') : logoPath;
      }
      final photos = [
        ...seller.photos,
        for (final p in newPhotoPaths) SupabaseContext.isLocalPath(p) ? await publicUpload(p, 'photo') : p,
      ];
      final existed = await ctx.client.from('sellers').select('id').eq('id', uid).maybeSingle() != null;
      await ctx.client.rpc<dynamic>(
        'upsert_seller_profile',
        params: {
          'p_business_name': seller.businessName.trim(),
          'p_description': seller.description,
          'p_years_in_business': seller.yearsInBusiness,
          'p_brands': seller.brands,
          'p_area_type': seller.areaType.name,
          'p_lat': seller.lat,
          'p_lng': seller.lng,
          'p_radius_km': seller.areaType == AreaType.radius ? seller.radiusKm : null,
          'p_service_codes': seller.serviceCodes,
          'p_category_ids': seller.categoryIds,
          'p_logo_url': logoUrl,
          'p_photos': photos,
          'p_city': seller.locality,
          'p_state': seller.state,
          'p_notify_mode': notifyModeJson(seller.notifyPreference),
          'p_quiet_hours_start': formatHour(seller.quietStartHour),
          'p_quiet_hours_end': formatHour(seller.quietEndHour),
          'p_business_phone': seller.phone,
        },
      );
      if (!existed) {
        // New seller role: refresh so the JWT carries it.
        try {
          await ctx.client.auth.refreshSession();
        } catch (e) {
          debugPrint('refreshSession: $e');
        }
      }
      ctx.changed(Topics.seller);
      final saved = await _fetchMine();
      if (saved == null) throw StateError('seller_not_found');
      return saved;
    });
  }

  @override
  Future<Seller?> getSeller(String id) async {
    if (id == ctx.uidOrNull) return _fetchMine();
    final row = await ctx.client.from('sellers').select('*, seller_categories(category_id)').eq('id', id).maybeSingle();
    return row == null ? null : mapSeller(row);
  }

  @override
  Future<SellerStats> stats() async {
    final uid = ctx.uid;
    final quotes = await ctx.client.from('quotes').select('status, created_at').eq('seller_id', uid);
    final orders = await ctx.client
        .from('orders')
        .select('payment_amount_minor, currency')
        .eq('seller_id', uid)
        .not('payment_amount_minor', 'is', null);
    final me = await _fetchMine();
    final statuses = [for (final q in quotes) q['status'] as String?];
    const active = {'sent', 'revised', 'shortlisted'};
    final won = statuses.where((s) => s == 'accepted').length;
    final lost = statuses.where((s) => s == 'declined' || s == 'expired').length;
    final now = DateTime.now();
    final revenue = MoneyX.sum([
      for (final o in orders) moneyOrZero(o['payment_amount_minor'], currencyOf(o, ctx.currency)),
    ], ctx.currency);
    return SellerStats(
      activeQuotes: statuses.where(active.contains).length,
      won: won,
      lost: lost,
      winRate: statuses.isEmpty ? 0 : won / statuses.length,
      avgResponseMins: me?.avgResponseMins,
      revenueLogged: revenue,
      ratingAvg: me?.ratingAvg ?? 0,
      ratingCount: me?.ratingCount ?? 0,
      quotesThisMonth: quotes.where((q) {
        final t = parseTimestamp(q['created_at']);
        return t != null && t.year == now.year && t.month == now.month;
      }).length,
    );
  }

  // ----------------------------------------------------------- verification

  @override
  Future<List<SellerDocument>> myDocuments() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const [];
    final rows = await ctx.client
        .from('seller_documents')
        .select()
        .eq('seller_id', uid)
        .order('created_at', ascending: false);
    // Latest submission per document type.
    final byType = <String, SellerDocument>{};
    for (final r in rows) {
      byType.putIfAbsent(r['doc_type'].toString(), () => mapSellerDocument(r));
    }
    return byType.values.toList();
  }

  Future<String?> _docUpload(String? filePath, String prefix) async {
    if (filePath == null) return null;
    if (!SupabaseContext.isLocalPath(filePath)) return filePath;
    final uid = ctx.uid;
    return ctx.upload(Buckets.verificationDocs, (ext) => '$uid/$prefix-${ctx.newId()}.$ext', filePath);
  }

  @override
  Future<void> submitDocument(String docType, {String? number, String? filePath}) => guardState(() async {
    final path = await _docUpload(filePath, docType);
    await ctx.client.rpc<dynamic>(
      'submit_verification',
      params: {'p_doc_type': docType, 'p_doc_number': number, 'p_file_path': path},
    );
    ctx.changed(Topics.seller);
  });

  @override
  Future<List<SellerLicence>> myLicences() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const [];
    final rows = await ctx.client
        .from('seller_licences')
        .select()
        .eq('seller_id', uid)
        .order('created_at', ascending: false);
    return [for (final r in rows) mapSellerLicence(r)];
  }

  @override
  Future<void> submitLicence(SellerLicence licence, {String? filePath}) => guardState(() async {
    final path = await _docUpload(filePath, 'licence');
    await ctx.client.rpc<dynamic>(
      'submit_licence',
      params: {
        'p_licence_type': licence.licenceType,
        'p_number': licence.number,
        'p_issuer': (licence.issuer ?? '').isEmpty ? null : licence.issuer,
        'p_state': licence.state,
        'p_category_ids': licence.categoryIds,
        'p_expires_at': licence.expiresAt?.toUtc().toIso8601String(),
        'p_file_path': path,
      },
    );
    ctx.changed(Topics.seller);
  });

  // -------------------------------------------------------------- templates

  @override
  Future<List<QuoteTemplate>> templates() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const [];
    final rows = await ctx.client.from('quote_templates').select().eq('seller_id', uid).order('name');
    return [for (final r in rows) mapQuoteTemplate(r)];
  }

  static final _uuidRe = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<void> saveTemplate(QuoteTemplate template) => guardState(() async {
    final uid = ctx.uid;
    final row = <String, Object?>{'seller_id': uid, 'name': template.name, 'payload': template.payload};
    if (_uuidRe.hasMatch(template.id)) {
      row['id'] = template.id;
      await ctx.client.from('quote_templates').upsert(row);
    } else {
      // Client-made ids (the form uses a timestamp): one template per name.
      await ctx.client.from('quote_templates').upsert(row, onConflict: 'seller_id,name');
    }
  });

  @override
  Future<void> deleteTemplate(String id) => guardState(() async {
    await ctx.client.from('quote_templates').delete().eq('id', id).eq('seller_id', ctx.uid);
  });
}

/// Lead feed (`get_lead_feed`), lead detail (`get_request_for_seller`) and
/// the `seller:{seller_id}` broadcast for new leads.
class SupabaseLeadRepository implements LeadRepository {
  SupabaseLeadRepository(this.ctx);
  final SupabaseContext ctx;

  static const pageSize = 20;
  static const _kind = 'lead';

  @override
  Future<LeadPage> feed(LeadFilters filters, {String? cursor}) async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const LeadPage(leads: []);
    final filtersJson = leadFiltersJson(filters);
    final scope = '$uid:${jsonEncode(filtersJson)}';
    List<JsonRow> rows;
    try {
      rows = await ctx.rpcList('get_lead_feed', {
        'p_filters': filtersJson,
        'p_cursor': cursor == null ? null : jsonDecode(cursor),
        'p_limit': pageSize,
      });
      if (cursor == null) {
        unawaited(
          ctx.cache
              ?.putRows(
                _kind,
                {for (final r in rows) r['request_id'].toString(): jsonEncode(r)},
                scope: scope,
                replaceScope: true,
              )
              .catchError((_) {}),
        );
      }
    } catch (e) {
      // Offline: the first page comes from the device cache.
      final cached = cursor == null && isNetworkError(e) ? await ctx.cache?.rowsInScope(_kind, scope) : null;
      if (cached == null || cached.isEmpty) {
        if (serverErrorCode(e) == 'not_a_seller') return const LeadPage(leads: []);
        throw toStateError(e);
      }
      rows = [for (final r in cached) Map<String, dynamic>.from(jsonDecode(r) as Map)];
      return LeadPage(leads: [for (final r in rows) mapLeadFeedRow(r, fallbackCurrency: ctx.currency)]);
    }
    return LeadPage(
      leads: [for (final r in rows) mapLeadFeedRow(r, fallbackCurrency: ctx.currency)],
      nextCursor: rows.length < pageSize ? null : leadCursor(rows.last),
    );
  }

  @override
  Future<Lead?> lead(String requestId) async {
    final JsonRow? row;
    try {
      row = await ctx.rpcRow('get_request_for_seller', {'p_request_id': requestId});
    } catch (e) {
      if (serverErrorCode(e) == 'request_not_found') return null;
      throw toStateError(e);
    }
    if (row == null) return null;
    String? firstName;
    final buyerId = row['buyer_id']?.toString();
    if (buyerId != null) {
      try {
        final p = (await ctx.publicProfiles([buyerId]))[buyerId];
        firstName = p?['display_name']?.toString().split(' ').first;
      } catch (_) {}
    }
    final l = mapLeadDetail(row, fallbackCurrency: ctx.currency, buyerFirstName: firstName);
    if (l.media.isEmpty) return l;
    final urls = await ctx.signedUrls(Buckets.requestMedia, l.media.map((m) => m.path));
    return l.copyWith(media: [for (final m in l.media) m.copyWith(url: urls[m.path])]);
  }

  @override
  Future<void> dismiss(String requestId) =>
      guardState(() => ctx.client.rpc<dynamic>('dismiss_lead', params: {'p_request_id': requestId, 'p_dismiss': true}));

  @override
  Future<void> markSeen(String requestId) => guardState(
    () => ctx.client.rpc<dynamic>(
      'mark_leads_seen',
      params: {
        'p_request_ids': [requestId],
      },
    ),
  );

  // One shared broadcast subscription however many screens listen.
  StreamController<void>? _signals;
  RealtimeChannel? _channel;

  /// Broadcast channel `seller:{seller_id}`, event `new_lead` (ids only).
  @override
  Stream<void> newLeadSignals() {
    final uid = ctx.uidOrNull;
    if (uid == null) return const Stream.empty();
    _signals ??= StreamController<void>.broadcast(
      onListen: () {
        try {
          _channel = ctx.client
              .channel('seller:$uid', opts: const RealtimeChannelConfig(private: false))
              .onBroadcast(event: 'new_lead', callback: (_) => _signals?.add(null))
              .subscribe();
        } catch (e) {
          debugPrint('lead channel: $e');
        }
      },
      onCancel: () async {
        final ch = _channel;
        _channel = null;
        final s = _signals;
        _signals = null;
        if (ch != null) {
          try {
            await ctx.client.removeChannel(ch);
          } catch (_) {}
        }
        await s?.close();
      },
    );
    return _signals!.stream;
  }
}
