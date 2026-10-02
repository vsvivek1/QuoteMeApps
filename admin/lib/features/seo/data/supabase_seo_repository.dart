import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/seo_models.dart';

/// Reads `seo_pages`, `seo_export_runs` and `seo_guides` (admin-only RLS),
/// writes through the admin RPCs (`admin_set_seo_page_noindex`,
/// `admin_upsert_seo_guide`, `admin_review_seo_guide`) and runs the
/// `seo-export` Edge Function with the signed-in admin's JWT.
class SupabaseSeoRepository implements SeoRepository {
  SupabaseSeoRepository(this.c);
  final SupabaseClient c;

  static DateTime? _ts(Object? v) => v == null ? null : DateTime.tryParse(v.toString());
  static int _int(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
  static int? _intN(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

  static SeoPageRow page(Map<String, dynamic> r) => SeoPageRow(
        cityId: _int(r['city_id']),
        categoryId: _int(r['category_id']),
        citySlug: r['city_slug'] as String,
        categorySlug: r['category_slug'] as String,
        path: r['path'] as String,
        status: SeoPageStatus.parse(r['status'] as String?),
        reasons: [for (final x in (r['reasons'] as List? ?? const [])) '$x'],
        quotesWindow: _int(r['quotes_window']),
        sellersWindow: _int(r['sellers_window']),
        localSellers: _int(r['local_sellers']),
        mergedCityIds: [for (final x in (r['merged_city_ids'] as List? ?? const [])) _int(x)],
        lastQuoteAt: _ts(r['last_quote_at']),
        manualNoindex: r['manual_noindex'] == true,
        indexableSince: _ts(r['indexable_since']),
        refreshedAt: _ts(r['refreshed_at']) ?? DateTime.now(),
      );

  static SeoExportRun run(Map<String, dynamic> r) => SeoExportRun(
        id: _int(r['id']),
        triggeredBy: r['triggered_by'] as String? ?? 'cron',
        startedAt: _ts(r['started_at']) ?? DateTime.now(),
        finishedAt: _ts(r['finished_at']),
        pagesTotal: _intN(r['pages_total']),
        indexable: _intN(r['indexable']),
        noindex: _intN(r['noindex']),
        waitingForData: _intN(r['waiting_for_data']),
        guides: _intN(r['guides']),
        sellers: _intN(r['sellers']),
        storagePath: r['storage_path'] as String?,
        uploadOk: r['upload_ok'] as bool?,
        deployHook: r['deploy_hook'] as String?,
        error: r['error'] as String?,
      );

  static SeoGuide guide(Map<String, dynamic> r) => SeoGuide(
        id: r['id'] as String,
        slug: r['slug'] as String,
        title: r['title'] as String,
        description: r['description'] as String?,
        cityId: _intN(r['city_id']),
        categoryId: _int(r['category_id']),
        bodyMd: r['body_md'] as String? ?? '',
        status: GuideStatus.parse(r['status'] as String?),
        aiAssisted: r['ai_assisted'] == true,
        authorId: r['author_id'] as String?,
        reviewerId: r['reviewer_id'] as String?,
        reviewedAt: _ts(r['reviewed_at']),
        publishedAt: _ts(r['published_at']),
        createdAt: _ts(r['created_at']) ?? DateTime.now(),
        updatedAt: _ts(r['updated_at']) ?? DateTime.now(),
      );

  @override
  Future<List<SeoPageRow>> pages() async {
    final rows = await c.from('seo_pages').select().order('quotes_window', ascending: false).limit(5000);
    return [for (final r in rows) page(r)];
  }

  @override
  Future<List<SeoExportRun>> runs({int limit = 10}) async {
    final rows = await c.from('seo_export_runs').select().order('id', ascending: false).limit(limit);
    return [for (final r in rows) run(r)];
  }

  @override
  Future<SeoPageRow> setPageNoindex(int cityId, int categoryId, bool noindex) async {
    final r = await c.rpc('admin_set_seo_page_noindex',
        params: {'p_city_id': cityId, 'p_category_id': categoryId, 'p_noindex': noindex});
    return page(Map<String, dynamic>.from(r as Map));
  }

  @override
  Future<List<SeoGuide>> guides() async {
    final rows = await c.from('seo_guides').select().order('updated_at', ascending: false).limit(1000);
    return [for (final r in rows) guide(r)];
  }

  @override
  Future<SeoGuide> upsertGuide(SeoGuideDraft d) async {
    final r = await c.rpc('admin_upsert_seo_guide', params: {
      'p_id': d.id,
      'p_slug': d.slug,
      'p_title': d.title,
      'p_category_id': d.categoryId,
      'p_body_md': d.bodyMd,
      'p_city_id': d.cityId,
      'p_description': d.description,
      'p_ai_assisted': d.aiAssisted,
    });
    return guide(Map<String, dynamic>.from(r as Map));
  }

  @override
  Future<SeoGuide> reviewGuide(String id, GuideAction action) async {
    final r = await c.rpc('admin_review_seo_guide', params: {'p_id': id, 'p_action': action.name});
    return guide(Map<String, dynamic>.from(r as Map));
  }

  @override
  Future<SeoExportResult> runExportNow() async {
    try {
      final res = await c.functions.invoke('seo-export', body: {'action': 'run'});
      return SeoExportResult.fromJson(
          res.data is Map ? Map<String, dynamic>.from(res.data as Map) : const <String, dynamic>{});
    } on FunctionException catch (e) {
      final d = e.details;
      throw Exception(d is Map ? '${d['code'] ?? d['message'] ?? e.status}' : 'seo_export_failed (${e.status})');
    }
  }
}
