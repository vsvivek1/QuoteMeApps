/// Trends news site (brief Section 21.10): live trend board, fired topics,
/// drafts with per-gate results, the sensitive-topic review queue, caps /
/// ramp / thresholds, kill switch, health inputs and "Run now".
///
/// Everything goes through the `admin_trends_*` RPCs (the `trends` schema is
/// not exposed through PostgREST) and the `trends-*` Edge Functions; see
/// admin/TRENDS_ADMIN_NEEDS.md and supabase/API.md section 13.
library;

// Helpers -----------------------------------------------------------------------------------------

DateTime? _ts(Object? v) => v == null ? null : DateTime.tryParse(v.toString());
int _int(Object? v, [int d = 0]) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? d;
int? _intN(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');
double _num(Object? v, [double d = 0]) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? d;
double? _numN(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');
String? _str(Object? v) => v == null ? null : '$v';
List<String> _strs(Object? v) => [for (final x in (v is List ? v : const [])) '$x'];
Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

/// The pipeline runs in one project and covers both countries.
enum TrendsCountry {
  usa,
  india;

  static TrendsCountry? parse(Object? v) => switch ('$v') {
        'usa' => usa,
        'india' => india,
        _ => null,
      };
}

/// The three pipeline Edge Functions ("Run now").
enum TrendsFunction {
  poll('trends-poll'),
  draft('trends-draft'),
  publish('trends-publish');

  const TrendsFunction(this.fnName);
  final String fnName;
}

/// Thrown by both repositories with the server's stable code (`PTnnn` → status
/// `nnn`, message = code) and, when given, the detail (e.g. which floor).
class TrendsException implements Exception {
  const TrendsException(this.code, {this.detail, this.status});
  final String code;
  final String? detail;
  final int? status;

  @override
  String toString() => detail == null || detail!.isEmpty ? code : '$code: $detail';
}

/// `429 rate_limited` from a trends Edge Function "Run now" (migration 1300).
class TrendsRateLimited extends TrendsException {
  const TrendsRateLimited({required this.retryAfterSeconds, required this.limit, required this.windowSeconds, super.detail})
      : super('rate_limited', status: 429);
  final int retryAfterSeconds;
  final int limit;
  final int windowSeconds;
}

/// Maps an Edge Function error body (`{code, message, details, hint}`) and its
/// HTTP status, plus the Retry-After header when the client exposes it.
TrendsException trendsFunctionError(int status, Object? body, {String? retryAfterHeader}) {
  final b = _map(body);
  final code = _str(b['code']) ?? _str(b['message']) ?? 'trends_run_failed';
  final details = b['details'];
  if (status == 429 || code == 'rate_limited') {
    final d = _map(details);
    final retry = _intN(retryAfterHeader) ?? _intN(d['retry_after_seconds']) ?? 60;
    return TrendsRateLimited(
      retryAfterSeconds: retry < 1 ? 1 : retry,
      limit: _int(d['limit'], 6),
      windowSeconds: _int(d['window_seconds'], 3600),
      detail: _str(b['hint']),
    );
  }
  return TrendsException(code, detail: details is String ? details : (details == null ? null : '$details'), status: status);
}

/// Maps a PostgREST error (`code` PTnnn, message = stable code, details) to a TrendsException.
TrendsException trendsRpcError({String? code, required String message, Object? details}) {
  final m = RegExp(r'^PT(\d{3})$').firstMatch(code ?? '');
  final status = m != null ? int.parse(m.group(1)!) : (code == '42501' ? 403 : null);
  final d = details == null || '$details'.isEmpty ? null : '$details';
  return TrendsException(message, detail: d, status: status);
}

// Board ------------------------------------------------------------------------------------------

enum TopicStatus {
  watching,
  fired,
  review,
  drafted,
  published,
  waitingSources,
  dropped,
  ended;

  String get wire => this == waitingSources ? 'waiting_sources' : name;

  static TopicStatus parse(Object? v) =>
      TopicStatus.values.firstWhere((s) => s.wire == '$v', orElse: () => watching);
}

class TrendTopic {
  const TrendTopic({
    required this.id,
    required this.title,
    required this.status,
    this.country,
    this.placeSlug,
    this.placeName,
    this.level,
    this.velocity = 0,
    this.peakVelocity = 0,
    this.signalCount = 0,
    this.domainCount = 0,
    this.domains = const [],
    this.firstSeen,
    this.lastSeen,
    this.firedAt,
    this.statusReason,
    this.articleSlug,
  });

  /// Works for the board's topic objects and for full `trend_topics` rows.
  factory TrendTopic.fromJson(Map<String, dynamic> j) => TrendTopic(
        id: '${j['id']}',
        title: _str(j['title']) ?? '',
        status: TopicStatus.parse(j['status']),
        country: TrendsCountry.parse(j['country']),
        placeSlug: _str(j['place_slug']),
        placeName: _str(j['place_name']),
        level: _str(j['level']),
        velocity: _num(j['velocity']),
        peakVelocity: _num(j['peak_velocity']),
        signalCount: _int(j['signal_count']),
        domainCount: _int(j['domain_count']),
        domains: _strs(j['domains']),
        firstSeen: _ts(j['first_seen']),
        lastSeen: _ts(j['last_seen']),
        firedAt: _ts(j['fired_at']),
        statusReason: _str(j['status_reason']),
        articleSlug: _str(j['article_slug']),
      );

  final String id;
  final String title;
  final TopicStatus status;
  final TrendsCountry? country;
  final String? placeSlug;
  final String? placeName;
  final String? level;
  final double velocity;
  final double peakVelocity;
  final int signalCount;
  final int domainCount;
  final List<String> domains;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final DateTime? firedAt;
  final String? statusReason;
  final String? articleSlug;
}

class TrendPlace {
  const TrendPlace({
    required this.country,
    required this.placeSlug,
    required this.placeName,
    this.level,
    this.maxVelocity = 0,
    this.topics = const [],
  });

  factory TrendPlace.fromJson(Map<String, dynamic> j) {
    final country = TrendsCountry.parse(j['country']);
    return TrendPlace(
      country: country ?? TrendsCountry.usa,
      placeSlug: _str(j['place_slug']) ?? '',
      placeName: _str(j['place_name']) ?? _str(j['place_slug']) ?? '',
      level: _str(j['level']),
      maxVelocity: _num(j['max_velocity']),
      topics: [
        for (final t in (j['topics'] as List? ?? const []))
          TrendTopic.fromJson({
            'country': j['country'],
            'place_slug': j['place_slug'],
            'place_name': j['place_name'],
            'level': j['level'],
            ..._map(t),
          }),
      ],
    );
  }

  final TrendsCountry country;
  final String placeSlug;
  final String placeName;
  final String? level;
  final double maxVelocity;
  final List<TrendTopic> topics;
}

enum SourceKind {
  googleTrends('google_trends'),
  googleNews('google_news'),
  reddit('reddit');

  const SourceKind(this.wire);
  final String wire;

  static SourceKind parse(Object? v) => SourceKind.values.firstWhere((k) => k.wire == '$v', orElse: () => googleNews);
}

const placeLevels = ['country', 'state', 'metro'];

class TrendSource {
  const TrendSource({
    required this.id,
    required this.kind,
    required this.country,
    required this.geo,
    required this.placeSlug,
    required this.placeName,
    required this.level,
    this.state,
    this.query,
    this.enabled = true,
    this.lastPolledAt,
    this.lastStatus,
    this.lastError,
    this.lastItems,
  });

  factory TrendSource.fromJson(Map<String, dynamic> j) => TrendSource(
        id: _int(j['id']),
        kind: SourceKind.parse(j['kind']),
        country: TrendsCountry.parse(j['country']) ?? TrendsCountry.usa,
        geo: _str(j['geo']) ?? '',
        placeSlug: _str(j['place_slug']) ?? '',
        placeName: _str(j['place_name']) ?? '',
        state: _str(j['state']),
        level: _str(j['level']) ?? 'metro',
        query: _str(j['query']),
        enabled: j['enabled'] != false,
        lastPolledAt: _ts(j['last_polled_at']),
        lastStatus: _str(j['last_status']),
        lastError: _str(j['last_error']),
        lastItems: _intN(j['last_items']),
      );

  final int id;
  final SourceKind kind;
  final TrendsCountry country;
  final String geo;
  final String placeSlug;
  final String placeName;
  final String? state;
  final String level;
  final String? query;
  final bool enabled;
  final DateTime? lastPolledAt;

  /// ok | error | skipped
  final String? lastStatus;
  final String? lastError;
  final int? lastItems;

  /// An enabled feed whose last poll failed: a blind spot on the board.
  bool get failing => enabled && lastStatus == 'error';

  /// Enabled but not polled for [maxAge] (default: 3 poll intervals).
  bool stale(DateTime now, {Duration maxAge = const Duration(minutes: 15)}) =>
      enabled && (lastPolledAt == null || now.difference(lastPolledAt!) > maxAge);

  TrendSource copyWith({bool? enabled}) => TrendSource(
        id: id,
        kind: kind,
        country: country,
        geo: geo,
        placeSlug: placeSlug,
        placeName: placeName,
        state: state,
        level: level,
        query: query,
        enabled: enabled ?? this.enabled,
        lastPolledAt: lastPolledAt,
        lastStatus: lastStatus,
        lastError: lastError,
        lastItems: lastItems,
      );
}

final _geoRe = RegExp(r'^(IN|US)(-[A-Z]{2})?$');
final _slugRe = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

/// A new polled source for `admin_trends_upsert_source`.
class TrendSourceDraft {
  const TrendSourceDraft({
    required this.kind,
    required this.country,
    required this.geo,
    required this.placeSlug,
    required this.placeName,
    required this.level,
    this.state,
    this.query,
  });

  final SourceKind kind;
  final TrendsCountry country;
  final String geo;
  final String placeSlug;
  final String placeName;
  final String level;
  final String? state;
  final String? query;

  /// Same checks as the RPC (geo format, query required except for Google
  /// Trends), plus geo/country agreement. Returns an error code or null.
  String? validate() {
    final g = geo.trim().toUpperCase();
    if (!_geoRe.hasMatch(g)) return 'invalid_geo';
    if ((country == TrendsCountry.india) != g.startsWith('IN')) return 'geo_country_mismatch';
    if (!_slugRe.hasMatch(placeSlug.trim())) return 'invalid_place_slug';
    if (placeName.trim().isEmpty) return 'invalid_place_name';
    if (!placeLevels.contains(level)) return 'invalid_level';
    if (kind != SourceKind.googleTrends && (query ?? '').trim().isEmpty) return 'query_required';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.wire,
        'country': country.name,
        'geo': geo.trim().toUpperCase(),
        'place_slug': placeSlug.trim(),
        'place_name': placeName.trim(),
        'level': level,
        if ((state ?? '').trim().isNotEmpty) 'state': state!.trim(),
        if ((query ?? '').trim().isNotEmpty) 'query': query!.trim(),
        'enabled': true,
      };
}

class TrendBoard {
  const TrendBoard({required this.generatedAt, this.places = const [], this.sources = const []});

  factory TrendBoard.fromJson(Map<String, dynamic> j) => TrendBoard(
        generatedAt: _ts(j['generated_at']) ?? DateTime.now(),
        places: [for (final p in (j['places'] as List? ?? const [])) TrendPlace.fromJson(_map(p))],
        sources: [for (final s in (j['sources'] as List? ?? const [])) TrendSource.fromJson(_map(s))],
      );

  final DateTime generatedAt;

  /// Hottest place first.
  final List<TrendPlace> places;
  final List<TrendSource> sources;

  List<TrendSource> get failingSources => sources.where((s) => s.failing).toList();

  /// Places whose name or slug contains [query] (case-insensitive).
  List<TrendPlace> placesMatching(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return places;
    return places.where((p) => p.placeName.toLowerCase().contains(q) || p.placeSlug.contains(q)).toList();
  }
}

// Drafts -----------------------------------------------------------------------------------------

enum DraftStatus {
  queued,
  review,
  rejected,
  published,
  noindex;

  static DraftStatus parse(Object? v) => DraftStatus.values.firstWhere((s) => s.name == '$v', orElse: () => queued);
}

/// `admin_trends_set_draft_status` actions ([wire] is the RPC value).
enum DraftAction {
  reject,
  noindex,
  reindex,
  unpublish;

  String get wire => this == reindex ? 'index' : name;
}

/// One gate's result from `trend_drafts.gates`.
class GateResult {
  const GateResult(this.key, this.data);
  final String key;
  final Map<String, dynamic> data;

  /// true / false; null when the gate is waiting (e.g. sensitive topic in review).
  bool? get passed => data['passed'] is bool ? data['passed'] as bool : null;

  /// Pipeline order (1, 2, 3, 4, 5, 5b, 6).
  static const order = ['sources', 'sensitive', 'originality', 'facts', 'value', 'balance', 'caps'];
  static const numbers = {
    'sources': '1',
    'sensitive': '2',
    'originality': '3',
    'facts': '4',
    'value': '5',
    'balance': '5b',
    'caps': '6',
  };

  /// Short technical summary of the useful fields (API.md / TRENDS_ADMIN_NEEDS.md table).
  String get summary {
    final d = data;
    String? fmt(Object? v) => v is num ? (v is int ? '$v' : v.toStringAsFixed(2)) : (v == null ? null : '$v');
    final parts = switch (key) {
      'sources' => [
          if (d['domains'] is List) '${(d['domains'] as List).length} domains: ${_strs(d['domains']).join(', ')}',
          fmt(d['detail']),
        ],
      'sensitive' => [
          if (_strs(d['reasons']).isNotEmpty) _strs(d['reasons']).join(', '),
          if (d['topic_approved'] == true) 'topic approved',
          if (d['review'] != null) 'review: ${d['review']}',
          if (d['stage'] != null) 'stage: ${d['stage']}',
        ],
      'originality' => [
          if (d['max_similarity'] != null) 'similarity ${fmt(d['max_similarity'])}',
          if (d['worst_source'] != null) 'worst: ${d['worst_source']}',
          if (d['long_quote'] == true) 'long quote',
          if (d['rewrites'] != null) 'rewrites ${d['rewrites']}',
        ],
      'facts' => [
          if (d['unsupported_claims_removed'] != null) '${d['unsupported_claims_removed']} unsupported removed',
          if (d['conflicts'] == true) 'sources conflict',
          fmt(d['notes']),
        ],
      'value' => [if (d['words'] != null) '${d['words']} words', fmt(d['reason'])],
      'balance' => [
          if (d['ratio'] != null) 'ratio ${fmt(d['ratio'])}',
          if (d['weaker_side'] != null) 'weaker: ${d['weaker_side']}',
          if (_strs(d['loaded_terms']).isNotEmpty) 'loaded: ${_strs(d['loaded_terms']).join(', ')}',
          fmt(d['reason']),
        ],
      'caps' => [fmt(d['reason'])],
      _ => [for (final e in d.entries) if (e.key != 'passed') '${e.key}: ${e.value}'],
    };
    return parts.whereType<String>().where((s) => s.isNotEmpty).join('; ');
  }
}

/// Gate results in pipeline order (unknown keys last, in their stored order).
List<GateResult> parseGates(Object? gates) {
  final m = _map(gates);
  return [
    for (final k in GateResult.order)
      if (m[k] is Map) GateResult(k, _map(m[k])),
    for (final e in m.entries)
      if (!GateResult.order.contains(e.key) && e.value is Map) GateResult(e.key, _map(e.value)),
  ];
}

class TrendDraft {
  const TrendDraft({
    required this.id,
    required this.country,
    required this.status,
    required this.createdAt,
    this.topicId,
    this.slug,
    this.headline,
    this.place,
    this.placeSlug,
    this.velocity,
    this.failedGate,
    this.reason,
    this.gates = const [],
    this.sensitive = false,
    this.sensitiveReasons = const [],
    this.reviewStage,
    this.topicReviewedBy,
    this.topicReviewedAt,
    this.reviewerId,
    this.reviewerName,
    this.reviewedAt,
    this.reviewNote,
    this.hasArticle = false,
    this.rewrites = 0,
    this.model,
    this.publishedAt,
    this.lastUpdateAt,
    this.supersededBy,
    this.noindexReason,
    this.visits14dAfterEnd,
    this.storagePath,
    this.dirty = false,
    this.updatedAt,
    this.article,
  });

  factory TrendDraft.fromJson(Map<String, dynamic> j) => TrendDraft(
        id: '${j['id']}',
        topicId: _str(j['topic_id']),
        country: TrendsCountry.parse(j['country']) ?? TrendsCountry.usa,
        slug: _str(j['slug']),
        status: DraftStatus.parse(j['status']),
        headline: _str(j['headline']),
        place: _str(j['place']),
        placeSlug: _str(j['place_slug']),
        velocity: _numN(j['velocity']),
        failedGate: _str(j['failed_gate']),
        reason: _str(j['reason']),
        gates: parseGates(j['gates']),
        sensitive: j['sensitive'] == true,
        sensitiveReasons: _strs(j['sensitive_reasons']),
        reviewStage: _str(j['review_stage']),
        topicReviewedBy: _str(j['topic_reviewed_by']),
        topicReviewedAt: _ts(j['topic_reviewed_at']),
        reviewerId: _str(j['reviewer_id']),
        reviewerName: _str(j['reviewer_name']),
        reviewedAt: _ts(j['reviewed_at']),
        reviewNote: _str(j['review_note']),
        hasArticle: j['has_article'] == true || j['article'] is Map,
        rewrites: _int(j['rewrites']),
        model: _str(j['model']),
        publishedAt: _ts(j['published_at']),
        lastUpdateAt: _ts(j['last_update_at']),
        supersededBy: _str(j['superseded_by']),
        noindexReason: _str(j['noindex_reason']),
        visits14dAfterEnd: _intN(j['visits_14d_after_end']),
        storagePath: _str(j['storage_path']),
        dirty: j['dirty'] == true,
        createdAt: _ts(j['created_at']) ?? DateTime.now(),
        updatedAt: _ts(j['updated_at']),
        article: j['article'] is Map ? _map(j['article']) : null,
      );

  final String id;
  final String? topicId;
  final TrendsCountry country;
  final String? slug;
  final DraftStatus status;
  final String? headline;
  final String? place;
  final String? placeSlug;
  final double? velocity;
  final String? failedGate;
  final String? reason;
  final List<GateResult> gates;
  final bool sensitive;
  final List<String> sensitiveReasons;

  /// topic | content (only while status = review)
  final String? reviewStage;
  final String? topicReviewedBy;
  final DateTime? topicReviewedAt;
  final String? reviewerId;
  final String? reviewerName;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final bool hasArticle;
  final int rewrites;
  final String? model;
  final DateTime? publishedAt;
  final DateTime? lastUpdateAt;
  final String? supersededBy;
  final String? noindexReason;
  final int? visits14dAfterEnd;
  final String? storagePath;
  final bool dirty;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Only in the review queue and the detail view.
  final Map<String, dynamic>? article;

  /// Stage of a draft in review: `topic` before anything was drafted.
  String get effectiveReviewStage => reviewStage ?? (hasArticle ? 'content' : 'topic');

  /// queued without an article: waiting for the Claude draft; with one: passed 3-5, waiting for the caps.
  bool get waitingForCaps => status == DraftStatus.queued && hasArticle;
}

/// Actions allowed from a draft's status (mirrors `admin_trends_set_draft_status`).
List<DraftAction> allowedDraftActions(TrendDraft d) => [
      if (d.status == DraftStatus.queued || d.status == DraftStatus.review) DraftAction.reject,
      if (d.status == DraftStatus.published) DraftAction.noindex,
      if (d.status == DraftStatus.noindex && d.supersededBy == null) DraftAction.reindex,
      if (d.status == DraftStatus.published || d.status == DraftStatus.noindex) DraftAction.unpublish,
    ];

/// Status after an action (same as the RPC).
DraftStatus draftStatusAfter(DraftAction a) => switch (a) {
      DraftAction.reject || DraftAction.unpublish => DraftStatus.rejected,
      DraftAction.noindex => DraftStatus.noindex,
      DraftAction.reindex => DraftStatus.published,
    };

class TrendSignal {
  const TrendSignal({
    required this.id,
    required this.sourceKind,
    required this.topic,
    this.url,
    this.publisher,
    this.publisherDomain,
    this.citable = false,
    this.snippet,
    this.score,
    this.firstSeen,
  });

  factory TrendSignal.fromJson(Map<String, dynamic> j) => TrendSignal(
        id: '${j['id']}',
        sourceKind: _str(j['source_kind']) ?? '',
        topic: _str(j['topic']) ?? '',
        url: _str(j['url']),
        publisher: _str(j['publisher']),
        publisherDomain: _str(j['publisher_domain']),
        citable: j['citable'] == true,
        snippet: _str(j['snippet']),
        score: _numN(j['score']),
        firstSeen: _ts(j['first_seen']),
      );

  final String id;
  final String sourceKind;
  final String topic;
  final String? url;
  final String? publisher;
  final String? publisherDomain;
  final bool citable;
  final String? snippet;
  final double? score;
  final DateTime? firstSeen;
}

class TrendLogEntry {
  const TrendLogEntry({
    required this.id,
    required this.decision,
    required this.createdAt,
    this.draftId,
    this.slug,
    this.country,
    this.reason,
    this.details = const {},
    this.actorId,
  });

  factory TrendLogEntry.fromJson(Map<String, dynamic> j) => TrendLogEntry(
        id: _int(j['id']),
        draftId: _str(j['draft_id']),
        slug: _str(j['slug']),
        country: TrendsCountry.parse(j['country']),
        decision: _str(j['decision']) ?? '',
        reason: _str(j['reason']),
        details: _map(j['details']),
        actorId: _str(j['actor_id']),
        createdAt: _ts(j['created_at']) ?? DateTime.now(),
      );

  final int id;
  final String? draftId;
  final String? slug;
  final TrendsCountry? country;
  final String decision;
  final String? reason;
  final Map<String, dynamic> details;

  /// null = the pipeline
  final String? actorId;
  final DateTime createdAt;
}

class TrendDraftDetail {
  const TrendDraftDetail({required this.draft, this.topic, this.signals = const [], this.log = const []});

  factory TrendDraftDetail.fromJson(Map<String, dynamic> j) => TrendDraftDetail(
        draft: TrendDraft.fromJson(j),
        topic: j['topic'] is Map ? TrendTopic.fromJson(_map(j['topic'])) : null,
        signals: [for (final s in (j['signals'] as List? ?? const [])) TrendSignal.fromJson(_map(s))],
        log: [for (final l in (j['log'] as List? ?? const [])) TrendLogEntry.fromJson(_map(l))],
      );

  final TrendDraft draft;
  final TrendTopic? topic;
  final List<TrendSignal> signals;
  final List<TrendLogEntry> log;

  Map<String, dynamic>? get article => draft.article;
}

/// The parts of the article JSON the panel renders (same sections as the site).
class TrendArticleView {
  const TrendArticleView(this.j);
  final Map<String, dynamic> j;

  String get headline => _str(j['headline']) ?? '';
  List<String> get summary => _strs(j['summary']);
  String? get framing => _str(_map(j['perspectives'])['framing']);
  ({String label, String body})? perspective(String side) {
    final p = _map(_map(j['perspectives'])[side]);
    if (p.isEmpty) return null;
    return (label: _str(p['label']) ?? side.toUpperCase(), body: _str(p['body']) ?? '');
  }

  String? get agree => _str(j['agree']);
  String? get localAngle => _str(j['local_angle']);
  String? get context => _str(j['context']);
  String? get watchNext => _str(j['watch_next']);
  List<({DateTime? at, String text})> _dated(String key) => [
        for (final u in (j[key] as List? ?? const []))
          if (u is Map) (at: _ts(u['at']), text: _str(u['text']) ?? '') else (at: null, text: '$u'),
      ];
  List<({DateTime? at, String text})> get updates => _dated('updates');
  List<({DateTime? at, String text})> get corrections => _dated('corrections');
  List<({String publisher, String? url, String? title})> get sources => [
        for (final s in (j['sources'] as List? ?? const []))
          if (s is Map) (publisher: _str(s['publisher']) ?? '', url: _str(s['url']), title: _str(s['title'])),
      ];
  String? get approvedBy => _str(_map(j['review'])['approved_by']);
  DateTime? get approvedAt => _ts(_map(j['review'])['approved_at']);
  ({String label, String? url})? get appLink {
    final a = _map(j['app_link']);
    return a.isEmpty ? null : (label: _str(a['label']) ?? '', url: _str(a['url']));
  }
}

// Settings, health, kill switch, runs ------------------------------------------------------------------

class PublishingState {
  const PublishingState({
    this.paused = false,
    this.pausedAt,
    this.pausedReason,
    this.pausedBy,
    this.resumedReason,
    this.resumedBy,
  });

  factory PublishingState.fromJson(Object? v) {
    final j = _map(v);
    return PublishingState(
      paused: j['paused'] == true,
      pausedAt: _ts(j['paused_at']),
      pausedReason: _str(j['paused_reason']),
      pausedBy: _str(j['paused_by']),
      resumedReason: _str(j['resumed_reason']),
      resumedBy: _str(j['resumed_by']),
    );
  }

  final bool paused;
  final DateTime? pausedAt;
  final String? pausedReason;

  /// Admin id, or `auto` (manual action / error spike).
  final String? pausedBy;
  final String? resumedReason;
  final String? resumedBy;

  bool get autoPaused => paused && pausedBy == 'auto';
}

class TrendHealth {
  const TrendHealth({
    required this.country,
    required this.recordedAt,
    this.indexedShare,
    this.clicks7d,
    this.clicksPrev7d,
    this.scWarnings = 0,
    this.manualAction = false,
    this.errorReports24h = 0,
    this.note,
  });

  factory TrendHealth.fromJson(Map<String, dynamic> j) => TrendHealth(
        country: TrendsCountry.parse(j['country']) ?? TrendsCountry.usa,
        recordedAt: _ts(j['recorded_at']) ?? _ts(j['created_at']) ?? DateTime.now(),
        indexedShare: _numN(j['indexed_share']),
        clicks7d: _intN(j['clicks_7d']),
        clicksPrev7d: _intN(j['clicks_prev_7d']),
        scWarnings: _int(j['sc_warnings']),
        manualAction: j['manual_action'] == true,
        errorReports24h: _int(j['error_reports_24h']),
        note: _str(j['note']),
      );

  final TrendsCountry country;
  final DateTime recordedAt;
  final double? indexedShare;
  final int? clicks7d;
  final int? clicksPrev7d;
  final int scWarnings;
  final bool manualAction;
  final int errorReports24h;
  final String? note;
}

/// Weekly Search Console / analytics figures for `admin_trends_record_health`.
class HealthInput {
  const HealthInput({
    required this.country,
    required this.indexedShare,
    required this.clicks7d,
    required this.clicksPrev7d,
    this.scWarnings = 0,
    this.manualAction = false,
    this.errorReports24h = 0,
    this.note,
  });

  final TrendsCountry country;

  /// 0..1 (the form takes a percentage).
  final double indexedShare;
  final int clicks7d;
  final int clicksPrev7d;
  final int scWarnings;
  final bool manualAction;
  final int errorReports24h;
  final String? note;

  String? validate() {
    if (indexedShare.isNaN || indexedShare < 0 || indexedShare > 1) return 'invalid_indexed_share';
    if (clicks7d < 0 || clicksPrev7d < 0) return 'invalid_clicks';
    if (scWarnings < 0 || errorReports24h < 0) return 'invalid_count';
    return null;
  }

  Map<String, dynamic> toParams() => {
        'p_country': country.name,
        'p_indexed_share': indexedShare,
        'p_clicks_7d': clicks7d,
        'p_clicks_prev_7d': clicksPrev7d,
        'p_sc_warnings': scWarnings,
        'p_manual_action': manualAction,
        'p_error_reports_24h': errorReports24h,
        'p_note': (note ?? '').trim().isEmpty ? null : note!.trim(),
      };
}

/// Same rules as `trends.health_problem` (and _shared/trends/ramp.ts healthProblem):
/// null when healthy, else the problem code.
String? healthProblem(TrendHealth? h, Map<String, dynamic> healthCfg, DateTime now) {
  final maxAge = _int(healthCfg['max_age_days'], 7);
  if (h == null || h.recordedAt.isBefore(now.subtract(Duration(days: maxAge)))) return 'no_recent_health';
  if (h.manualAction) return 'manual_action';
  if (h.errorReports24h > _int(healthCfg['max_error_reports_24h'], 5)) return 'error_reports';
  if (h.scWarnings > _int(healthCfg['max_sc_warnings'], 0)) return 'search_console_warnings';
  if (h.indexedShare == null || h.indexedShare! < _num(healthCfg['min_indexed_share'], 0.6)) return 'low_indexed_share';
  final prev = h.clicksPrev7d ?? 0;
  if (prev > 0 && (prev - (h.clicks7d ?? 0)) / prev > _num(healthCfg['max_click_drop'], 0.3)) return 'traffic_drop';
  return null;
}

class HealthResult {
  const HealthResult({required this.health, this.autoPause, this.healthProblem});

  factory HealthResult.fromJson(Map<String, dynamic> j) => HealthResult(
        health: TrendHealth.fromJson(j),
        autoPause: _str(j['auto_pause']),
        healthProblem: _str(j['health_problem']),
      );

  final TrendHealth health;

  /// search_console_manual_action | error_report_spike when this snapshot paused publishing.
  final String? autoPause;
  final String? healthProblem;
}

class TrendRun {
  const TrendRun({
    required this.fn,
    required this.startedAt,
    this.finishedAt,
    this.ok,
    this.dryRun = false,
    this.stats = const {},
    this.error,
    this.trigger,
  });

  factory TrendRun.fromJson(String fn, Map<String, dynamic> j) => TrendRun(
        fn: fn,
        startedAt: _ts(j['started_at']) ?? DateTime.now(),
        finishedAt: _ts(j['finished_at']),
        ok: j['ok'] is bool ? j['ok'] as bool : null,
        dryRun: j['dry_run'] == true,
        stats: _map(j['stats']),
        error: _str(j['error']),
        trigger: _str(j['trigger']),
      );

  final String fn;
  final DateTime startedAt;
  final DateTime? finishedAt;

  /// null while running
  final bool? ok;
  final bool dryRun;
  final Map<String, dynamic> stats;
  final String? error;

  /// cron | admin (migration 1300)
  final String? trigger;
}

/// Admin "Run now" window for one function (`admin_trends_settings().run_now`).
class RunNowUsage {
  const RunNowUsage({this.used = 0, this.limit = 6, this.remaining = 6, this.windowSeconds = 3600, this.retryAfterSeconds = 0});

  factory RunNowUsage.fromJson(Object? v) {
    final j = _map(v);
    final limit = _int(j['limit'], 6);
    final used = _int(j['used']);
    return RunNowUsage(
      used: used,
      limit: limit,
      remaining: _intN(j['remaining']) ?? (limit - used).clamp(0, limit),
      windowSeconds: _int(j['window_seconds'], 3600),
      retryAfterSeconds: _int(j['retry_after_seconds']),
    );
  }

  final int used;
  final int limit;
  final int remaining;
  final int windowSeconds;
  final int retryAfterSeconds;
}

class RunNowResult {
  const RunNowResult({required this.ok, this.dryRun = false, this.reason, this.stats = const {}});

  factory RunNowResult.fromJson(Object? v) {
    final j = _map(v);
    return RunNowResult(
      ok: j['ok'] != false,
      dryRun: j['dry_run'] == true,
      reason: _str(j['reason']),
      stats: _map(j['stats']),
    );
  }

  final bool ok;
  final bool dryRun;

  /// Set on a dry run: which secret is missing.
  final String? reason;
  final Map<String, dynamic> stats;

  /// "signals_new 4, fired 1, ..." (scalar stats; lists show their length).
  String get statsSummary => [
        for (final e in stats.entries)
          if (e.value is num || e.value is bool || e.value is String)
            '${e.key} ${e.value}'
          else if (e.value is List)
            '${e.key} ${(e.value as List).length}',
      ].join(', ');
}

/// `admin_trends_settings()`.
class TrendSettingsSnapshot {
  const TrendSettingsSnapshot({
    required this.settings,
    this.descriptions = const {},
    this.perDay = const {},
    this.health = const {},
    this.healthProblems = const {},
    this.published24h = const {},
    this.runs = const {},
    this.runNow = const {},
  });

  factory TrendSettingsSnapshot.fromJson(Map<String, dynamic> j) {
    Map<TrendsCountry, T> byCountry<T>(Object? v, T Function(Object?) f) => {
          for (final c in TrendsCountry.values) c: f(_map(v)[c.name]),
        };
    return TrendSettingsSnapshot(
      settings: _map(j['settings']),
      descriptions: {for (final e in _map(j['descriptions']).entries) e.key: '${e.value ?? ''}'},
      perDay: byCountry(j['per_day'], (v) => _int(v, 1)),
      health: byCountry(j['health'], (v) => v is Map ? TrendHealth.fromJson(_map(v)) : null),
      healthProblems: byCountry(j['health_problem'], _str),
      published24h: byCountry(j['published_24h'], (v) => _int(v)),
      runs: {for (final e in _map(j['runs']).entries) e.key: TrendRun.fromJson(e.key, _map(e.value))},
      runNow: {for (final e in _map(j['run_now']).entries) e.key: RunNowUsage.fromJson(e.value)},
    );
  }

  final Map<String, dynamic> settings;
  final Map<String, String> descriptions;
  final Map<TrendsCountry, int> perDay;
  final Map<TrendsCountry, TrendHealth?> health;
  final Map<TrendsCountry, String?> healthProblems;
  final Map<TrendsCountry, int> published24h;
  final Map<String, TrendRun> runs;
  final Map<String, RunNowUsage> runNow;

  PublishingState get publishing => PublishingState.fromJson(settings['publishing']);
  bool get pipelineEnabled => _map(settings['pipeline'])['enabled'] == true;
  Map<String, dynamic> get caps => _map(settings['caps']);
  Map<String, dynamic> get ramp => _map(settings['ramp']);
  List<int> get rampLevels => [for (final x in (caps['ramp_levels'] as List? ?? const [1, 2, 5, 10, 20])) _int(x)];
  int rampLevel(TrendsCountry c) => _int(_map(ramp[c.name])['level']);
  DateTime? rampChangedAt(TrendsCountry c) => _ts(_map(ramp[c.name])['changed_at']);
  int get minDaysBetweenSteps => _int(ramp['min_days_between_steps'], 30);
  RunNowUsage runNowFor(TrendsFunction f) => runNow[f.fnName] ?? const RunNowUsage();

  /// Why a manual step up is refused (same order as `admin_trends_set_ramp`), or null.
  String? rampStepUpBlocker(TrendsCountry c, DateTime now) {
    final level = rampLevel(c);
    if (level + 1 >= rampLevels.length) return 'top_level';
    final changed = rampChangedAt(c);
    if (changed != null && changed.isAfter(now.subtract(Duration(days: minDaysBetweenSteps)))) {
      return 'ramp_step_too_soon';
    }
    final problem = healthProblems[c];
    if (problem != null) return 'ramp_unhealthy';
    return null;
  }

  /// Keys the generic editor offers (kill switch has its own control).
  List<String> get editableKeys => [
        for (final k in settings.keys.toList()..sort())
          if (k != 'publishing') k,
      ];
}

// Setting floors (mirrors admin_trends_set_setting) -----------------------------------------------------

const objectSettingKeys = {'caps', 'gates', 'ramp', 'detection', 'pipeline', 'app_hosts'};
const stringListSettingKeys = {'sensitive_tags', 'sensitive_keywords', 'banned_perspective_terms'};

/// The value the server stores: object settings are merged (ramp keeps its
/// per-country levels, which change only through the ramp RPC), lists replaced.
Object? mergeSetting(String key, Object? old, Object? patch) {
  if (objectSettingKeys.contains(key) && old is Map && patch is Map) {
    final merged = {...Map<String, dynamic>.from(old), ...Map<String, dynamic>.from(patch)};
    if (key == 'ramp') {
      merged['usa'] = old['usa'];
      merged['india'] = old['india'];
    }
    return merged;
  }
  return patch;
}

/// Server-side floors from the brief, checked on the merged value. Returns the
/// server's `invalid_setting_value` detail strings (empty = valid).
List<String> trendSettingProblems(String key, Object? old, Object? merged) {
  if (key == 'publishing') return const ['use_admin_trends_set_kill_switch'];
  String typeOf(Object? v) => v is Map ? 'object' : (v is List ? 'array' : (v is num ? 'number' : (v is bool ? 'boolean' : 'string')));
  if (old != null && typeOf(old) != typeOf(merged)) return const ['invalid_setting_type'];
  final out = <String>[];
  if (stringListSettingKeys.contains(key)) {
    if (merged is! List || merged.any((e) => e is! String || e.isEmpty)) out.add('array of non-empty strings');
    return out;
  }
  final m = _map(merged);
  num? n(String k) => m[k] is num ? m[k] as num : null;
  switch (key) {
    case 'caps':
      final levels = m['ramp_levels'];
      var prev = 0;
      var ok = levels is List && levels.isNotEmpty;
      if (ok) {
        for (final x in levels) {
          if (x is! num || x <= prev || x != x.floor()) {
            ok = false;
            break;
          }
          prev = x.toInt();
        }
      }
      if (!ok) out.add('ramp_levels must be ascending positive integers');
      final hard = n('hard_max_per_day') ?? 99;
      if (hard > 20 || (ok && prev > (n('hard_max_per_day') ?? 20))) out.add('at most 20 per day per country');
      final perHour = n('max_per_hour') ?? 99;
      if (perHour < 1 || perHour > 3) out.add('max_per_hour must be 1 to 3');
    case 'gates':
      if ((n('min_sources') ?? 0) < 2 ||
          (n('min_words') ?? 0) < 250 ||
          (n('max_similarity') ?? 1) > 0.5 ||
          (n('max_rewrites') ?? 9) > 1) {
        out.add('min_sources >= 2, min_words >= 250, max_similarity <= 0.5, max_rewrites <= 1');
      }
    case 'ramp':
      if ((n('min_days_between_steps') ?? 0) < 30) out.add('min_days_between_steps >= 30');
  }
  return out;
}

/// Parses "1, 2, 5" / one per line into numbers (null when a part is not a number).
List<num>? parseNumberList(String text) {
  final parts = text.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty);
  final out = <num>[];
  for (final p in parts) {
    final v = num.tryParse(p);
    if (v == null) return null;
    out.add(v);
  }
  return out;
}

/// Parses comma / newline separated words, trimmed, empty parts dropped, duplicates removed.
List<String> parseStringList(String text) {
  final seen = <String>{};
  return [
    for (final p in text.split(RegExp(r'[\n,]')).map((s) => s.trim()))
      if (p.isNotEmpty && seen.add(p)) p,
  ];
}

/// Minutes (rounded up) for a Retry-After in seconds.
int retryMinutes(int seconds) => (seconds / 60).ceil().clamp(1, 1 << 20);

abstract interface class TrendsRepository {
  Future<TrendBoard> board({TrendsCountry? country, int hours = 24});
  Future<List<TrendTopic>> topics({TopicStatus? status, TrendsCountry? country, int limit = 100});
  Future<List<TrendDraft>> drafts({DraftStatus? status, TrendsCountry? country, int limit = 100, int offset = 0});
  Future<TrendDraftDetail> draft(String id);
  Future<List<TrendDraft>> reviewQueue({TrendsCountry? country});

  /// Approve / reject (stage topic or content); stores reviewer and date.
  Future<TrendDraft> review(String id, {required bool approve, String? note});
  Future<TrendSettingsSnapshot> settings();

  /// Returns the stored value (merged for object settings).
  Future<Object?> setSetting(String key, Object value);
  Future<PublishingState> setKillSwitch({required bool paused, String? reason});
  Future<void> setRamp(TrendsCountry country, int level, {String? reason});
  Future<HealthResult> recordHealth(HealthInput input);
  Future<TrendDraft> recordTraffic(String slug, int visits14d);
  Future<TrendDraft> setDraftStatus(String id, DraftAction action, {String? reason});
  Future<TrendDraft> addCorrection(String id, String text);
  Future<TrendDraft> supersede(String slug, String bySlug);
  Future<List<TrendLogEntry>> publishLog({int limit = 100, String? draftId});
  Future<TrendSource> addSource(TrendSourceDraft source);
  Future<TrendSource> setSourceEnabled(int id, bool enabled);

  /// Calls the Edge Function with the admin's JWT (`{action: "run"}`).
  /// Throws [TrendsRateLimited] past the per-function hourly limit.
  Future<RunNowResult> runNow(TrendsFunction fn);
}
