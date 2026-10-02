import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/requests/domain/buyer_request.dart';
import '../../../features/requests/domain/category.dart';
import '../../../features/requests/domain/request_repository.dart';
import '../../demo/demo_repositories.dart' show suggestCategories;
import '../../money/money.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// `categories` (cached on device) and the server keyword classifier.
class SupabaseCategoryRepository implements CategoryRepository {
  SupabaseCategoryRepository(this.ctx);
  final SupabaseContext ctx;

  List<Category>? _all;
  DateTime? _loadedAt;
  String? _lastText;
  Future<List<JsonRow>>? _lastClassify;

  static const _kind = 'category';
  static const _ttl = Duration(hours: 6);

  @override
  Future<List<Category>> fetchAll({bool forceRefresh = false}) async {
    final fresh = _loadedAt != null && DateTime.now().difference(_loadedAt!) < _ttl;
    if (!forceRefresh && _all != null && fresh) return _all!;
    try {
      final rows = await ctx.client.from('categories').select().eq('active', true).order('sort').order('id');
      _all = [for (final r in rows) mapCategory(r)];
      _loadedAt = DateTime.now();
      unawaited(
        ctx.cache
            ?.putRows(_kind, {for (final r in rows) r['id'].toString(): jsonEncode(r)}, replaceScope: true)
            .catchError((_) {}),
      );
      return _all!;
    } catch (e) {
      if (_all != null) return _all!;
      final cached = await ctx.cache?.rowsInScope(_kind, '') ?? const [];
      if (cached.isEmpty) rethrow;
      return _all = [for (final r in cached) mapCategory(Map<String, dynamic>.from(jsonDecode(r) as Map))];
    }
  }

  /// One `classify_request_text` call per distinct text (suggest and
  /// blockedMatch run back to back on every keystroke).
  Future<List<JsonRow>> _classify(String text) {
    if (_lastText == text && _lastClassify != null) return _lastClassify!;
    _lastText = text;
    return _lastClassify = ctx.rpcList('classify_request_text', {'p_text': text, 'p_limit': 5});
  }

  @override
  Future<List<Category>> suggest(String text) async {
    if (text.trim().isEmpty) return const [];
    final all = await fetchAll();
    try {
      final byId = {for (final c in all) c.id: c};
      final rows = await _classify(text);
      return [
        for (final r in rows)
          if (r['blocked'] != true && byId[asInt(r['category_id'])] != null) byId[asInt(r['category_id'])]!,
      ];
    } catch (e) {
      debugPrint('classify: $e');
      return suggestCategories(all, text); // offline: local keywords
    }
  }

  @override
  Future<Category?> blockedMatch(String text) async {
    if (text.trim().isEmpty) return null;
    final all = await fetchAll();
    try {
      final rows = await _classify(text);
      final hit = rows.where((r) => r['blocked'] == true).firstOrNull;
      if (hit == null) return null;
      final id = asInt(hit['category_id']);
      final known = all.where((c) => c.id == id).firstOrNull;
      if (known != null) return known.copyWith(policy: CategoryPolicy.blocked);
      // A blocked keyword not tied to a category: describe it with its reason.
      return Category(
        id: id ?? -1,
        parentId: asInt(hit['parent_id']) ?? -1,
        names: hit['names'] != null ? parseLocalizedMap(hit['names']) : parseLocalizedMap(hit['reason']),
        policy: CategoryPolicy.blocked,
        disclaimer: parseLocalizedMap(hit['reason']),
      );
    } catch (e) {
      debugPrint('classify: $e');
      return suggestCategories(all, text, includeBlocked: true).where((c) => c.isBlocked).firstOrNull;
    }
  }
}

/// Buyer requests: `create_request`, direct reads (RLS: own rows), media in
/// `request-media/{request_id}/...`, Realtime on `requests`.
class SupabaseRequestRepository implements RequestRepository {
  SupabaseRequestRepository(this.ctx, this.categories);
  final SupabaseContext ctx;
  final SupabaseCategoryRepository categories;

  static const select = '*, request_media(file_path, type, sort, hidden)';
  static const _kind = 'request';

  final _notified = <String, int>{};

  Future<BuyerRequest> _map(JsonRow row) async => (await _mapAll([row])).single;

  /// Maps rows and signs every media path in one storage call.
  Future<List<BuyerRequest>> _mapAll(List<JsonRow> rows) async {
    final list = [
      for (final row in rows)
        mapRequest(row, fallbackCurrency: ctx.currency, notifiedSellers: _notified[row['id']] ?? 0),
    ];
    final paths = [for (final r in list) ...r.media.map((m) => m.path)];
    if (paths.isEmpty) return list;
    final urls = await ctx.signedUrls(Buckets.requestMedia, paths);
    return [
      for (final r in list) r.copyWith(media: [for (final m in r.media) m.copyWith(url: urls[m.path])]),
    ];
  }

  String _title(RequestDraft d, List<Category> cats) {
    final text = d.text.trim();
    final cat = cats.where((c) => c.id == d.categoryId).firstOrNull;
    var title = text.isEmpty ? (cat?.name('en') ?? '') : text.split('\n').first.trim();
    if (title.length > 80) title = '${title.substring(0, 80)}…';
    if (title.length < 3) title = [title, cat?.name('en') ?? ''].where((s) => s.isNotEmpty).join(' · ');
    return title;
  }

  static int _windowHours(QuoteWindow w) => switch (w) {
    QuoteWindow.h24 => 24,
    QuoteWindow.h48 => 48,
    QuoteWindow.d7 => 168,
  };

  @override
  Future<BuyerRequest> createRequest(RequestDraft draft) async {
    if (draft.categoryId == null) throw const RequestFailure('invalid', 'category required');
    final cats = await categories.fetchAll().catchError((_) => const <Category>[]);
    final JsonRow? created;
    try {
      created = await ctx.rpcRow('create_request', {
        'p_category_id': draft.categoryId,
        'p_title': _title(draft, cats),
        'p_description': draft.text.trim().isEmpty ? null : draft.text.trim(),
        'p_fields': draft.fields,
        'p_budget_min_minor': draft.budgetMin?.minorInt,
        'p_budget_max_minor': draft.budgetMax?.minorInt,
        'p_budget_visible': draft.budgetVisible,
        'p_needed_by': draft.neededBy == null ? null : formatDate(draft.neededBy!),
        'p_lat': draft.lat,
        'p_lng': draft.lng,
        'p_location_code': (draft.locationCode ?? '').trim().isEmpty ? null : draft.locationCode!.trim(),
        'p_locality': draft.locality,
        'p_audience': draft.audience.name,
        'p_quote_window_hours': _windowHours(draft.quoteWindow),
        'p_full_address': draft.fullAddress,
        'p_reference_url': draft.referenceLink,
        'p_inviting_seller_id': draft.invitedBySellerId,
      });
    } catch (e) {
      throw toRequestFailure(e);
    }
    final id = created?['request_id']?.toString();
    if (id == null) throw const RequestFailure('unknown', 'create_request returned no id');
    _notified[id] = asInt(created!['matched_sellers']) ?? 0;

    // Media goes to request-media/{request_id}/{uuid}.{ext}, then a row.
    var sort = 0;
    for (final local in draft.localMediaPaths) {
      try {
        final ext = SupabaseContext.extensionOf(local);
        final type = const {'mp4', 'mov'}.contains(ext) ? 'video' : 'image';
        final path = await ctx.upload(Buckets.requestMedia, (ext) => '$id/${ctx.newId()}.$ext', local);
        await ctx.client.from('request_media').insert({
          'request_id': id,
          'file_path': path,
          'type': type,
          'sort': sort++,
        });
      } catch (e) {
        debugPrint('request media upload failed: $e'); // the request itself exists
      }
    }
    ctx.changed(Topics.requests);
    final row = await ctx.client.from('requests').select(select).eq('id', id).single();
    return _map(row);
  }

  Future<List<JsonRow>> _fetchMine(String uid) async {
    final rows = await ctx.client
        .from('requests')
        .select(select)
        .eq('buyer_id', uid)
        .order('created_at', ascending: false)
        .limit(100);
    return rows;
  }

  @override
  Stream<List<BuyerRequest>> watchMyRequests() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(const []);
    final live = ctx.liveQuery<List<JsonRow>>(
      name: 'requests:$uid',
      fetch: () => _fetchMine(uid),
      bind: ctx.onTable('requests', column: 'buyer_id', equals: uid),
      topics: {Topics.requests},
    );
    return ctx.cachedRows(kind: _kind, scope: uid, live: live).asyncMap(_mapAll);
  }

  @override
  Stream<BuyerRequest?> watchRequest(String id) {
    final live = ctx.liveQuery<JsonRow?>(
      name: 'request:$id',
      fetch: () => ctx.client.from('requests').select(select).eq('id', id).maybeSingle(),
      bind: ctx.onTable('requests', column: 'id', equals: id),
      topics: {Topics.requests},
    );
    return ctx.cachedRow(kind: _kind, id: id, live: live).asyncMap((r) => r == null ? null : _map(r));
  }

  @override
  Future<void> cancelRequest(String id) async {
    try {
      await ctx.client.rpc<dynamic>('close_request', params: {'p_request_id': id, 'p_status': 'cancelled'});
    } catch (e) {
      throw toRequestFailure(e);
    }
    ctx.changed(Topics.requests);
  }

  @override
  Future<int> postalCodeLookupCount(String code) async {
    final normalized = await ctx.client.rpc<dynamic>('normalize_postal_code', params: {'p_code': code});
    if (normalized == null) return 0;
    final res = await ctx.client
        .from('postal_codes')
        .select('code')
        .eq('code', normalized.toString())
        .count(CountOption.exact);
    return res.count;
  }
}
