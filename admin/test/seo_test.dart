import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/app.dart';
import 'package:iwant_admin/core/config/admin_country.dart';
import 'package:iwant_admin/core/config/admin_env.dart';
import 'package:iwant_admin/core/demo/demo_repositories.dart';
import 'package:iwant_admin/core/demo/demo_store.dart';
import 'package:iwant_admin/core/providers.dart';
import 'package:iwant_admin/features/seo/data/demo_seo_repository.dart';
import 'package:iwant_admin/features/seo/data/supabase_seo_repository.dart';
import 'package:iwant_admin/features/seo/domain/seo_models.dart';
import 'package:iwant_admin/features/seo/presentation/seo_screen.dart';
import 'package:iwant_admin/l10n/gen/app_localizations.dart';

final now = DateTime.utc(2026, 10, 2, 12);

SeoGuide guide({
  GuideStatus status = GuideStatus.draft,
  bool ai = false,
  DateTime? created,
  DateTime? reviewed,
}) =>
    SeoGuide(
      id: 'g',
      slug: 'g',
      title: 'Guide title',
      categoryId: 2,
      bodyMd: 'x',
      status: status,
      aiAssisted: ai,
      reviewedAt: reviewed,
      createdAt: created ?? now,
      updatedAt: now,
    );

void main() {
  group('thresholds', () {
    test('defaults, JSON round trip and server ranges', () {
      expect(SeoThresholds.fromJson(null), SeoThresholds.defaults);
      expect(SeoThresholds.defaults.toJson(), {'min_quotes': 10, 'min_sellers': 3, 'window_days': 90, 'stale_days': 90});
      expect(SeoThresholds.fromJson({'min_quotes': 12, 'min_sellers': 4, 'window_days': 60, 'stale_days': 30}).minQuotes, 12);
      expect(SeoThresholds.defaults.isValid, isTrue);
    });

    test('anonymity floor: never fewer than 3 quotes or 2 sellers', () {
      expect(const SeoThresholds(minQuotes: 2).invalidKeys(), ['min_quotes']);
      expect(const SeoThresholds(minSellers: 1).invalidKeys(), ['min_sellers']);
      expect(const SeoThresholds(windowDays: 400, staleDays: 6).invalidKeys(), ['window_days', 'stale_days']);
      expect(const SeoThresholds(minQuotes: 3, minSellers: 2, windowDays: 7, staleDays: 365).isValid, isTrue);
    });
  });

  group('guides', () {
    test('review transitions mirror admin_review_seo_guide', () {
      expect(guideActions(GuideStatus.draft), [GuideAction.approve]);
      expect(guideActions(GuideStatus.approved), [GuideAction.publish, GuideAction.reject]);
      expect(guideActions(GuideStatus.published), [GuideAction.unpublish, GuideAction.reject]);
    });

    test('weekly AI count uses a rolling 7 days and ignores human guides', () {
      final gs = [
        guide(ai: true, created: now.subtract(const Duration(days: 1))),
        guide(ai: true, created: now.subtract(const Duration(days: 8))),
        guide(created: now),
      ];
      expect(aiGuidesThisWeek(gs, now), 1);
    });

    test('site visibility and review overdue (twice a year)', () {
      expect(guide().siteVisibility(now), 'not exported');
      expect(guide(status: GuideStatus.approved, reviewed: now).siteVisibility(now), 'noindex preview');
      expect(guide(status: GuideStatus.published, reviewed: now).siteVisibility(now), 'indexable');
      final old = guide(status: GuideStatus.published, reviewed: now.subtract(const Duration(days: 200)));
      expect(old.reviewOverdue(now), isTrue);
      expect(old.siteVisibility(now), 'noindex (review overdue)');
    });

    test('slugs and draft validation', () {
      expect(slugify('Which 1.5 ton AC for a Chennai flat?'), 'which-1-5-ton-ac-for-a-chennai-flat');
      expect(isValidGuideSlug('fridge-size'), isTrue);
      expect(isValidGuideSlug('Fridge size'), isFalse);
      expect(isValidGuideSlug('-x'), isFalse);
      const ok = SeoGuideDraft(slug: 'a-guide', title: 'A good guide', categoryId: 1, bodyMd: '## Hi');
      expect(ok.validate(), isNull);
      expect(const SeoGuideDraft(slug: 'a guide', title: 'A good guide', categoryId: 1, bodyMd: 'x').validate(), 'invalid_slug');
      expect(const SeoGuideDraft(slug: 'a', title: 'Hi', categoryId: 1, bodyMd: 'x').validate(), 'invalid_title');
      expect(const SeoGuideDraft(slug: 'a', title: 'A good guide', categoryId: 1, bodyMd: '  ').validate(), 'invalid_body');
    });
  });

  group('demo repository', () {
    late DemoStore store;
    late DemoSeoRepository repo;
    setUp(() {
      store = DemoStore(AdminCountryConfig.usa, now: now);
      repo = DemoSeoRepository(store, fixedNow: now);
    });

    test('weekly AI cap from app_settings', () async {
      store.settings['seo_ai_guides_weekly_cap'] = store.settings['seo_ai_guides_weekly_cap']!.withValue(1);
      // the seeded AI draft already used this week's single slot
      await expectLater(
        repo.upsertGuide(const SeoGuideDraft(slug: 'ai-two', title: 'Another AI guide', categoryId: 2, bodyMd: 'x', aiAssisted: true)),
        throwsA(isA<StateError>().having((e) => e.message, 'message', 'ai_guide_weekly_cap')),
      );
      final human = await repo.upsertGuide(
          const SeoGuideDraft(slug: 'human-one', title: 'A human guide', categoryId: 2, bodyMd: 'x'));
      expect(human.status, GuideStatus.draft);
    });

    test('draft -> approve (reviewer + date) -> publish; edits go back to draft', () async {
      store.currentAdminId = 'admin-1';
      final g = await repo.upsertGuide(const SeoGuideDraft(slug: 'new-guide', title: 'A new guide', categoryId: 2, bodyMd: 'x'));
      await expectLater(repo.reviewGuide(g.id, GuideAction.publish),
          throwsA(isA<StateError>().having((e) => e.message, 'message', 'guide_not_approved')));
      final approved = await repo.reviewGuide(g.id, GuideAction.approve);
      expect(approved.reviewerId, 'admin-1');
      expect(approved.reviewedAt, now);
      final published = await repo.reviewGuide(g.id, GuideAction.publish);
      expect(published.status, GuideStatus.published);
      final edited = await repo.upsertGuide(
          SeoGuideDraft(id: g.id, slug: 'new-guide', title: 'A new guide, edited', categoryId: 2, bodyMd: 'y'));
      expect(edited.status, GuideStatus.draft);
      expect(edited.reviewerId, isNull);
      expect(store.audit.map((a) => a.action), contains('admin_review_seo_guide'));
    });

    test('thresholds drive page status; manual noindex sticks', () async {
      final before = await repo.pages();
      expect(before.where((p) => p.status == SeoPageStatus.indexable), isNotEmpty);
      store.settings['seo_thresholds'] = store.settings['seo_thresholds']!
          .withValue(const SeoThresholds(minQuotes: 1000, minSellers: 3).toJson());
      await repo.runExportNow();
      final after = await repo.pages();
      expect(after.every((p) => p.status == SeoPageStatus.waitingForData), isTrue);
      final p = after.first;
      final forced = await repo.setPageNoindex(p.cityId, p.categoryId, true);
      expect(forced.manualNoindex, isTrue);
      expect(forced.reasons, contains(SeoPageRow.manualNoindexReason));
      expect((await repo.runs()).first.triggeredBy, startsWith('admin:'));
    });

    test('settings repository rejects thresholds below the floor', () async {
      final settings = DemoSettingsRepository(store);
      await expectLater(settings.set('seo_thresholds', {'min_quotes': 1, 'min_sellers': 3, 'window_days': 90, 'stale_days': 90}),
          throwsArgumentError);
      await expectLater(settings.set('seo_thresholds', {'min_quotes': 10}), throwsArgumentError);
      final ok = await settings.set('seo_thresholds', {'min_quotes': 15, 'min_sellers': 4, 'window_days': 90, 'stale_days': 60});
      expect(SeoThresholds.fromJson(ok.value).minQuotes, 15);
    });
  });

  test('Supabase row mapping', () {
    final p = SupabaseSeoRepository.page({
      'city_id': 4,
      'category_id': 7,
      'city_slug': 'dallas',
      'category_slug': 'refrigerators',
      'path': '/quotes/dallas/refrigerators',
      'status': 'waiting_for_data',
      'reasons': ['below threshold'],
      'quotes_window': 9,
      'sellers_window': 3,
      'local_sellers': 12,
      'merged_city_ids': [5],
      'last_quote_at': '2026-09-30T00:00:00Z',
      'manual_noindex': false,
      'refreshed_at': '2026-10-02T02:40:00Z',
    });
    expect(p.status, SeoPageStatus.waitingForData);
    expect(p.mergedCityIds, [5]);
    final g = SupabaseSeoRepository.guide({
      'id': 'x',
      'slug': 's',
      'title': 'Title here',
      'category_id': 3,
      'body_md': 'b',
      'status': 'published',
      'ai_assisted': true,
      'reviewed_at': '2026-09-01T00:00:00Z',
      'created_at': '2026-08-01T00:00:00Z',
      'updated_at': '2026-09-01T00:00:00Z',
    });
    expect(g.status, GuideStatus.published);
    expect(g.aiAssisted, isTrue);
    final r = SeoExportResult.fromJson({'run_id': 3, 'pages': 10, 'priced_pages': 4, 'guides': 1, 'uploaded': true, 'deploy_hook': 'dry_run'});
    expect((r.runId, r.pricedPages, r.deployHook), (3, 4, 'dry_run'));
  });

  testWidgets('thresholds dialog: Save disabled below the anonymity floor', (tester) async {
    SeoThresholds? result;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => result = await showDialog<SeoThresholds>(
            context: context,
            builder: (_) => const ThresholdsDialog(initial: SeoThresholds.defaults),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('seo-threshold-min_quotes')), '2');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save')).onPressed, isNull);
    await tester.enterText(find.byKey(const ValueKey('seo-threshold-min_quotes')), '12');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(result?.minQuotes, 12);
  });

  testWidgets('demo: SEO pages screen lists pages, runs the export and shows guides', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [adminEnvProvider.overrideWithValue(const AdminEnv(country: 'usa'))],
      child: const AdminApp(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), DemoStore.adminEmail);
    await tester.enterText(find.byType(TextFormField).at(1), DemoStore.adminPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SEO pages').first);
    await tester.pumpAndSettle();
    expect(find.text('Quality gates'), findsOneWidget);
    expect(find.textContaining('/quotes/new-york/'), findsWidgets);

    await tester.tap(find.text('Run export now').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run export now').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Export done'), findsOneWidget);

    await tester.tap(find.text('Guides'));
    await tester.pumpAndSettle();
    expect(find.textContaining('New AI-assisted guides this week: 1 of 10'), findsOneWidget);
    expect(find.text('Fridge size for a family of four (demo)'), findsOneWidget);
  });
}
