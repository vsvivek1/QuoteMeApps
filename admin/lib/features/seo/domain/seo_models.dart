/// SEO content site (brief Section 21.9): price-page status, export runs,
/// thresholds and the buying-guide review queue.
library;

/// Status of one city x category price page, as the nightly export left it.
enum SeoPageStatus {
  indexable,
  noindex,
  waitingForData;

  static SeoPageStatus parse(String? v) => switch (v) {
        'indexable' => indexable,
        'noindex' => noindex,
        _ => waitingForData,
      };
}

class SeoPageRow {
  const SeoPageRow({
    required this.cityId,
    required this.categoryId,
    required this.citySlug,
    required this.categorySlug,
    required this.path,
    required this.status,
    this.reasons = const [],
    this.quotesWindow = 0,
    this.sellersWindow = 0,
    this.localSellers = 0,
    this.mergedCityIds = const [],
    this.lastQuoteAt,
    this.manualNoindex = false,
    this.indexableSince,
    required this.refreshedAt,
  });

  final int cityId;
  final int categoryId;
  final String citySlug;
  final String categorySlug;
  final String path;
  final SeoPageStatus status;
  final List<String> reasons;
  final int quotesWindow;
  final int sellersWindow;
  final int localSellers;
  final List<int> mergedCityIds;
  final DateTime? lastQuoteAt;
  final bool manualNoindex;
  final DateTime? indexableSince;
  final DateTime refreshedAt;

  SeoPageRow withManualNoindex(bool v) => SeoPageRow(
        cityId: cityId,
        categoryId: categoryId,
        citySlug: citySlug,
        categorySlug: categorySlug,
        path: path,
        status: v && status == SeoPageStatus.indexable ? SeoPageStatus.noindex : status,
        reasons: [...reasons.where((r) => r != manualNoindexReason), if (v) manualNoindexReason],
        quotesWindow: quotesWindow,
        sellersWindow: sellersWindow,
        localSellers: localSellers,
        mergedCityIds: mergedCityIds,
        lastQuoteAt: lastQuoteAt,
        manualNoindex: v,
        indexableSince: indexableSince,
        refreshedAt: refreshedAt,
      );

  static const manualNoindexReason = 'manually set to noindex';
}

/// `app_settings.seo_thresholds`. Same ranges as `private.validate_seo_setting`.
class SeoThresholds {
  const SeoThresholds({this.minQuotes = 10, this.minSellers = 3, this.windowDays = 90, this.staleDays = 90});

  final int minQuotes;
  final int minSellers;
  final int windowDays;
  final int staleDays;

  static const defaults = SeoThresholds();
  static const settingKey = 'seo_thresholds';
  static const guideCapKey = 'seo_ai_guides_weekly_cap';

  /// Inclusive ranges enforced server side. The lower bounds are the
  /// anonymity floor: a median is never computed from fewer quotes or sellers.
  static const ranges = <String, (int, int)>{
    'min_quotes': (3, 1000),
    'min_sellers': (2, 100),
    'window_days': (7, 365),
    'stale_days': (7, 365),
  };

  factory SeoThresholds.fromJson(Object? v) {
    if (v is! Map) return defaults;
    int read(String k, int d) => v[k] is num ? (v[k] as num).toInt() : d;
    return SeoThresholds(
      minQuotes: read('min_quotes', defaults.minQuotes),
      minSellers: read('min_sellers', defaults.minSellers),
      windowDays: read('window_days', defaults.windowDays),
      staleDays: read('stale_days', defaults.staleDays),
    );
  }

  Map<String, int> toJson() => {
        'min_quotes': minQuotes,
        'min_sellers': minSellers,
        'window_days': windowDays,
        'stale_days': staleDays,
      };

  /// Keys whose value is out of range (empty = valid).
  List<String> invalidKeys() => [
        for (final e in toJson().entries)
          if (e.value < ranges[e.key]!.$1 || e.value > ranges[e.key]!.$2) e.key,
      ];

  bool get isValid => invalidKeys().isEmpty;

  @override
  bool operator ==(Object other) => other is SeoThresholds && other.toJson().toString() == toJson().toString();

  @override
  int get hashCode => toJson().toString().hashCode;
}

class SeoExportRun {
  const SeoExportRun({
    required this.id,
    required this.triggeredBy,
    required this.startedAt,
    this.finishedAt,
    this.pagesTotal,
    this.indexable,
    this.noindex,
    this.waitingForData,
    this.guides,
    this.sellers,
    this.storagePath,
    this.uploadOk,
    this.deployHook,
    this.error,
  });

  final int id;
  final String triggeredBy;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? pagesTotal;
  final int? indexable;
  final int? noindex;
  final int? waitingForData;
  final int? guides;
  final int? sellers;
  final String? storagePath;
  final bool? uploadOk;

  /// triggered | dry_run | failed | skipped
  final String? deployHook;
  final String? error;

  bool get ok => error == null && uploadOk == true;
}

/// Result of `seo-export` (Run export now).
class SeoExportResult {
  const SeoExportResult({
    required this.runId,
    required this.pages,
    required this.pricedPages,
    required this.guides,
    required this.uploaded,
    required this.deployHook,
    this.publicUrl,
  });

  factory SeoExportResult.fromJson(Map<String, dynamic> j) => SeoExportResult(
        runId: (j['run_id'] as num?)?.toInt(),
        pages: (j['pages'] as num?)?.toInt() ?? 0,
        pricedPages: (j['priced_pages'] as num?)?.toInt() ?? 0,
        guides: (j['guides'] as num?)?.toInt() ?? 0,
        uploaded: j['uploaded'] == true,
        deployHook: '${j['deploy_hook'] ?? 'skipped'}',
        publicUrl: j['public_url'] as String?,
      );

  final int? runId;
  final int pages;
  final int pricedPages;
  final int guides;
  final bool uploaded;
  final String deployHook;
  final String? publicUrl;
}

enum GuideStatus {
  draft,
  approved,
  published;

  static GuideStatus parse(String? v) => GuideStatus.values.firstWhere((s) => s.name == v, orElse: () => draft);
}

/// Review actions (`admin_review_seo_guide`).
enum GuideAction { approve, publish, unpublish, reject }

class SeoGuide {
  const SeoGuide({
    required this.id,
    required this.slug,
    required this.title,
    this.description,
    this.cityId,
    required this.categoryId,
    required this.bodyMd,
    required this.status,
    this.aiAssisted = false,
    this.authorId,
    this.reviewerId,
    this.reviewedAt,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? description;
  final int? cityId;
  final int categoryId;
  final String bodyMd;
  final GuideStatus status;
  final bool aiAssisted;
  final String? authorId;
  final String? reviewerId;
  final DateTime? reviewedAt;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Guides must be re-reviewed at least twice a year; the site sets older
  /// published guides to noindex (GUIDE_REVIEW_MAX_DAYS in web/app_site).
  static const reviewMaxDays = 184;

  bool reviewOverdue(DateTime now) =>
      status == GuideStatus.published &&
      (reviewedAt == null || now.difference(reviewedAt!).inDays > reviewMaxDays);

  /// What the exported site does with this guide.
  String siteVisibility(DateTime now) => switch (status) {
        GuideStatus.draft => 'not exported',
        GuideStatus.approved => 'noindex preview',
        GuideStatus.published => reviewOverdue(now) ? 'noindex (review overdue)' : 'indexable',
      };
}

/// Actions allowed from a status (mirrors `admin_review_seo_guide`).
List<GuideAction> guideActions(GuideStatus s) => switch (s) {
      GuideStatus.draft => const [GuideAction.approve],
      GuideStatus.approved => const [GuideAction.publish, GuideAction.reject],
      GuideStatus.published => const [GuideAction.unpublish, GuideAction.reject],
    };

/// New AI-assisted guides created in the rolling 7 days before [now].
int aiGuidesThisWeek(Iterable<SeoGuide> guides, DateTime now) => guides
    .where((g) => g.aiAssisted && g.createdAt.isAfter(now.subtract(const Duration(days: 7))))
    .length;

final _slugRe = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');
bool isValidGuideSlug(String s) => s.length <= 100 && _slugRe.hasMatch(s);

/// "Which 1.5 ton AC for a Chennai flat?" -> "which-1-5-ton-ac-for-a-chennai-flat"
String slugify(String s) {
  final out = s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
  return out.length > 100 ? out.substring(0, 100).replaceAll(RegExp(r'-+$'), '') : out;
}

class SeoGuideDraft {
  const SeoGuideDraft({
    this.id,
    required this.slug,
    required this.title,
    this.description,
    this.cityId,
    required this.categoryId,
    required this.bodyMd,
    this.aiAssisted = false,
  });

  final String? id;
  final String slug;
  final String title;
  final String? description;
  final int? cityId;
  final int categoryId;
  final String bodyMd;
  final bool aiAssisted;

  /// Client-side checks (the RPC checks again). Returns an error code or null.
  String? validate() {
    if (!isValidGuideSlug(slug)) return 'invalid_slug';
    final t = title.trim().length;
    if (t < 5 || t > 140) return 'invalid_title';
    if ((description ?? '').length > 300) return 'invalid_description';
    if (bodyMd.trim().isEmpty || bodyMd.length > 50000) return 'invalid_body';
    return null;
  }
}

abstract interface class SeoRepository {
  Future<List<SeoPageRow>> pages();
  Future<List<SeoExportRun>> runs({int limit = 10});
  Future<SeoPageRow> setPageNoindex(int cityId, int categoryId, bool noindex);
  Future<List<SeoGuide>> guides();
  Future<SeoGuide> upsertGuide(SeoGuideDraft draft);
  Future<SeoGuide> reviewGuide(String id, GuideAction action);

  /// Calls the `seo-export` Edge Function with the admin's JWT.
  Future<SeoExportResult> runExportNow();
}
