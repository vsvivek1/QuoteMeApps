import '../../../core/demo/demo_store.dart';
import '../../categories/domain/category_models.dart';
import '../domain/seo_models.dart';

/// In-memory SEO pages, export runs and guides for demo mode. Mirrors the
/// server rules (review transitions, weekly AI cap, thresholds) so the panel
/// behaves the same; nothing is exported or deployed.
class DemoSeoRepository implements SeoRepository {
  DemoSeoRepository(this.s, {this.fixedNow}) {
    _seed();
  }

  final DemoStore s;

  /// Fixed clock for tests; null = wall clock.
  final DateTime? fixedNow;
  DateTime get now => fixedNow ?? DateTime.now();

  final _pages = <SeoPageRow>[];
  final _runs = <SeoExportRun>[];
  final _guides = <String, SeoGuide>{};
  var _runId = 1;

  static Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 80));

  SeoThresholds get _thresholds => SeoThresholds.fromJson(s.settings[SeoThresholds.settingKey]?.value);
  int get _cap => (s.settings[SeoThresholds.guideCapKey]?.value as num?)?.toInt() ?? 10;

  List<AdminCategory> get _leafAllowed => [
        for (final c in s.categories)
          if (c.policy == CategoryPolicy.allowed && !s.categories.any((x) => x.parentId == c.id)) c,
      ];

  void _seed() {
    final cities = s.config.priorityCities.take(4).toList();
    final cats = _leafAllowed;
    var cityId = 1;
    for (final city in cities) {
      final slug = city.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
      for (final (i, cat) in cats.indexed) {
        final q = ((cityId * 7 + i * 5) % 23) + (cityId == 1 ? 6 : 0);
        _pages.add(SeoPageRow(
          cityId: cityId,
          categoryId: cat.id,
          citySlug: slug,
          categorySlug: cat.slug,
          path: '/quotes/$slug/${cat.slug}',
          status: SeoPageStatus.waitingForData,
          quotesWindow: q,
          sellersWindow: (q / 3).ceil().clamp(1, 12),
          localSellers: 3 + (q % 9),
          lastQuoteAt: now.subtract(Duration(days: 1 + (q % 5))),
          refreshedAt: now,
        ));
      }
      cityId++;
    }
    _recompute();
    final cat = cats.isEmpty ? 0 : cats.first.id;
    void g(String slug, String title, GuideStatus st, {bool ai = false, int age = 3}) => _guides[slug] = SeoGuide(
          id: 'guide-$slug',
          slug: slug,
          title: title,
          categoryId: cat,
          cityId: 1,
          bodyMd: '## $title\n\nDemo guide text.',
          status: st,
          aiAssisted: ai,
          reviewerId: st == GuideStatus.draft ? null : 'demo-admin',
          reviewedAt: st == GuideStatus.draft ? null : now.subtract(Duration(days: age)),
          publishedAt: st == GuideStatus.published ? now.subtract(Duration(days: age)) : null,
          createdAt: now.subtract(Duration(days: age + 1)),
          updatedAt: now.subtract(Duration(days: age)),
        );
    g('fridge-size-family-of-four', 'Fridge size for a family of four (demo)', GuideStatus.published, age: 40);
    g('ai-draft-fridge-brands', 'Which fridge brand has the best service? (AI draft, demo)', GuideStatus.draft, ai: true, age: 1);
    _runs.add(SeoExportRun(
      id: _runId++,
      triggeredBy: 'cron',
      startedAt: now.subtract(const Duration(hours: 9)),
      finishedAt: now.subtract(const Duration(hours: 9)),
      pagesTotal: _pages.length,
      indexable: _count(SeoPageStatus.indexable),
      noindex: _count(SeoPageStatus.noindex),
      waitingForData: _count(SeoPageStatus.waitingForData),
      guides: 1,
      sellers: 0,
      storagePath: 'seo/${s.config.country.name}.json',
      uploadOk: true,
      deployHook: 'dry_run',
    ));
  }

  int _count(SeoPageStatus st) => _pages.where((p) => p.status == st).length;

  /// Same gates as `public.seo_export` (minus prices, which demo mode has none of).
  void _recompute() {
    final t = _thresholds;
    for (var i = 0; i < _pages.length; i++) {
      final p = _pages[i];
      final reasons = <String>[
        if (p.quotesWindow == 0) 'no quotes in the last ${t.windowDays} days',
        if (p.quotesWindow > 0 && (p.quotesWindow < t.minQuotes || p.sellersWindow < t.minSellers))
          'below threshold (${p.quotesWindow} quotes / ${p.sellersWindow} sellers; need ${t.minQuotes} / ${t.minSellers})',
        if (p.lastQuoteAt != null && now.difference(p.lastQuoteAt!).inDays > t.staleDays)
          'stale (no quotes in ${t.staleDays} days)',
        if (p.manualNoindex) SeoPageRow.manualNoindexReason,
      ];
      final waiting = p.quotesWindow == 0 || p.quotesWindow < t.minQuotes || p.sellersWindow < t.minSellers;
      _pages[i] = SeoPageRow(
        cityId: p.cityId,
        categoryId: p.categoryId,
        citySlug: p.citySlug,
        categorySlug: p.categorySlug,
        path: p.path,
        status: reasons.isEmpty
            ? SeoPageStatus.indexable
            : waiting
                ? SeoPageStatus.waitingForData
                : SeoPageStatus.noindex,
        reasons: reasons,
        quotesWindow: p.quotesWindow,
        sellersWindow: p.sellersWindow,
        localSellers: p.localSellers,
        lastQuoteAt: p.lastQuoteAt,
        manualNoindex: p.manualNoindex,
        indexableSince: reasons.isEmpty ? (p.indexableSince ?? now) : null,
        refreshedAt: now,
      );
    }
  }

  @override
  Future<List<SeoPageRow>> pages() async {
    await _latency();
    return [..._pages]..sort((a, b) => b.quotesWindow.compareTo(a.quotesWindow));
  }

  @override
  Future<List<SeoExportRun>> runs({int limit = 10}) async {
    await _latency();
    return _runs.reversed.take(limit).toList();
  }

  @override
  Future<SeoPageRow> setPageNoindex(int cityId, int categoryId, bool noindex) async {
    await _latency();
    final i = _pages.indexWhere((p) => p.cityId == cityId && p.categoryId == categoryId);
    if (i < 0) throw StateError('seo_page_not_found');
    _pages[i] = _pages[i].withManualNoindex(noindex);
    s.log('admin_set_seo_page_noindex', targetType: 'seo_page', targetId: _pages[i].path, details: {'noindex': noindex});
    s.touch();
    return _pages[i];
  }

  @override
  Future<List<SeoGuide>> guides() async {
    await _latency();
    return _guides.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<SeoGuide> upsertGuide(SeoGuideDraft d) async {
    await _latency();
    final err = d.validate();
    if (err != null) throw ArgumentError(err);
    final old = d.id == null ? null : _guides.values.where((g) => g.id == d.id).firstOrNull;
    if (d.id != null && old == null) throw StateError('guide_not_found');
    if (_guides.values.any((g) => g.slug == d.slug && g.id != d.id)) throw StateError('duplicate_slug');
    if (old == null && d.aiAssisted && aiGuidesThisWeek(_guides.values, now) >= _cap) {
      throw StateError('ai_guide_weekly_cap');
    }
    if (old != null && d.aiAssisted && !old.aiAssisted) throw StateError('ai_flag_cannot_be_added');
    if (old != null) _guides.remove(old.slug);
    final g = SeoGuide(
      id: old?.id ?? s.nextId('guide'),
      slug: d.slug,
      title: d.title.trim(),
      description: d.description,
      cityId: d.cityId,
      categoryId: d.categoryId,
      bodyMd: d.bodyMd,
      status: GuideStatus.draft,
      aiAssisted: d.aiAssisted,
      authorId: s.currentAdminId,
      createdAt: old?.createdAt ?? now,
      updatedAt: now,
    );
    _guides[g.slug] = g;
    s.log(old == null ? 'admin_create_seo_guide' : 'admin_edit_seo_guide',
        targetType: 'seo_guide', targetId: g.id, details: {'slug': g.slug, 'ai_assisted': g.aiAssisted});
    s.touch();
    return g;
  }

  @override
  Future<SeoGuide> reviewGuide(String id, GuideAction action) async {
    await _latency();
    final old = _guides.values.where((g) => g.id == id).firstOrNull;
    if (old == null) throw StateError('guide_not_found');
    if (!guideActions(old.status).contains(action)) {
      throw StateError(action == GuideAction.publish ? 'guide_not_approved' : 'invalid_transition');
    }
    final (status, reviewer, reviewed, published) = switch (action) {
      GuideAction.approve => (GuideStatus.approved, s.currentAdminId ?? 'demo-admin', now, null),
      GuideAction.publish => (GuideStatus.published, old.reviewerId, old.reviewedAt, old.publishedAt ?? now),
      GuideAction.unpublish => (GuideStatus.approved, old.reviewerId, old.reviewedAt, null),
      GuideAction.reject => (GuideStatus.draft, null, null, null),
    };
    final g = SeoGuide(
      id: old.id,
      slug: old.slug,
      title: old.title,
      description: old.description,
      cityId: old.cityId,
      categoryId: old.categoryId,
      bodyMd: old.bodyMd,
      status: status,
      aiAssisted: old.aiAssisted,
      authorId: old.authorId,
      reviewerId: reviewer,
      reviewedAt: reviewed,
      publishedAt: published,
      createdAt: old.createdAt,
      updatedAt: now,
    );
    _guides[g.slug] = g;
    s.log('admin_review_seo_guide', targetType: 'seo_guide', targetId: g.id,
        details: {'action': action.name, 'from': old.status.name, 'to': g.status.name});
    s.touch();
    return g;
  }

  @override
  Future<SeoExportResult> runExportNow() async {
    await _latency();
    _recompute();
    final published = _guides.values.where((g) => g.status != GuideStatus.draft).length;
    final run = SeoExportRun(
      id: _runId++,
      triggeredBy: 'admin:${s.currentAdminId ?? 'demo'}',
      startedAt: now,
      finishedAt: now,
      pagesTotal: _pages.length,
      indexable: _count(SeoPageStatus.indexable),
      noindex: _count(SeoPageStatus.noindex),
      waitingForData: _count(SeoPageStatus.waitingForData),
      guides: published,
      sellers: 0,
      storagePath: 'seo/${s.config.country.name}.json',
      uploadOk: true,
      deployHook: 'dry_run',
    );
    _runs.add(run);
    s.log('seo_export_run', targetType: 'seo_export', targetId: '${run.id}', details: {'demo': true});
    s.touch();
    return SeoExportResult(
      runId: run.id,
      pages: _pages.where((p) => p.quotesWindow > 0).length,
      pricedPages: run.indexable ?? 0,
      guides: published,
      uploaded: false,
      deployHook: 'dry_run',
    );
  }
}
