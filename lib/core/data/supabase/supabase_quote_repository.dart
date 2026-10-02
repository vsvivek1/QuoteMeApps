import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../features/quotes/domain/quote.dart';
import '../../../features/quotes/domain/quote_repository.dart';
import '../../config/country_config.dart';
import '../../money/money.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// Quotes: buyer reads directly (RLS), seller and buyer actions through the
/// quote RPCs, Realtime on `quotes`.
class SupabaseQuoteRepository implements QuoteRepository {
  SupabaseQuoteRepository(this.ctx);
  final SupabaseContext ctx;

  static const select =
      '*, quote_line_items(*), '
      'seller:sellers(id, business_name, logo_url, rating_avg, rating_count, verification_status, '
      'avg_response_mins, early_partner)';
  static const _kind = 'quote';

  bool get _gst => ctx.config.country == Country.india;

  Quote _map(JsonRow row) => mapQuote(row, fallbackCurrency: ctx.currency);

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on QuoteFailure {
      rethrow;
    } catch (e) {
      throw toQuoteFailure(e);
    }
  }

  Future<Set<String>> _blocked() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return const {};
    try {
      final rows = await ctx.client.from('blocks').select('blocked_id').eq('blocker_id', uid);
      return {for (final r in rows) r['blocked_id'].toString()};
    } catch (_) {
      return const {};
    }
  }

  @override
  Stream<List<Quote>> watchQuotesForRequest(String requestId) {
    Future<List<JsonRow>> fetch() async {
      final rows = await ctx.client
          .from('quotes')
          .select(select)
          .eq('request_id', requestId)
          .eq('hidden', false)
          .order('created_at');
      final blocked = await _blocked();
      return [
        for (final r in rows)
          if (!blocked.contains(r['seller_id'])) r,
      ];
    }

    final live = ctx.liveQuery<List<JsonRow>>(
      name: 'quotes:$requestId',
      fetch: fetch,
      bind: ctx.onTable('quotes', column: 'request_id', equals: requestId),
      topics: {Topics.quotes},
    );
    return ctx.cachedRows(kind: _kind, scope: requestId, live: live).map((rows) => [for (final r in rows) _map(r)]);
  }

  @override
  Future<Quote?> getQuote(String quoteId) async {
    final row = await ctx.client.from('quotes').select(select).eq('id', quoteId).maybeSingle();
    return row == null ? null : _map(row);
  }

  Future<List<String>> _uploadAttachments(String requestId, List<String> paths) async {
    final sellerId = ctx.uid;
    final out = <String>[];
    for (final p in paths) {
      if (!SupabaseContext.isLocalPath(p)) {
        out.add(p);
        continue;
      }
      out.add(await ctx.upload(Buckets.requestMedia, (ext) => '$requestId/quotes/$sellerId/${ctx.newId()}.$ext', p));
    }
    return out;
  }

  Map<String, dynamic> _params(QuoteDraft d, List<String> attachments) => {
    'p_line_items': quoteLineItemsJson(d, gst: _gst),
    'p_delivery_minor': d.delivery.minorInt,
    'p_sales_tax_rate_bp': _gst ? 0 : d.taxRateBp,
    'p_offered_brand_model': d.offeredBrandModel,
    'p_delivery_date': d.deliveryDate == null ? null : formatDate(d.deliveryDate!),
    'p_warranty': d.warranty,
    'p_valid_days': d.validDays,
    'p_notes': d.notes,
    'p_attachments': attachments,
  };

  Future<Quote> _reload(JsonRow? row) async {
    final id = row?['id']?.toString();
    if (id == null) throw const QuoteFailure('unknown');
    ctx.changed(Topics.quotes);
    return await getQuote(id) ?? _map(row!);
  }

  @override
  Future<Quote> submitQuote(QuoteDraft draft) => _guard(() async {
    final attachments = await _uploadAttachments(draft.requestId, draft.attachmentPaths);
    final row = await ctx.rpcRow('submit_quote', {'p_request_id': draft.requestId, ..._params(draft, attachments)});
    return _reload(row);
  });

  @override
  Future<Quote> reviseQuote(String quoteId, QuoteDraft draft) => _guard(() async {
    final attachments = await _uploadAttachments(draft.requestId, draft.attachmentPaths);
    final params = {'p_quote_id': quoteId, ..._params(draft, attachments)};
    if (attachments.isEmpty) params.remove('p_attachments'); // null keeps the current files
    final row = await ctx.rpcRow('revise_quote', params);
    return _reload(row);
  });

  @override
  Future<void> withdrawQuote(String quoteId) => _guard(() async {
    await ctx.client.rpc<dynamic>('withdraw_quote', params: {'p_quote_id': quoteId});
    ctx.changed(Topics.quotes);
  });

  /// Seller "My quotes" via `get_my_quotes` (safe request summary included).
  @override
  Stream<List<Quote>> watchMyQuotes(String bucket) {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(const []);
    Future<List<Quote>> fetch() async {
      final rows = await ctx.rpcList('get_my_quotes', {'p_tab': bucket, 'p_limit': 50});
      final me = await ctx.client
          .from('sellers')
          .select(
            'id, business_name, logo_url, rating_avg, rating_count, verification_status, '
            'avg_response_mins, early_partner',
          )
          .eq('id', uid)
          .maybeSingle();
      final summary = mapSellerSummary(me, uid);
      return [
        for (final r in rows)
          if (r['quote'] is Map)
            mapQuote(Map<String, dynamic>.from(r['quote'] as Map), fallbackCurrency: ctx.currency, seller: summary),
      ];
    }

    return ctx.liveQuery(
      name: 'myquotes:$uid:$bucket',
      fetch: fetch,
      bind: ctx.onTable('quotes', column: 'seller_id', equals: uid),
      topics: {Topics.quotes},
    );
  }

  @override
  Future<String> acceptQuote(String quoteId) => _guard(() async {
    final order = await ctx.rpcRow('accept_quote', {'p_quote_id': quoteId});
    ctx
      ..changed(Topics.quotes)
      ..changed(Topics.requests)
      ..changed(Topics.orders)
      ..changed(Topics.chats);
    final id = order?['id']?.toString();
    if (id == null) throw const QuoteFailure('unknown');
    return id;
  });

  @override
  Future<void> declineQuote(String quoteId, {String? reason}) => _guard(() async {
    await ctx.client.rpc<dynamic>('decline_quote', params: {'p_quote_id': quoteId, 'p_reason': reason});
    ctx.changed(Topics.quotes);
  });

  @override
  Future<void> setShortlisted(String quoteId, bool shortlisted) => _guard(() async {
    await ctx.client.rpc<dynamic>('shortlist', params: {'p_quote_id': quoteId, 'p_on': shortlisted});
    ctx.changed(Topics.quotes);
  });

  @override
  Future<void> counterOffer(String quoteId, Money target, {String? note}) => _guard(() async {
    await ctx.client.rpc<dynamic>(
      'counter_offer',
      params: {'p_quote_id': quoteId, 'p_target_minor': target.minorInt, 'p_note': note},
    );
    ctx.changed(Topics.quotes);
  });

  /// The backend has no "viewed by buyer" state yet (API.md has no column or
  /// RPC for it), so this is a no-op.
  @override
  Future<void> markViewed(String quoteId) async {
    if (kDebugMode) debugPrint('markViewed($quoteId): not tracked by the backend');
  }
}
