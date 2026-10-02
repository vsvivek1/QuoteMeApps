import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant_admin/app.dart';
import 'package:iwant_admin/core/config/admin_country.dart';
import 'package:iwant_admin/core/config/admin_env.dart';
import 'package:iwant_admin/core/demo/demo_store.dart';
import 'package:iwant_admin/core/providers.dart';
import 'package:iwant_admin/features/trends/data/demo_trends_repository.dart';
import 'package:iwant_admin/features/trends/domain/trends_models.dart';
import 'package:iwant_admin/features/trends/presentation/setting_editor_dialog.dart';
import 'package:iwant_admin/l10n/gen/app_localizations.dart';

final now = DateTime.utc(2026, 10, 2, 12);

Matcher throwsTrends(String code) => throwsA(isA<TrendsException>().having((e) => e.code, 'code', code));

void main() {
  group('setting floors (mirror admin_trends_set_setting)', () {
    const caps = {
      'ramp_levels': [1, 2, 5, 10, 20],
      'hard_max_per_day': 20,
      'max_per_hour': 3,
      'max_drafts_per_run': 3,
    };
    List<String> check(String key, Object old, Object patch) => trendSettingProblems(key, old, mergeSetting(key, old, patch));

    test('caps: 1-3 per hour, at most 20 per day, ascending integer ramp levels', () {
      expect(check('caps', caps, {'max_per_hour': 2}), isEmpty);
      expect(check('caps', caps, {'max_per_hour': 4}), ['max_per_hour must be 1 to 3']);
      expect(check('caps', caps, {'max_per_hour': 0}), ['max_per_hour must be 1 to 3']);
      expect(check('caps', caps, {'hard_max_per_day': 21}), ['at most 20 per day per country']);
      expect(check('caps', caps, {'hard_max_per_day': 10}), ['at most 20 per day per country'],
          reason: 'the top ramp level (20) would exceed the hard max');
      expect(check('caps', caps, {'ramp_levels': [1, 3, 2]}), contains('ramp_levels must be ascending positive integers'));
      expect(check('caps', caps, {'ramp_levels': [1, 2.5]}), contains('ramp_levels must be ascending positive integers'));
      expect(check('caps', caps, {'ramp_levels': <int>[]}), contains('ramp_levels must be ascending positive integers'));
    });

    test('gates: >= 2 sources, >= 250 words, similarity <= 0.5, <= 1 rewrite', () {
      const gates = {'min_sources': 2, 'min_words': 250, 'max_similarity': 0.2, 'max_rewrites': 1, 'shingle_words': 6};
      expect(check('gates', gates, {'min_words': 400, 'max_similarity': 0.15}), isEmpty);
      for (final bad in [
        {'min_sources': 1},
        {'min_words': 249},
        {'max_similarity': 0.6},
        {'max_rewrites': 2},
      ]) {
        expect(check('gates', gates, bad), hasLength(1), reason: '$bad');
      }
    });

    test('ramp: >= 30 days between steps; levels kept from the old value', () {
      final ramp = {
        'usa': {'level': 1, 'changed_at': null},
        'india': {'level': 2, 'changed_at': null},
        'min_days_between_steps': 30,
      };
      expect(check('ramp', ramp, {'min_days_between_steps': 29}), ['min_days_between_steps >= 30']);
      final merged = mergeSetting('ramp', ramp, {'min_days_between_steps': 45, 'usa': {'level': 4}}) as Map;
      expect(merged['usa'], {'level': 1, 'changed_at': null});
      expect(merged['min_days_between_steps'], 45);
    });

    test('lists are replaced and need non-empty strings; type and kill switch checks', () {
      expect(mergeSetting('sensitive_tags', ['a'], ['b', 'c']), ['b', 'c']);
      expect(check('sensitive_tags', ['a'], ['b', '']), ['array of non-empty strings']);
      expect(check('sensitive_tags', ['a'], {'x': 1}), ['invalid_setting_type']);
      expect(trendSettingProblems('publishing', {}, {'paused': true}), ['use_admin_trends_set_kill_switch']);
      expect(mergeSetting('detection', {'a': 1, 'b': 2}, {'b': 3}), {'a': 1, 'b': 3});
    });

    test('list parsing for the editor', () {
      expect(parseNumberList('1, 2 5\n10'), [1, 2, 5, 10]);
      expect(parseNumberList('1, x'), isNull);
      expect(parseStringList('police, court\ncourt\n , riot'), ['police', 'court', 'riot']);
    });
  });

  group('mapping', () {
    test('gates in pipeline order with useful summaries', () {
      final gates = parseGates({
        'caps': {'passed': false, 'reason': 'daily cap reached'},
        'sources': {'passed': true, 'domains': ['a.com', 'b.com']},
        'originality': {'passed': false, 'max_similarity': 0.34, 'worst_source': 'a.com', 'rewrites': 1},
        'sensitive': {'reasons': ['keyword:police'], 'review': 'pending', 'stage': 'topic'},
        'custom': {'passed': true, 'x': 1},
      });
      expect(gates.map((g) => g.key), ['sources', 'sensitive', 'originality', 'caps', 'custom']);
      expect(gates.map((g) => g.passed), [true, null, false, false, true]);
      expect(gates[0].summary, '2 domains: a.com, b.com');
      expect(gates[1].summary, 'keyword:police; review: pending; stage: topic');
      expect(gates[2].summary, 'similarity 0.34; worst: a.com; rewrites 1');
      expect(gates[3].summary, 'daily cap reached');
      expect(GateResult.numbers['balance'], '5b');
    });

    test('board: places carry their country and place into topics; failing feeds', () {
      final b = TrendBoard.fromJson({
        'generated_at': '2026-10-02T12:00:00Z',
        'places': [
          {
            'country': 'india',
            'place_slug': 'pune',
            'place_name': 'Pune',
            'level': 'metro',
            'max_velocity': 82,
            'topics': [
              {'id': 't1', 'title': 'pune rains', 'status': 'waiting_sources', 'velocity': 82, 'domains': ['a.in'], 'signal_count': 9},
            ],
          },
        ],
        'sources': [
          {'id': 1, 'kind': 'google_news', 'country': 'india', 'geo': 'IN-WB', 'place_slug': 'kolkata', 'place_name': 'Kolkata', 'level': 'metro', 'enabled': true, 'last_status': 'error', 'last_error': 'HTTP 503'},
          {'id': 2, 'kind': 'reddit', 'country': 'usa', 'geo': 'US-IL', 'place_slug': 'chicago', 'place_name': 'Chicago', 'level': 'metro', 'enabled': false, 'last_status': 'error'},
        ],
      });
      final t = b.places.single.topics.single;
      expect((t.country, t.placeName, t.status, t.velocity), (TrendsCountry.india, 'Pune', TopicStatus.waitingSources, 82.0));
      expect(b.failingSources.map((s) => s.id), [1], reason: 'a disabled feed is not a blind spot');
      expect(b.placesMatching('PUN').length, 1);
      expect(b.placesMatching('chicago'), isEmpty);
      expect(b.sources.first.stale(DateTime.utc(2026, 10, 2)), isTrue);
    });

    test('drafts: review stage, queue meaning and allowed actions (mirror the RPC)', () {
      TrendDraft d(String status, {bool article = false, String? stage, String? superseded}) => TrendDraft.fromJson({
            'id': 'x',
            'country': 'usa',
            'status': status,
            'has_article': article,
            'review_stage': stage,
            'superseded_by': superseded,
            'created_at': '2026-10-02T10:00:00Z',
            'gates': {'sources': {'passed': true}},
          });
      expect(d('review').effectiveReviewStage, 'topic');
      expect(d('review', article: true).effectiveReviewStage, 'content');
      expect(d('queued', article: true).waitingForCaps, isTrue);
      expect(d('queued').waitingForCaps, isFalse);
      expect(allowedDraftActions(d('queued')), [DraftAction.reject]);
      expect(allowedDraftActions(d('review')), [DraftAction.reject]);
      expect(allowedDraftActions(d('published')), [DraftAction.noindex, DraftAction.unpublish]);
      expect(allowedDraftActions(d('noindex')), [DraftAction.reindex, DraftAction.unpublish]);
      expect(allowedDraftActions(d('noindex', superseded: 'newer')), [DraftAction.unpublish]);
      expect(allowedDraftActions(d('rejected')), isEmpty);
      expect(DraftAction.reindex.wire, 'index');
      expect(draftStatusAfter(DraftAction.unpublish), DraftStatus.rejected);
    });

    test('settings snapshot: per-country values, kill switch, run-now usage and ramp blockers', () {
      final s = TrendSettingsSnapshot.fromJson({
        'settings': {
          'publishing': {'paused': true, 'paused_at': '2026-10-02T09:00:00Z', 'paused_reason': 'error_report_spike', 'paused_by': 'auto'},
          'pipeline': {'enabled': true},
          'caps': {'ramp_levels': [1, 2, 5, 10, 20]},
          'ramp': {
            'usa': {'level': 0, 'changed_at': null},
            'india': {'level': 1, 'changed_at': '2026-09-20T00:00:00Z'},
            'min_days_between_steps': 30,
          },
        },
        'per_day': {'usa': 1, 'india': 2},
        'health_problem': {'usa': 'no_recent_health', 'india': null},
        'published_24h': {'usa': 0, 'india': 2},
        'runs': {
          'trends-poll': {'started_at': '2026-10-02T11:55:00Z', 'ok': true, 'stats': {'fired': ['a']}, 'trigger': 'admin'},
        },
        'run_now': {
          'trends-draft': {'used': 6, 'limit': 6, 'remaining': 0, 'window_seconds': 3600, 'retry_after_seconds': 600},
        },
      });
      expect(s.publishing.autoPaused, isTrue);
      expect(s.pipelineEnabled, isTrue);
      expect((s.perDay[TrendsCountry.india], s.published24h[TrendsCountry.india]), (2, 2));
      expect(s.runs['trends-poll']!.trigger, 'admin');
      expect(s.runNowFor(TrendsFunction.draft).remaining, 0);
      expect(s.runNowFor(TrendsFunction.poll).remaining, 6, reason: 'missing usage = full window');
      expect(s.rampStepUpBlocker(TrendsCountry.usa, now), 'ramp_unhealthy');
      expect(s.rampStepUpBlocker(TrendsCountry.india, now), 'ramp_step_too_soon');
      expect(s.rampStepUpBlocker(TrendsCountry.india, DateTime.utc(2026, 10, 21)), isNull);
      expect(s.editableKeys, isNot(contains('publishing')));
    });

    test('health: same rules as trends.health_problem', () {
      const cfg = {'max_age_days': 7, 'min_indexed_share': 0.6, 'max_click_drop': 0.3, 'max_sc_warnings': 0, 'max_error_reports_24h': 5};
      TrendHealth h({double share = 0.8, int clicks = 100, int prev = 100, int warnings = 0, bool manual = false, int errors = 0, int age = 1}) =>
          TrendHealth(
            country: TrendsCountry.usa,
            recordedAt: now.subtract(Duration(days: age)),
            indexedShare: share,
            clicks7d: clicks,
            clicksPrev7d: prev,
            scWarnings: warnings,
            manualAction: manual,
            errorReports24h: errors,
          );
      expect(healthProblem(null, cfg, now), 'no_recent_health');
      expect(healthProblem(h(age: 8), cfg, now), 'no_recent_health');
      expect(healthProblem(h(manual: true, errors: 9), cfg, now), 'manual_action');
      expect(healthProblem(h(errors: 6), cfg, now), 'error_reports');
      expect(healthProblem(h(warnings: 1), cfg, now), 'search_console_warnings');
      expect(healthProblem(h(share: 0.5), cfg, now), 'low_indexed_share');
      expect(healthProblem(h(clicks: 60, prev: 100), cfg, now), 'traffic_drop');
      expect(healthProblem(h(clicks: 80, prev: 100), cfg, now), isNull);
    });

    test('health and source input validation', () {
      const ok = HealthInput(country: TrendsCountry.india, indexedShare: 0.8, clicks7d: 10, clicksPrev7d: 12);
      expect(ok.validate(), isNull);
      expect(ok.toParams()['p_note'], isNull);
      expect(const HealthInput(country: TrendsCountry.india, indexedShare: 1.2, clicks7d: 1, clicksPrev7d: 1).validate(),
          'invalid_indexed_share');
      expect(const HealthInput(country: TrendsCountry.india, indexedShare: 0.5, clicks7d: -1, clicksPrev7d: 1).validate(),
          'invalid_clicks');

      TrendSourceDraft src({SourceKind kind = SourceKind.googleNews, String geo = 'IN-MH', String? query = 'Nagpur'}) => TrendSourceDraft(
            kind: kind,
            country: TrendsCountry.india,
            geo: geo,
            placeSlug: 'nagpur',
            placeName: 'Nagpur',
            level: 'metro',
            query: query,
          );
      expect(src().validate(), isNull);
      expect(src().toJson()['geo'], 'IN-MH');
      expect(src(geo: 'in-mh').validate(), isNull, reason: 'upper-cased like the RPC');
      expect(src(geo: 'IN-MAH').validate(), 'invalid_geo');
      expect(src(geo: 'US-CA').validate(), 'geo_country_mismatch');
      expect(src(query: ' ').validate(), 'query_required');
      expect(src(kind: SourceKind.googleTrends, query: null).validate(), isNull);
    });

    test('errors: RPC PTnnn and Edge Function 429 with Retry-After', () {
      final rpc = trendsRpcError(code: 'PT400', message: 'invalid_setting_value', details: 'max_per_hour must be 1 to 3');
      expect((rpc.code, rpc.status, '$rpc'), (
        'invalid_setting_value',
        400,
        'invalid_setting_value: max_per_hour must be 1 to 3',
      ));
      expect(trendsRpcError(code: 'PT409', message: 'draft_not_in_review').toString(), 'draft_not_in_review');

      final limited = trendsFunctionError(429, {
        'code': 'rate_limited',
        'details': {'fn': 'trends-draft', 'limit': 6, 'window_seconds': 3600, 'used': 6, 'retry_after_seconds': 754},
        'hint': 'at most 6 admin runs of trends-draft per 60 minutes',
      });
      expect(limited, isA<TrendsRateLimited>());
      limited as TrendsRateLimited;
      expect((limited.retryAfterSeconds, limited.limit, retryMinutes(limited.retryAfterSeconds)), (754, 6, 13));
      expect((trendsFunctionError(429, null, retryAfterHeader: '30') as TrendsRateLimited).retryAfterSeconds, 30);
      final other = trendsFunctionError(403, {'code': 'admin_only'});
      expect((other.code, other.status), ('admin_only', 403));
      expect(RunNowResult.fromJson({'ok': true, 'dry_run': true, 'reason': 'missing ANTHROPIC_API_KEY', 'stats': {'queued': 1, 'fired': ['a', 'b'], 'x': {}}})
          .statsSummary, 'queued 1, fired 2');
    });

    test('article view reads the site sections', () {
      const a = TrendArticleView({
        'headline': 'H',
        'summary': ['one', 'two', 'three'],
        'perspectives': {
          'framing': 'Short-term vs Long-term',
          'a': {'label': 'Short-term', 'body': 'A'},
          'b': {'label': 'Long-term', 'body': 'B'},
        },
        'corrections': [
          {'at': '2026-10-02T10:00:00Z', 'text': 'fixed'},
        ],
        'sources': [
          {'publisher': 'P', 'url': 'https://p.example'},
        ],
        'review': {'approved_by': 'editor:abc', 'approved_at': '2026-10-02T11:00:00Z'},
      });
      expect(a.summary, hasLength(3));
      expect(a.perspective('b')?.label, 'Long-term');
      expect(a.corrections.single.text, 'fixed');
      expect(a.sources.single.publisher, 'P');
      expect(a.approvedBy, 'editor:abc');
    });
  });

  group('demo repository (server rules)', () {
    late DemoStore store;
    late DemoTrendsRepository repo;
    setUp(() {
      store = DemoStore(AdminCountryConfig.india, now: now)..currentAdminId = 'admin-1';
      repo = DemoTrendsRepository(store, fixedNow: now);
    });

    test('board: both countries, hottest place first, failing feed visible; country filter', () async {
      final b = await repo.board();
      expect(b.places.first.placeName, 'Pune');
      expect(b.places.map((p) => p.country).toSet(), TrendsCountry.values.toSet());
      expect(b.failingSources.single.placeName, 'Kolkata');
      final usa = await repo.board(country: TrendsCountry.usa);
      expect(usa.places.every((p) => p.country == TrendsCountry.usa), isTrue);
      expect((await repo.topics(status: TopicStatus.fired)).single.title, 'houston power outage heat');
    });

    test('review: topic stage approval queues for drafting and stores reviewer and date', () async {
      final queue = await repo.reviewQueue();
      expect(queue.map((d) => d.effectiveReviewStage), ['topic', 'content'], reason: 'oldest first');
      final topic = queue.first;
      final approved = await repo.review(topic.id, approve: true, note: 'traffic rules only, no incident');
      expect((approved.status, approved.topicReviewedBy, approved.topicReviewedAt), (DraftStatus.queued, 'admin-1', now));
      await expectLater(repo.review(topic.id, approve: false), throwsTrends('draft_not_in_review'));
      expect(store.audit.first.action, 'admin_trends_review');
    });

    test('review: final text approval stamps article.review; rejection drops the topic', () async {
      final content = (await repo.reviewQueue()).firstWhere((d) => d.effectiveReviewStage == 'content');
      await repo.review(content.id, approve: true);
      final detail = await repo.draft(content.id);
      expect((detail.draft.status, detail.draft.reviewerId, detail.draft.reviewedAt), (DraftStatus.queued, 'admin-1', now));
      expect(TrendArticleView(detail.article!).approvedBy, 'editor:admin-1');
      expect(detail.log.first.decision, 'review_approved');

      final repo2 = DemoTrendsRepository(DemoStore(AdminCountryConfig.usa, now: now), fixedNow: now);
      final topic = (await repo2.reviewQueue()).first;
      final rejected = await repo2.review(topic.id, approve: false, note: 'police incident');
      expect((rejected.status, rejected.failedGate), (DraftStatus.rejected, 'sensitive'));
      expect((await repo2.topics(status: TopicStatus.dropped)).map((t) => t.id), contains(topic.topicId));
    });

    test('draft actions follow the RPC; corrections need 10 characters', () async {
      final published = (await repo.drafts(status: DraftStatus.published)).first;
      await expectLater(repo.setDraftStatus(published.id, DraftAction.reject), throwsTrends('invalid_draft_action'));
      final noindex = await repo.setDraftStatus(published.id, DraftAction.noindex, reason: 'thin');
      expect((noindex.status, noindex.noindexReason, noindex.dirty), (DraftStatus.noindex, 'thin', true));
      await expectLater(repo.addCorrection(published.id, 'short'), throwsTrends('correction_too_short'));
      await repo.addCorrection(published.id, 'The advisory runs until Sunday, not Saturday.');
      expect(TrendArticleView((await repo.draft(published.id)).article!).corrections, hasLength(1));
      final superseded = (await repo.drafts(status: DraftStatus.noindex)).firstWhere((d) => d.supersededBy != null);
      await expectLater(repo.setDraftStatus(superseded.id, DraftAction.reindex), throwsTrends('invalid_draft_action'));
    });

    test('settings floors, kill switch and health auto-pause', () async {
      await expectLater(repo.setSetting('caps', {'max_per_hour': 4}),
          throwsA(isA<TrendsException>().having((e) => e.detail, 'detail', 'max_per_hour must be 1 to 3')));
      await expectLater(repo.setSetting('publishing', {'paused': true}), throwsTrends('use_admin_trends_set_kill_switch'));
      expect(await repo.setSetting('caps', {'max_per_hour': 2}), containsPair('max_per_hour', 2));

      final paused = await repo.setKillSwitch(paused: true, reason: 'checking a complaint');
      expect((paused.paused, paused.pausedBy, paused.pausedAt), (true, 'admin-1', now));
      await repo.setKillSwitch(paused: false, reason: 'resolved');

      final r = await repo.recordHealth(const HealthInput(
          country: TrendsCountry.usa, indexedShare: 0.7, clicks7d: 100, clicksPrev7d: 90, manualAction: true));
      expect(r.autoPause, 'search_console_manual_action');
      final s = await repo.settings();
      expect((s.publishing.paused, s.publishing.pausedBy), (true, 'auto'));
      expect(s.healthProblems[TrendsCountry.usa], 'manual_action');
    });

    test('ramp: one level at a time, 30 days apart, only when healthy', () async {
      await expectLater(repo.setRamp(TrendsCountry.usa, 1), throwsTrends('ramp_unhealthy'));
      await expectLater(repo.setRamp(TrendsCountry.india, 3), throwsTrends('ramp_one_level_at_a_time'));
      await repo.setRamp(TrendsCountry.india, 2, reason: 'healthy for 6 weeks');
      expect((await repo.settings()).perDay[TrendsCountry.india], 5);
      await expectLater(repo.setRamp(TrendsCountry.india, 3), throwsTrends('ramp_step_too_soon'));
      await repo.setRamp(TrendsCountry.india, 0);
      expect((await repo.settings()).perDay[TrendsCountry.india], 1, reason: 'down: any time, any amount');
    });

    test('run now: 6 per function per hour, then rate limited', () async {
      for (var i = 0; i < 6; i++) {
        expect((await repo.runNow(TrendsFunction.draft)).dryRun, isTrue);
      }
      await expectLater(repo.runNow(TrendsFunction.draft),
          throwsA(isA<TrendsRateLimited>().having((e) => e.retryAfterSeconds, 'retry', 3600)));
      expect((await repo.runNow(TrendsFunction.poll)).ok, isTrue, reason: 'per function');
      final s = await repo.settings();
      expect((s.runNowFor(TrendsFunction.draft).remaining, s.runNowFor(TrendsFunction.poll).remaining), (0, 5));
      expect(s.runs['trends-draft']!.trigger, 'admin');
    });
  });

  testWidgets('setting editor: Save disabled below the floor, server refusal shown', (tester) async {
    Object? sent;
    var fail = true;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<bool>(
            context: context,
            builder: (_) => TrendSettingDialog(
              settingKey: 'caps',
              value: const {'ramp_levels': [1, 2, 5, 10, 20], 'hard_max_per_day': 20, 'max_per_hour': 3, 'timezones': {'usa': 'America/New_York'}},
              onSave: (v) async {
                if (fail) throw const TrendsException('invalid_setting_value', detail: 'max_per_hour must be 1 to 3', status: 400);
                sent = v;
              },
            ),
          ),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    Finder save() => find.widgetWithText(FilledButton, 'Save');

    await tester.enterText(find.byKey(const ValueKey('trends-setting-max_per_hour')), '4');
    await tester.pump();
    expect(tester.widget<FilledButton>(save()).onPressed, isNull);
    expect(find.text('Not allowed: max_per_hour must be 1 to 3'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('trends-setting-max_per_hour')), '2');
    await tester.pump();
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('trends-setting-server-error')), findsOneWidget);
    expect(find.textContaining('invalid_setting_value: max_per_hour must be 1 to 3'), findsOneWidget);

    fail = false;
    await tester.enterText(find.byKey(const ValueKey('trends-setting-timezones.usa')), 'America/Chicago');
    await tester.pump();
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(sent, {
      'max_per_hour': 2,
      'timezones': {'usa': 'America/Chicago'},
    }, reason: 'only changed keys; a nested object is sent whole');
  });

  testWidgets('demo: Trends screens render and the main flows work', (tester) async {
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [adminEnvProvider.overrideWithValue(const AdminEnv(country: 'india'))],
      child: const AdminApp(),
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), DemoStore.adminEmail);
    await tester.enterText(find.byType(TextFormField).at(1), DemoStore.adminPassword);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trends').first);
    await tester.pumpAndSettle();
    // live board
    expect(find.textContaining('Pune  ·  India'), findsOneWidget);
    expect(find.text('pune rains waterlogging'), findsOneWidget);
    expect(find.textContaining('feed(s) failing'), findsOneWidget);
    // country filter
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('trends-country')), matching: find.text('USA')));
    await tester.pumpAndSettle();
    expect(find.text('pune rains waterlogging'), findsNothing);
    expect(find.text('houston power outage heat'), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('trends-country')), matching: find.text('All')));
    await tester.pumpAndSettle();

    // fired topics
    await tester.tap(find.text('Fired topics'));
    await tester.pumpAndSettle();
    expect(find.text('houston power outage heat'), findsOneWidget);

    // drafts with gate chips, then the detail screen
    await tester.tap(find.text('Drafts'));
    await tester.pumpAndSettle();
    expect(find.text('Mumbai heatwave pushes up demand for AC repairs (sample)'), findsOneWidget);
    expect(find.text('1. 2+ sources'), findsWidgets);
    await tester.tap(find.text('Mumbai heatwave pushes up demand for AC repairs (sample)'));
    await tester.pumpAndSettle();
    expect(find.text('Quality gates'), findsOneWidget);
    expect(find.text('Where they agree'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // review queue: approve the topic-stage item
    await tester.tap(find.textContaining('Review queue'));
    await tester.pumpAndSettle();
    expect(find.text('Approve topic'), findsOneWidget);
    expect(find.text('Approve final text'), findsOneWidget);
    await tester.tap(find.text('Approve topic'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('Approve topic'), findsNothing);
    expect(find.text('Approve final text'), findsOneWidget);

    // controls: kill switch with confirmation and reason
    await tester.tap(find.text('Controls'));
    await tester.pumpAndSettle();
    expect(find.text('Run now'), findsWidgets);
    expect(find.text('6 of 6 admin runs left this hour'), findsNWidgets(3));
    await tester.tap(find.byKey(const ValueKey('trends-pause')));
    await tester.pumpAndSettle();
    expect(find.text('Pause drafting and publishing?'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('trends-confirm-reason')), 'checking a complaint');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Pause now').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Publishing and drafting are paused'), findsOneWidget);
    expect(find.byKey(const ValueKey('trends-resume')), findsOneWidget);

    // run now (demo: dry run) uses one of the hourly runs
    await tester.tap(find.byKey(const ValueKey('trends-run-poll')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Run now').last);
    await tester.pumpAndSettle();
    expect(find.text('5 of 6 admin runs left this hour'), findsOneWidget);
  });
}
