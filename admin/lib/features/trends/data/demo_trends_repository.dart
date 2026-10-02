import '../../../core/demo/demo_store.dart';
import '../domain/trends_models.dart';

/// In-memory trend board, drafts, review queue and settings for demo mode.
/// Fictional sample data for both countries (the pipeline covers both). It
/// mirrors the server rules of the `admin_trends_*` RPCs (review stages,
/// draft actions, setting floors, ramp, kill switch, health auto-pause) and
/// the "Run now" limit of 6 per function per hour; nothing is polled,
/// drafted, published or sent anywhere.
class DemoTrendsRepository implements TrendsRepository {
  DemoTrendsRepository(this.s, {this.fixedNow}) {
    _seed();
  }

  final DemoStore s;

  /// Fixed clock for tests; null = wall clock.
  final DateTime? fixedNow;
  DateTime get now => fixedNow ?? DateTime.now();

  static const runNowLimit = 6;
  static const runNowWindow = Duration(hours: 1);

  final _sources = <TrendSource>[];
  final _topics = <String, TrendTopic>{};
  final _drafts = <String, Map<String, dynamic>>{};
  final _signals = <String, List<TrendSignal>>{};
  final _log = <TrendLogEntry>[];
  final _settings = <String, Object?>{};
  final _descriptions = <String, String>{};
  final _health = <TrendsCountry, List<TrendHealth>>{for (final c in TrendsCountry.values) c: []};
  final _runs = <String, TrendRun>{};
  final _adminRuns = <String, List<DateTime>>{};
  var _logId = 1;
  var _sourceId = 100;

  static Future<void> _latency() => Future<void>.delayed(const Duration(milliseconds: 60));

  String get _admin => s.currentAdminId ?? 'demo-admin';
  String _iso(DateTime d) => d.toUtc().toIso8601String();
  DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) =>
      now.subtract(Duration(days: days, hours: hours, minutes: minutes));

  // Seed --------------------------------------------------------------------------------------------

  void _seed() {
    _seedSettings();
    _seedSources();
    _seedTopicsAndDrafts();
    for (final f in TrendsFunction.values) {
      _runs[f.fnName] = TrendRun(
        fn: f.fnName,
        startedAt: _ago(minutes: 3 + f.index),
        finishedAt: _ago(minutes: 3 + f.index),
        ok: true,
        trigger: 'cron',
        stats: switch (f) {
          TrendsFunction.poll => {'sources': 32, 'signals_seen': 412, 'signals_new': 37, 'topics_new': 4, 'fired': <String>['houston power outage heat']},
          TrendsFunction.draft => {'considered': 2, 'queued': 1, 'review': 1, 'rejected': 0, 'skipped_caps': 0},
          TrendsFunction.publish => {'published': <String>[], 'capped': 1, 'uploaded': 0, 'deploy_hook': 'dry_run'},
        },
      );
    }
    _health[TrendsCountry.india]!.add(TrendHealth(
      country: TrendsCountry.india,
      recordedAt: _ago(days: 3),
      indexedShare: 0.82,
      clicks7d: 1240,
      clicksPrev7d: 1105,
      note: 'Search Console weekly check (demo)',
    ));
  }

  void _seedSettings() {
    void set(String k, Object v, String d) {
      _settings[k] = v;
      _descriptions[k] = d;
    }

    set('pipeline', {'enabled': false}, 'Master switch for the pg_cron jobs (poll, draft, publish). Enable it in ONE project only.');
    set('publishing', {'paused': false, 'paused_at': null, 'paused_reason': null},
        'Kill switch: paused=true stops drafting and publishing at once (polling continues).');
    set(
        'caps',
        {
          'ramp_levels': [1, 2, 5, 10, 20],
          'hard_max_per_day': 20,
          'max_per_hour': 3,
          'timezones': {'usa': 'America/New_York', 'india': 'Asia/Kolkata'},
          'max_drafts_per_run': 3,
          'queue_ttl_hours': 6,
        },
        'Rate caps: per-country daily cap = ramp_levels[ramp.<country>.level], max per rolling hour, queue expiry.');
    set(
        'ramp',
        {
          'usa': {'level': 0, 'changed_at': null},
          'india': {'level': 1, 'changed_at': _iso(_ago(days: 41)), 'changed_by': 'admin'},
          'min_days_between_steps': 30,
          'auto_step_up': false,
          'health': {'max_age_days': 7, 'min_indexed_share': 0.6, 'max_click_drop': 0.3, 'max_sc_warnings': 0, 'max_error_reports_24h': 5},
        },
        'Ramp 1 -> 2 -> 5 -> 10 -> 20 per day. Up: manually (one level, 30+ days apart) or by health signal when auto_step_up; down: automatic on bad health.');
    set(
        'gates',
        {
          'min_sources': 2,
          'max_similarity': 0.2,
          'shingle_words': 6,
          'max_quote_words': 25,
          'min_words': 250,
          'min_section_words': 15,
          'max_perspective_ratio': 1.5,
          'noindex_min_visits_14d': 20,
          'max_rewrites': 1,
        },
        'Quality gate thresholds (same names and values as the site build).');
    set(
        'detection',
        {
          'fire_threshold': 60,
          'min_signals': 3,
          'cluster_similarity': 0.5,
          'velocity_window_minutes': 60,
          'baseline_hours': 6,
          'topic_ttl_hours': 48,
          'merge_window_days': 7,
          'end_velocity': 10,
          'end_after_hours': 6,
          'update_min_interval_minutes': 60,
          'max_updates': 10,
          'source_weights': {'google_trends': 3, 'google_news': 1, 'reddit': 1},
          'non_publisher_domains': ['news.google.com', 'trends.google.com', 'google.com', 'reddit.com', 'x.com'],
        },
        'Trend detection: velocity threshold to fire, minimum signals, clustering and topic lifetimes.');
    set('sensitive_tags', ['religion', 'caste', 'communal', 'death', 'crime', 'health', 'medical', 'election', 'politics', 'court', 'minors'],
        'Topic tags that never auto-publish (human review queue).');
    set('sensitive_keywords', ['killed', 'dead', 'death', 'riot', 'police', 'court', 'election', 'vaccine', 'outbreak', 'child', 'shooting'],
        'Words in a topic or its headlines that send it to the human review queue.');
    set('banned_perspective_terms', ['left', 'right', 'liberal', 'conservative', 'communist', 'capitalist', 'democrat', 'republican', 'bjp', 'congress'],
        'Partisan / ideological / religious labels never allowed as perspective labels.');
    set(
        'app_links',
        [
          {'country': 'india', 'keywords': ['heatwave', 'heat wave', 'temperature'], 'category': 'air-conditioner-repair', 'label': 'Get AC repair quotes in {place} on I Want India'},
          {'country': 'india', 'keywords': ['monsoon', 'flooding', 'waterlogging'], 'category': 'plumbing', 'label': 'Get plumbing quotes in {place} on I Want India'},
          {'country': 'usa', 'keywords': ['snow', 'freeze', 'cold'], 'category': 'furnace-repair', 'label': 'Get furnace repair quotes in {place} on I Want USA'},
        ],
        'Keyword -> app category link rules (UTM utm_source=trends).');
    set('app_hosts', {'usa': 'iwantusa.app', 'india': 'iwantindia.app'}, 'App hosts for contextual links (must be in the site APP_LINK_HOSTS).');
  }

  void _seedSources() {
    void src(SourceKind k, TrendsCountry c, String geo, String slug, String name, String level,
        {String? query, String status = 'ok', String? error, int items = 20, bool enabled = true, int mins = 2}) {
      _sources.add(TrendSource(
        id: _sources.length + 1,
        kind: k,
        country: c,
        geo: geo,
        placeSlug: slug,
        placeName: name,
        level: level,
        query: query,
        enabled: enabled,
        lastPolledAt: enabled ? _ago(minutes: mins) : null,
        lastStatus: enabled ? status : null,
        lastError: error,
        lastItems: enabled && status == 'ok' ? items : 0,
      ));
    }

    const i = TrendsCountry.india, u = TrendsCountry.usa;
    const gt = SourceKind.googleTrends, gn = SourceKind.googleNews, rd = SourceKind.reddit;
    src(gt, i, 'IN', 'india', 'India', 'country', items: 20);
    src(gt, i, 'IN-MH', 'maharashtra', 'Maharashtra', 'state', items: 18);
    src(gt, i, 'IN-KA', 'karnataka', 'Karnataka', 'state', items: 16);
    src(gt, i, 'IN-DL', 'delhi', 'Delhi', 'state', items: 17);
    src(gn, i, 'IN-MH', 'mumbai', 'Mumbai', 'metro', query: 'Mumbai', items: 40);
    src(gn, i, 'IN-MH', 'pune', 'Pune', 'metro', query: 'Pune', items: 38);
    src(gn, i, 'IN-KA', 'bengaluru', 'Bengaluru', 'metro', query: 'Bengaluru', items: 40);
    src(gn, i, 'IN-WB', 'kolkata', 'Kolkata', 'metro', query: 'Kolkata', status: 'error', error: 'HTTP 503 from news.google.com (demo)', mins: 2);
    src(rd, i, 'IN-MH', 'mumbai', 'Mumbai', 'metro', query: 'mumbai', status: 'skipped', error: 'REDDIT_CLIENT_ID not set');
    src(gt, u, 'US', 'usa', 'United States', 'country', items: 20);
    src(gt, u, 'US-IL', 'illinois', 'Illinois', 'state', items: 15);
    src(gt, u, 'US-TX', 'texas', 'Texas', 'state', items: 19);
    src(gn, u, 'US-IL', 'chicago', 'Chicago', 'metro', query: 'Chicago', items: 40);
    src(gn, u, 'US-TX', 'houston', 'Houston', 'metro', query: 'Houston', items: 37);
    src(gn, u, 'US-NY', 'new-york', 'New York', 'metro', query: 'New York City', items: 40);
    src(gn, u, 'US-FL', 'miami', 'Miami', 'metro', query: 'Miami', enabled: false);
    src(rd, u, 'US-IL', 'chicago', 'Chicago', 'metro', query: 'chicago', status: 'skipped', error: 'REDDIT_CLIENT_ID not set');
  }

  Map<String, dynamic> _article({
    required String slug,
    required TrendsCountry country,
    required String place,
    required String placeSlug,
    required String headline,
    required List<String> summary,
    required String framing,
    required (String, String) labels,
    required List<(String, String)> sources,
    List<Map<String, dynamic>> updates = const [],
    bool sensitive = false,
  }) =>
      {
        'id': 'demo-$slug',
        'slug': slug,
        'country': country.name,
        'places': [
          {'slug': placeSlug, 'name': place, 'level': 'metro'},
        ],
        'headline': headline,
        'summary': summary,
        'perspectives': {
          'framing': framing,
          'a': {
            'label': labels.$1,
            'body': 'Sample text (demo). From the ${labels.$1.toLowerCase()} side, what matters most is what people in '
                '$place can do in the next few days: the cited reports describe the immediate situation and the '
                'practical steps residents and local businesses are taking, and why acting early tends to cost less.',
          },
          'b': {
            'label': labels.$2,
            'body': 'Sample text (demo). From the ${labels.$2.toLowerCase()} side, the same events point to longer '
                'questions for $place: planning, maintenance and how often this happens, which the cited sources '
                'also discuss, with figures that suggest the costs add up over a season rather than a single week.',
          },
        },
        'agree': 'Both views agree that clear information and comparing options early help people in $place decide.',
        'local_angle': 'For people in $place, the practical effect is on daily routines, travel and household costs this week.',
        'context': 'This is sample context written for the demo admin panel; the real pipeline writes it from the cited sources.',
        'watch_next': 'Watch official updates over the next 48 hours and whether the trend keeps rising in nearby areas.',
        'sources': [
          for (final (pub, url) in sources) {'publisher': pub, 'url': url, 'title': 'Sample report from $pub', 'snippet': 'Sample snippet (demo).'},
        ],
        'updates': updates,
        'corrections': <Map<String, dynamic>>[],
        'sensitive': sensitive,
        'review': {'approved_by': null, 'approved_at': null},
        'disclosure': 'AI-assisted, automatically published',
      };

  void _seedTopicsAndDrafts() {
    TrendTopic topic(String id, TrendsCountry c, String placeSlug, String place, String title, TopicStatus st, double v,
            {List<String> domains = const [], int signals = 6, int ageMins = 90, String? reason, String? slug, bool fired = true}) =>
        _topics[id] = TrendTopic(
          id: id,
          title: title,
          status: st,
          country: c,
          placeSlug: placeSlug,
          placeName: place,
          level: placeSlug == 'india' || placeSlug == 'usa' ? 'country' : 'metro',
          velocity: v,
          peakVelocity: v + 4,
          signalCount: signals,
          domainCount: domains.length,
          domains: domains,
          firstSeen: _ago(minutes: ageMins),
          lastSeen: _ago(minutes: 4),
          firedAt: fired && st != TopicStatus.watching && st != TopicStatus.waitingSources ? _ago(minutes: ageMins - 30) : null,
          statusReason: reason ?? (fired ? 'velocity ${v.round()}' : null),
          articleSlug: slug,
        );

    const i = TrendsCountry.india, u = TrendsCountry.usa;
    final pune = topic('t-pune-rains', i, 'pune', 'Pune', 'pune rains waterlogging', TopicStatus.drafted, 82,
        domains: ['hindustantimes.com', 'indiatimes.com', 'punemirror.com'], signals: 9);
    topic('t-pune-metro', i, 'pune', 'Pune', 'pune metro trial run', TopicStatus.watching, 41,
        domains: ['punemirror.com'], signals: 3, fired: false);
    final mumbai = topic('t-mumbai-heat', i, 'mumbai', 'Mumbai', 'mumbai heatwave ac demand', TopicStatus.published, 74,
        domains: ['indianexpress.com', 'mid-day.com', 'freepressjournal.in'], signals: 11, ageMins: 600, slug: 'mumbai-heatwave-ac-demand');
    topic('t-mumbai-train', i, 'mumbai', 'Mumbai', 'mumbai local train delays', TopicStatus.waitingSources, 66,
        domains: ['mid-day.com'], signals: 5, reason: 'fewer than 2 independent publishers', fired: false);
    final blr = topic('t-blr-police', i, 'bengaluru', 'Bengaluru', 'bengaluru traffic police new fines', TopicStatus.review, 70,
        domains: ['deccanherald.com', 'thehindu.com'], signals: 7, reason: 'sensitive: keyword:police');
    final delhi = topic('t-delhi-air', i, 'delhi', 'Delhi', 'delhi air quality severe', TopicStatus.review, 77,
        domains: ['hindustantimes.com', 'ndtv.com', 'thehindu.com'], signals: 12, reason: 'sensitive: tag:health');
    final chi1 = topic('t-chi-snow', u, 'chicago', 'Chicago', 'chicago first snow', TopicStatus.published, 68,
        domains: ['chicagotribune.com', 'suntimes.com', 'wgntv.com'], signals: 10, ageMins: 2000, slug: 'chicago-first-snow');
    final chi2 = topic('t-chi-snow-2', u, 'chicago', 'Chicago', 'chicago snow day two', TopicStatus.published, 59,
        domains: ['chicagotribune.com', 'nbcchicago.com'], signals: 6, ageMins: 700, slug: 'chicago-snow-day-two');
    final hou = topic('t-hou-power', u, 'houston', 'Houston', 'houston power outage heat', TopicStatus.fired, 79,
        domains: ['houstonchronicle.com', 'khou.com', 'click2houston.com'], signals: 8, ageMins: 40);
    final nyc = topic('t-nyc-fare', u, 'new-york', 'New York', 'nyc subway fare increase', TopicStatus.dropped, 63,
        domains: ['nytimes.com', 'gothamist.com'], signals: 6, ageMins: 300, reason: 'originality: rejected after one rewrite');
    topic('t-miami-tide', u, 'miami', 'Miami', 'miami king tide flooding', TopicStatus.ended, 12,
        domains: ['miamiherald.com', 'local10.com'], signals: 4, ageMins: 1300, reason: 'velocity below 10 for 6 h');

    Map<String, dynamic> gates({
      List<String>? domains,
      Map<String, dynamic>? sensitive,
      Map<String, dynamic>? originality,
      bool facts = true,
      int? words,
      bool balance = true,
      Map<String, dynamic>? caps,
    }) =>
        {
          'sources': {'passed': true, 'domains': domains ?? const [], 'detail': '${(domains ?? const []).length} independent publishers'},
          'sensitive': sensitive ?? {'passed': true, 'reasons': <String>[]},
          'originality': ?originality,
          if (originality != null && originality['passed'] == true && facts)
            'facts': {'passed': true, 'unsupported_claims_removed': 1, 'conflicts': false},
          if (words != null) 'value': {'passed': true, 'words': words},
          if (words != null && balance) 'balance': {'passed': true, 'ratio': 1.08, 'loaded_terms': <String>[]},
          'caps': ?caps,
        };

    void draft(String id, TrendTopic t, DraftStatus st,
        {Map<String, dynamic>? article,
        Map<String, dynamic> g = const {},
        String? failedGate,
        String? reason,
        bool sensitive = false,
        List<String> reasons = const [],
        String? stage,
        DateTime? publishedAt,
        String? supersededBy,
        String? noindexReason,
        int? visits,
        int rewrites = 0}) {
      _drafts[id] = {
        'id': id,
        'topic_id': t.id,
        'country': t.country!.name,
        'slug': article?['slug'] ?? t.articleSlug,
        'status': st.name,
        'velocity': t.velocity,
        'failed_gate': failedGate,
        'reason': reason,
        'gates': g,
        'sensitive': sensitive,
        'sensitive_reasons': reasons,
        'review_stage': stage,
        'topic_reviewed_by': null,
        'topic_reviewed_at': null,
        'reviewer_id': null,
        'reviewed_at': null,
        'review_note': null,
        'article': article,
        'rewrites': rewrites,
        'model': article == null ? null : 'claude-sonnet-5-5',
        'published_at': publishedAt == null ? null : _iso(publishedAt),
        'last_update_at': null,
        'superseded_by': supersededBy,
        'noindex_reason': noindexReason,
        'visits_14d_after_end': visits,
        'storage_path': publishedAt == null ? null : 'articles/${article?['slug']}.json',
        'dirty': false,
        'created_at': _iso(t.firedAt ?? t.firstSeen ?? now),
        'updated_at': _iso(now),
      };
      _signals[t.id] = [
        for (final (n, d) in t.domains.indexed)
          TrendSignal(
            id: '${t.id}-s$n',
            sourceKind: n == 0 ? 'google_trends' : 'google_news',
            topic: t.title,
            url: 'https://$d/sample-${t.placeSlug}-${n + 1}',
            publisher: d,
            publisherDomain: d,
            citable: true,
            snippet: 'Sample headline about ${t.title} from $d (demo).',
            score: 1.0 + n,
            firstSeen: t.firstSeen?.add(Duration(minutes: 5 * n)),
          ),
      ];
    }

    final orig = {'passed': true, 'max_similarity': 0.11, 'worst_source': 'indiatimes.com', 'long_quote': false, 'rewrites': 0};
    draft('d-pune-rains', pune, DraftStatus.queued,
        article: _article(
          slug: 'pune-rains-waterlogging',
          country: i,
          place: 'Pune',
          placeSlug: 'pune',
          headline: 'Pune: heavy rain leaves several roads waterlogged (sample)',
          summary: ['Sample: heavy overnight rain was reported across Pune.', 'Sample: several low-lying roads were waterlogged.', 'Sample: civic teams are clearing drains.'],
          framing: 'Short-term vs Long-term',
          labels: ('Short-term', 'Long-term'),
          sources: [('Hindustan Times', 'https://hindustantimes.com/sample'), ('Pune Mirror', 'https://punemirror.com/sample')],
        ),
        g: gates(
            domains: pune.domains,
            originality: orig,
            words: 486,
            caps: {'passed': false, 'reason': 'daily cap reached (2 of 2 today, india)', 'at': _iso(_ago(minutes: 4))}),
        reason: 'waiting for caps');
    draft('d-mumbai-heat', mumbai, DraftStatus.published,
        article: _article(
          slug: 'mumbai-heatwave-ac-demand',
          country: i,
          place: 'Mumbai',
          placeSlug: 'mumbai',
          headline: 'Mumbai heatwave pushes up demand for AC repairs (sample)',
          summary: ['Sample: temperatures stayed above normal for a fourth day.', 'Sample: repair shops report longer waits.', 'Sample: the weather office expects relief by the weekend.'],
          framing: 'Consumer view vs Business view',
          labels: ('Consumer view', 'Business view'),
          sources: [('Indian Express', 'https://indianexpress.com/sample'), ('Mid-day', 'https://mid-day.com/sample'), ('Free Press Journal', 'https://freepressjournal.in/sample')],
          updates: [
            {'at': _iso(_ago(hours: 2)), 'text': 'Sample update: the weather office extended the heat advisory by one day.'},
          ],
        ),
        g: gates(domains: mumbai.domains, originality: orig, words: 512, caps: {'passed': true, 'at': _iso(_ago(hours: 9))}),
        publishedAt: _ago(hours: 9));
    draft('d-blr-police', blr, DraftStatus.review,
        g: gates(domains: blr.domains, sensitive: {'passed': false, 'reasons': ['keyword:police'], 'review': 'pending', 'stage': 'topic'}),
        failedGate: 'sensitive',
        reason: 'sensitive topic: human review before drafting',
        sensitive: true,
        reasons: ['keyword:police'],
        stage: 'topic');
    draft('d-delhi-air', delhi, DraftStatus.review,
        article: _article(
          slug: 'delhi-air-quality-severe',
          country: i,
          place: 'Delhi',
          placeSlug: 'delhi',
          headline: 'Delhi air quality turns severe as winds drop (sample)',
          summary: ['Sample: the air quality index crossed the severe mark in several areas.', 'Sample: authorities announced graded restrictions.', 'Sample: forecasts expect stronger winds in two days.'],
          framing: 'Short-term vs Long-term',
          labels: ('Short-term', 'Long-term'),
          sources: [('Hindustan Times', 'https://hindustantimes.com/sample-air'), ('NDTV', 'https://ndtv.com/sample-air'), ('The Hindu', 'https://thehindu.com/sample-air')],
          sensitive: true,
        ),
        g: gates(
            domains: delhi.domains,
            sensitive: {'passed': false, 'reasons': ['tag:health'], 'review': 'pending', 'stage': 'content'},
            originality: orig,
            words: 455),
        failedGate: 'sensitive',
        reason: 'finished text is sensitive: human review before publishing',
        sensitive: true,
        reasons: ['tag:health'],
        stage: 'content');
    draft('d-chi-snow', chi1, DraftStatus.noindex,
        article: _article(
          slug: 'chicago-first-snow',
          country: u,
          place: 'Chicago',
          placeSlug: 'chicago',
          headline: 'Chicago prepares for the first heavy snow of the season (sample)',
          summary: ['Sample: forecasters expect the first significant snowfall.', 'Sample: hardware stores report more requests for snow blowers.', 'Sample: city crews are preparing salt and plows.'],
          framing: 'Short-term vs Long-term',
          labels: ('Short-term', 'Long-term'),
          sources: [('Chicago Tribune', 'https://chicagotribune.com/sample'), ('Sun-Times', 'https://suntimes.com/sample')],
        ),
        g: gates(domains: chi1.domains, originality: orig, words: 530, caps: {'passed': true, 'at': _iso(_ago(days: 2))}),
        publishedAt: _ago(days: 2),
        supersededBy: 'chicago-snow-day-two',
        noindexReason: 'superseded by chicago-snow-day-two');
    draft('d-chi-snow-2', chi2, DraftStatus.published,
        article: _article(
          slug: 'chicago-snow-day-two',
          country: u,
          place: 'Chicago',
          placeSlug: 'chicago',
          headline: 'Chicago snow, day two: side streets and furnace calls (sample)',
          summary: ['Sample: plows reached most main roads overnight.', 'Sample: side streets remain slow.', 'Sample: heating repair calls doubled.'],
          framing: 'Consumer view vs Business view',
          labels: ('Consumer view', 'Business view'),
          sources: [('Chicago Tribune', 'https://chicagotribune.com/sample-2'), ('NBC Chicago', 'https://nbcchicago.com/sample-2')],
        ),
        g: gates(domains: chi2.domains, originality: orig, words: 471, caps: {'passed': true, 'at': _iso(_ago(hours: 11))}),
        publishedAt: _ago(hours: 11),
        visits: 312);
    draft('d-hou-power', hou, DraftStatus.queued, g: gates(domains: hou.domains), reason: 'waiting for the Claude draft');
    draft('d-nyc-fare', nyc, DraftStatus.rejected,
        g: gates(
          domains: nyc.domains,
          originality: {'passed': false, 'max_similarity': 0.34, 'worst_source': 'nytimes.com', 'long_quote': false, 'rewrites': 1},
        ),
        failedGate: 'originality',
        reason: 'similarity 0.34 > 0.2 after one rewrite',
        rewrites: 1);

    void log(String decision, String? draftId, {String? reason, int minsAgo = 0, String? actor, Map<String, dynamic> details = const {}}) {
      final d = draftId == null ? null : _drafts[draftId];
      _log.add(TrendLogEntry(
        id: _logId++,
        draftId: draftId,
        slug: d?['slug'] as String?,
        country: TrendsCountry.parse(d?['country'] ?? details['country']),
        decision: decision,
        reason: reason,
        details: details,
        actorId: actor,
        createdAt: _ago(minutes: minsAgo),
      ));
    }

    log('published', 'd-chi-snow', minsAgo: 2880);
    log('published', 'd-chi-snow-2', minsAgo: 660);
    log('superseded', 'd-chi-snow', reason: 'chicago-snow-day-two', minsAgo: 650, actor: 'demo-admin');
    log('published', 'd-mumbai-heat', minsAgo: 540);
    log('updated', 'd-mumbai-heat', reason: 'new signals', minsAgo: 120);
    log('rejected', 'd-nyc-fare', reason: 'originality', minsAgo: 240);
    log('review', 'd-blr-police', reason: 'keyword:police', minsAgo: 50);
    log('review', 'd-delhi-air', reason: 'tag:health', minsAgo: 35);
    log('queued', 'd-pune-rains', minsAgo: 20);
    log('capped', 'd-pune-rains', reason: 'daily cap reached', minsAgo: 4);
  }

  // Helpers -------------------------------------------------------------------------------------------

  TrendDraft _draft(String id) {
    final d = _drafts[id];
    if (d == null) throw const TrendsException('draft_not_found', status: 404);
    final t = _topics[d['topic_id']];
    final article = d['article'] as Map<String, dynamic>?;
    return TrendDraft.fromJson({
      ...d,
      'headline': article?['headline'] ?? t?.title,
      'place': t?.placeName,
      'place_slug': t?.placeSlug,
      'reviewer_name': d['reviewer_id'] == null ? null : 'Demo Admin',
      'has_article': article != null,
      'article': null,
    });
  }

  TrendDraft _draftWithArticle(String id) {
    final base = _draft(id);
    return TrendDraft.fromJson({
      ..._drafts[id]!,
      'headline': base.headline,
      'place': base.place,
      'place_slug': base.placeSlug,
      'reviewer_name': base.reviewerName,
    });
  }

  void _decide(String decision, String? draftId, {String? reason, Map<String, dynamic> details = const {}}) {
    final d = draftId == null ? null : _drafts[draftId];
    _log.add(TrendLogEntry(
      id: _logId++,
      draftId: draftId,
      slug: d?['slug'] as String?,
      country: TrendsCountry.parse(d?['country'] ?? details['country']),
      decision: decision,
      reason: reason,
      details: details,
      actorId: _admin,
      createdAt: now,
    ));
  }

  Map<String, dynamic> _setting(String k) => Map<String, dynamic>.from(_settings[k] as Map? ?? const {});

  int _perDay(TrendsCountry c) {
    final levels = [for (final x in (_setting('caps')['ramp_levels'] as List? ?? const [1])) (x as num).toInt()];
    final level = ((_setting('ramp')[c.name] as Map?)?['level'] as num? ?? 0).toInt().clamp(0, levels.length - 1);
    final hard = (_setting('caps')['hard_max_per_day'] as num? ?? 20).toInt();
    return levels[level] < hard ? levels[level] : hard;
  }

  String? _healthProblem(TrendsCountry c) {
    final list = _health[c]!;
    return healthProblem(list.isEmpty ? null : list.last, Map<String, dynamic>.from(_setting('ramp')['health'] as Map? ?? const {}), now);
  }

  RunNowUsage _usage(TrendsFunction f) {
    final runs = (_adminRuns[f.fnName] ?? const <DateTime>[]).where((t) => t.isAfter(now.subtract(runNowWindow))).toList()..sort();
    final remaining = (runNowLimit - runs.length).clamp(0, runNowLimit);
    final retry = remaining > 0 ? 0 : runs.first.add(runNowWindow).difference(now).inSeconds.clamp(1, 3600);
    return RunNowUsage(used: runs.length, limit: runNowLimit, remaining: remaining, windowSeconds: runNowWindow.inSeconds, retryAfterSeconds: retry);
  }

  // Reads ---------------------------------------------------------------------------------------------

  @override
  Future<TrendBoard> board({TrendsCountry? country, int hours = 24}) async {
    await _latency();
    final since = now.subtract(Duration(hours: hours.clamp(1, 720)));
    final byPlace = <String, List<TrendTopic>>{};
    for (final t in _topics.values) {
      if (country != null && t.country != country) continue;
      if (t.lastSeen != null && t.lastSeen!.isBefore(since)) continue;
      byPlace.putIfAbsent('${t.country!.name}/${t.placeSlug}', () => []).add(t);
    }
    final places = [
      for (final ts in byPlace.values)
        TrendPlace(
          country: ts.first.country!,
          placeSlug: ts.first.placeSlug!,
          placeName: ts.first.placeName!,
          level: ts.first.level,
          maxVelocity: ts.map((t) => t.velocity).reduce((a, b) => a > b ? a : b),
          topics: ts..sort((a, b) => b.velocity.compareTo(a.velocity)),
        ),
    ]..sort((a, b) => b.maxVelocity.compareTo(a.maxVelocity));
    return TrendBoard(
      generatedAt: now,
      places: places,
      sources: [for (final s in _sources) if (country == null || s.country == country) s],
    );
  }

  @override
  Future<List<TrendTopic>> topics({TopicStatus? status, TrendsCountry? country, int limit = 100}) async {
    await _latency();
    final out = [
      for (final t in _topics.values)
        if ((status == null || t.status == status) && (country == null || t.country == country)) t,
    ]..sort((a, b) => (b.firedAt ?? b.lastSeen ?? now).compareTo(a.firedAt ?? a.lastSeen ?? now));
    return out.take(limit).toList();
  }

  @override
  Future<List<TrendDraft>> drafts({DraftStatus? status, TrendsCountry? country, int limit = 100, int offset = 0}) async {
    await _latency();
    final out = [
      for (final id in _drafts.keys) _draft(id),
    ].where((d) => (status == null || d.status == status) && (country == null || d.country == country)).toList()
      ..sort((a, b) => (b.publishedAt ?? b.createdAt).compareTo(a.publishedAt ?? a.createdAt));
    return out.skip(offset).take(limit).toList();
  }

  @override
  Future<TrendDraftDetail> draft(String id) async {
    await _latency();
    final d = _draftWithArticle(id);
    return TrendDraftDetail(
      draft: d,
      topic: _topics[d.topicId],
      signals: _signals[d.topicId] ?? const [],
      log: _log.where((l) => l.draftId == id).toList().reversed.toList(),
    );
  }

  @override
  Future<List<TrendDraft>> reviewQueue({TrendsCountry? country}) async {
    await _latency();
    return [
      for (final id in _drafts.keys)
        if (_drafts[id]!['status'] == 'review' && (country == null || _drafts[id]!['country'] == country.name)) _draftWithArticle(id),
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  Future<TrendSettingsSnapshot> settings() async {
    await _latency();
    return TrendSettingsSnapshot(
      settings: {for (final e in _settings.entries) e.key: e.value},
      descriptions: Map.of(_descriptions),
      perDay: {for (final c in TrendsCountry.values) c: _perDay(c)},
      health: {for (final c in TrendsCountry.values) c: _health[c]!.isEmpty ? null : _health[c]!.last},
      healthProblems: {for (final c in TrendsCountry.values) c: _healthProblem(c)},
      published24h: {
        for (final c in TrendsCountry.values)
          c: _drafts.values.where((d) {
            final p = DateTime.tryParse('${d['published_at']}');
            return d['country'] == c.name && p != null && p.isAfter(now.subtract(const Duration(hours: 24)));
          }).length,
      },
      runs: Map.of(_runs),
      runNow: {for (final f in TrendsFunction.values) f.fnName: _usage(f)},
    );
  }

  @override
  Future<List<TrendLogEntry>> publishLog({int limit = 100, String? draftId}) async {
    await _latency();
    return _log.reversed.where((l) => draftId == null || l.draftId == draftId).take(limit).toList();
  }

  // Changes -----------------------------------------------------------------------------------------

  @override
  Future<TrendDraft> review(String id, {required bool approve, String? note}) async {
    await _latency();
    final d = _drafts[id];
    if (d == null) throw const TrendsException('draft_not_found', status: 404);
    if (d['status'] != 'review') throw const TrendsException('draft_not_in_review', status: 409);
    final stage = (d['review_stage'] as String?) ?? (d['article'] == null ? 'topic' : 'content');
    final gates = Map<String, dynamic>.from(d['gates'] as Map? ?? const {});
    final sens = Map<String, dynamic>.from(gates['sensitive'] as Map? ?? const {});
    final t = _topics[d['topic_id']];
    TrendTopic topicWith(TopicStatus st, String reason) => TrendTopic(
          id: t!.id,
          title: t.title,
          status: st,
          country: t.country,
          placeSlug: t.placeSlug,
          placeName: t.placeName,
          level: t.level,
          velocity: t.velocity,
          peakVelocity: t.peakVelocity,
          signalCount: t.signalCount,
          domainCount: t.domainCount,
          domains: t.domains,
          firstSeen: t.firstSeen,
          lastSeen: t.lastSeen,
          firedAt: t.firedAt,
          statusReason: reason,
          articleSlug: t.articleSlug,
        );
    if (!approve) {
      gates['sensitive'] = {...sens, 'passed': false, 'review': 'rejected', 'stage': stage};
      d.addAll({
        'status': 'rejected',
        'failed_gate': 'sensitive',
        'reason': (note ?? '').trim().isEmpty ? 'rejected by reviewer' : note,
        'reviewer_id': _admin,
        'reviewed_at': _iso(now),
        'review_note': note,
        'gates': gates,
      });
      if (t != null) _topics[t.id] = topicWith(TopicStatus.dropped, 'review_rejected');
    } else if (stage == 'topic') {
      gates['sensitive'] = {...sens, 'topic_approved': true};
      d.addAll({
        'status': 'queued',
        'review_stage': null,
        'topic_reviewed_by': _admin,
        'topic_reviewed_at': _iso(now),
        'review_note': note,
        'gates': gates,
      });
      if (t != null) _topics[t.id] = topicWith(TopicStatus.fired, 'topic_approved');
    } else {
      gates['sensitive'] = {...sens, 'passed': true, 'review': 'approved'};
      final article = Map<String, dynamic>.from(d['article'] as Map);
      article['review'] = {'approved_by': 'editor:${_admin.length > 8 ? _admin.substring(0, 8) : _admin}', 'approved_at': _iso(now)};
      d.addAll({
        'status': 'queued',
        'review_stage': null,
        'reviewer_id': _admin,
        'reviewed_at': _iso(now),
        'review_note': note,
        'article': article,
        'gates': gates,
      });
    }
    _decide(approve ? 'review_approved' : 'review_rejected', id, reason: note, details: {'stage': stage});
    s.log('admin_trends_review', targetType: 'trend_draft', targetId: id, details: {'approve': approve, 'stage': stage, 'note': note});
    s.touch();
    return _draft(id);
  }

  @override
  Future<Object?> setSetting(String key, Object value) async {
    await _latency();
    if (key == 'publishing') throw const TrendsException('use_admin_trends_set_kill_switch', status: 400);
    if (!_settings.containsKey(key)) throw const TrendsException('unknown_setting', status: 404);
    final old = _settings[key];
    final merged = mergeSetting(key, old, value);
    final problems = trendSettingProblems(key, old, merged);
    if (problems.isNotEmpty) {
      throw problems.first == 'invalid_setting_type'
          ? const TrendsException('invalid_setting_type', status: 400)
          : TrendsException('invalid_setting_value', detail: problems.first, status: 400);
    }
    _settings[key] = merged;
    s.log('admin_trends_set_setting', targetType: 'trend_setting', targetId: key, details: {'from': old, 'to': merged});
    s.touch();
    return merged;
  }

  @override
  Future<PublishingState> setKillSwitch({required bool paused, String? reason}) async {
    await _latency();
    final old = PublishingState.fromJson(_settings['publishing']);
    final r = (reason ?? '').trim().isEmpty ? null : reason!.trim();
    _settings['publishing'] = paused
        ? {'paused': true, 'paused_at': _iso(old.paused ? (old.pausedAt ?? now) : now), 'paused_reason': r, 'paused_by': _admin}
        : {'paused': false, 'paused_at': null, 'paused_reason': null, 'resumed_reason': r, 'resumed_by': _admin};
    _decide('kill_switch', null, reason: r, details: {'paused': paused});
    s.log('admin_trends_set_kill_switch', targetType: 'trend_setting', targetId: 'publishing', details: {'paused': paused, 'reason': r});
    s.touch();
    return PublishingState.fromJson(_settings['publishing']);
  }

  @override
  Future<void> setRamp(TrendsCountry country, int level, {String? reason}) async {
    await _latency();
    final ramp = _setting('ramp');
    final levels = (_setting('caps')['ramp_levels'] as List? ?? const []).length;
    final cur = ((ramp[country.name] as Map?)?['level'] as num? ?? 0).toInt();
    final changed = DateTime.tryParse('${(ramp[country.name] as Map?)?['changed_at']}');
    if (level < 0 || level >= levels) throw const TrendsException('invalid_ramp_level', status: 400);
    if (level == cur) return;
    if (level > cur) {
      if (level > cur + 1) throw const TrendsException('ramp_one_level_at_a_time', status: 409);
      final minDays = (ramp['min_days_between_steps'] as num? ?? 30).toInt();
      if (changed != null && changed.isAfter(now.subtract(Duration(days: minDays)))) {
        throw const TrendsException('ramp_step_too_soon', status: 409);
      }
      final problem = _healthProblem(country);
      if (problem != null) throw TrendsException('ramp_unhealthy', detail: problem, status: 409);
    }
    ramp[country.name] = {'level': level, 'changed_at': _iso(now), 'changed_by': 'admin'};
    _settings['ramp'] = ramp;
    _decide(level > cur ? 'ramp_up' : 'ramp_down', null,
        reason: reason, details: {'country': country.name, 'from': cur, 'to': level, 'per_day': _perDay(country)});
    s.log('admin_trends_set_ramp', targetType: 'trend_setting', targetId: 'ramp', details: {'country': country.name, 'from': cur, 'to': level});
    s.touch();
  }

  @override
  Future<HealthResult> recordHealth(HealthInput input) async {
    await _latency();
    final err = input.validate();
    if (err != null) throw TrendsException(err, status: 400);
    final h = TrendHealth(
      country: input.country,
      recordedAt: now,
      indexedShare: input.indexedShare,
      clicks7d: input.clicks7d,
      clicksPrev7d: input.clicksPrev7d,
      scWarnings: input.scWarnings,
      manualAction: input.manualAction,
      errorReports24h: input.errorReports24h,
      note: input.note,
    );
    _health[input.country]!.add(h);
    final maxErr = ((_setting('ramp')['health'] as Map?)?['max_error_reports_24h'] as num? ?? 5).toInt();
    final pause = h.manualAction ? 'search_console_manual_action' : (h.errorReports24h > maxErr ? 'error_report_spike' : null);
    if (pause != null && !PublishingState.fromJson(_settings['publishing']).paused) {
      _settings['publishing'] = {'paused': true, 'paused_at': _iso(now), 'paused_reason': pause, 'paused_by': 'auto'};
      _decide('auto_pause', null, reason: pause, details: {'country': input.country.name});
    }
    s.log('admin_trends_record_health', targetType: 'trend_health', targetId: input.country.name, details: input.toParams());
    s.touch();
    return HealthResult(health: h, autoPause: pause, healthProblem: _healthProblem(input.country));
  }

  String _idBySlug(String slug, {Set<String> statuses = const {'published', 'noindex'}}) {
    for (final e in _drafts.entries) {
      if (e.value['slug'] == slug && statuses.contains(e.value['status'])) return e.key;
    }
    throw const TrendsException('draft_not_found', status: 404);
  }

  @override
  Future<TrendDraft> recordTraffic(String slug, int visits14d) async {
    await _latency();
    if (visits14d < 0) throw const TrendsException('invalid_visits', status: 400);
    final id = _idBySlug(slug);
    _drafts[id]!.addAll({'visits_14d_after_end': visits14d, 'dirty': true});
    s.log('admin_trends_record_traffic', targetType: 'trend_draft', targetId: id, details: {'slug': slug, 'visits_14d_after_end': visits14d});
    s.touch();
    return _draft(id);
  }

  @override
  Future<TrendDraft> setDraftStatus(String id, DraftAction action, {String? reason}) async {
    await _latency();
    final cur = _draft(id);
    if (!allowedDraftActions(cur).contains(action)) {
      throw TrendsException('invalid_draft_action', detail: '${action.wire} from ${cur.status.name}', status: 409);
    }
    final d = _drafts[id]!;
    final r = (reason ?? '').trim().isEmpty ? null : reason!.trim();
    switch (action) {
      case DraftAction.reject:
        d.addAll({'status': 'rejected', 'failed_gate': d['failed_gate'] ?? 'manual', 'reason': r ?? 'rejected by admin'});
      case DraftAction.noindex:
        d.addAll({'status': 'noindex', 'noindex_reason': r ?? 'manual', 'dirty': true});
      case DraftAction.reindex:
        d.addAll({'status': 'published', 'noindex_reason': null, 'dirty': true});
      case DraftAction.unpublish:
        d.addAll({'status': 'rejected', 'failed_gate': 'manual', 'reason': r ?? 'unpublished by admin', 'dirty': true});
    }
    _decide(
        switch (action) {
          DraftAction.reject => 'rejected',
          DraftAction.unpublish => 'unpublished',
          DraftAction.reindex => 'indexed',
          DraftAction.noindex => 'noindex',
        },
        id,
        reason: r,
        details: {'from': cur.status.name, 'manual': true});
    s.log('admin_trends_set_draft_status', targetType: 'trend_draft', targetId: id,
        details: {'action': action.wire, 'from': cur.status.name, 'to': d['status'], 'reason': r});
    s.touch();
    return _draft(id);
  }

  @override
  Future<TrendDraft> addCorrection(String id, String text) async {
    await _latency();
    if (text.trim().length < 10) throw const TrendsException('correction_too_short', status: 400);
    final cur = _draft(id);
    if (cur.status != DraftStatus.published && cur.status != DraftStatus.noindex) {
      throw const TrendsException('draft_not_published', status: 409);
    }
    final d = _drafts[id]!;
    final article = Map<String, dynamic>.from(d['article'] as Map);
    article['corrections'] = [
      ...(article['corrections'] as List? ?? const []),
      {'at': _iso(now), 'text': text.trim()},
    ];
    article['updated_at'] = _iso(now);
    d.addAll({'article': article, 'dirty': true});
    _decide('corrected', id, reason: text.trim(), details: {'manual': true});
    s.log('admin_trends_add_correction', targetType: 'trend_draft', targetId: id, details: {'slug': d['slug'], 'text': text.trim()});
    s.touch();
    return _draft(id);
  }

  @override
  Future<TrendDraft> supersede(String slug, String bySlug) async {
    await _latency();
    if (slug == bySlug) throw const TrendsException('invalid_supersede', status: 400);
    try {
      _idBySlug(bySlug);
    } on TrendsException {
      throw const TrendsException('superseding_article_not_found', status: 404);
    }
    final id = _idBySlug(slug);
    _drafts[id]!.addAll({'superseded_by': bySlug, 'status': 'noindex', 'noindex_reason': 'superseded by $bySlug', 'dirty': true});
    _decide('superseded', id, reason: bySlug, details: {'manual': true});
    s.log('admin_trends_supersede', targetType: 'trend_draft', targetId: id, details: {'slug': slug, 'superseded_by': bySlug});
    s.touch();
    return _draft(id);
  }

  @override
  Future<TrendSource> addSource(TrendSourceDraft source) async {
    await _latency();
    final err = source.validate();
    if (err != null) throw TrendsException('invalid_source', detail: err, status: 400);
    final j = source.toJson();
    if (_sources.any((x) => x.kind.wire == j['kind'] && x.geo == j['geo'] && x.placeSlug == j['place_slug'] && x.query == j['query'])) {
      throw const TrendsException('source_exists', status: 409);
    }
    final src = TrendSource.fromJson({...j, 'id': _sourceId++});
    _sources.add(src);
    s.log('admin_trends_upsert_source', targetType: 'trend_source', targetId: '${src.id}', details: j);
    s.touch();
    return src;
  }

  @override
  Future<TrendSource> setSourceEnabled(int id, bool enabled) async {
    await _latency();
    final i = _sources.indexWhere((x) => x.id == id);
    if (i < 0) throw const TrendsException('source_not_found', status: 404);
    _sources[i] = _sources[i].copyWith(enabled: enabled);
    s.log('admin_trends_upsert_source', targetType: 'trend_source', targetId: '$id', details: {'enabled': enabled});
    s.touch();
    return _sources[i];
  }

  @override
  Future<RunNowResult> runNow(TrendsFunction fn) async {
    await _latency();
    final usage = _usage(fn);
    if (usage.remaining <= 0) {
      throw TrendsRateLimited(
        retryAfterSeconds: usage.retryAfterSeconds,
        limit: usage.limit,
        windowSeconds: usage.windowSeconds,
        detail: 'at most ${usage.limit} admin runs of ${fn.fnName} per 60 minutes',
      );
    }
    _adminRuns.putIfAbsent(fn.fnName, () => []).add(now);
    final paused = PublishingState.fromJson(_settings['publishing']).paused;
    final stats = switch (fn) {
      TrendsFunction.poll => {
          'sources': _sources.where((x) => x.enabled).length,
          'signals_seen': 0,
          'signals_new': 0,
          'topics_new': 0,
          'fired': <String>[],
        },
      TrendsFunction.draft => paused ? {'paused': true} : {'considered': 0, 'queued': 0, 'review': 0},
      TrendsFunction.publish => paused ? {'paused': true} : {'published': <String>[], 'capped': 0, 'uploaded': 0},
    };
    _runs[fn.fnName] = TrendRun(fn: fn.fnName, startedAt: now, finishedAt: now, ok: true, dryRun: true, stats: stats, trigger: 'admin');
    s.log('admin_trends_run_now', targetType: 'trend_run', targetId: fn.fnName, details: {'demo': true});
    s.touch();
    return RunNowResult(ok: true, dryRun: true, reason: 'demo mode: nothing polled, drafted or published', stats: stats);
  }
}
