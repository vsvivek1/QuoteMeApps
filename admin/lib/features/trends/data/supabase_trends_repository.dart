import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/trends_models.dart';

/// The `admin_trends_*` RPCs (the `trends` schema is not exposed through
/// PostgREST) and the `trends-*` Edge Functions, called with the signed-in
/// admin's JWT. Errors become [TrendsException] with the server's code.
class SupabaseTrendsRepository implements TrendsRepository {
  SupabaseTrendsRepository(this.c);
  final SupabaseClient c;

  Future<Object?> _rpc(String fn, [Map<String, dynamic>? params]) async {
    try {
      return await c.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      throw trendsRpcError(code: e.code, message: e.message, details: e.details);
    }
  }

  static Map<String, dynamic> _m(Object? v) => v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
  static List<Map<String, dynamic>> _l(Object? v) => [for (final x in (v is List ? v : const [])) _m(x)];

  @override
  Future<TrendBoard> board({TrendsCountry? country, int hours = 24}) async =>
      TrendBoard.fromJson(_m(await _rpc('admin_trends_board', {'p_country': country?.name, 'p_hours': hours})));

  @override
  Future<List<TrendTopic>> topics({TopicStatus? status, TrendsCountry? country, int limit = 100}) async => [
        for (final r in _l(await _rpc('admin_trends_topics',
            {'p_status': status?.wire, 'p_country': country?.name, 'p_limit': limit})))
          TrendTopic.fromJson(r),
      ];

  @override
  Future<List<TrendDraft>> drafts({DraftStatus? status, TrendsCountry? country, int limit = 100, int offset = 0}) async => [
        for (final r in _l(await _rpc('admin_trends_drafts',
            {'p_status': status?.name, 'p_country': country?.name, 'p_limit': limit, 'p_offset': offset})))
          TrendDraft.fromJson(r),
      ];

  @override
  Future<TrendDraftDetail> draft(String id) async =>
      TrendDraftDetail.fromJson(_m(await _rpc('admin_trends_draft', {'p_draft_id': id})));

  @override
  Future<List<TrendDraft>> reviewQueue({TrendsCountry? country}) async => [
        for (final r in _l(await _rpc('admin_trends_review_queue', {'p_country': country?.name}))) TrendDraft.fromJson(r),
      ];

  @override
  Future<TrendDraft> review(String id, {required bool approve, String? note}) async => TrendDraft.fromJson(
      _m(await _rpc('admin_trends_review', {'p_draft_id': id, 'p_approve': approve, 'p_note': _blankToNull(note)})));

  @override
  Future<TrendSettingsSnapshot> settings() async => TrendSettingsSnapshot.fromJson(_m(await _rpc('admin_trends_settings')));

  @override
  Future<Object?> setSetting(String key, Object value) async =>
      _m(await _rpc('admin_trends_set_setting', {'p_key': key, 'p_value': value}))['value'];

  @override
  Future<PublishingState> setKillSwitch({required bool paused, String? reason}) async => PublishingState.fromJson(
      await _rpc('admin_trends_set_kill_switch', {'p_paused': paused, 'p_reason': _blankToNull(reason)}));

  @override
  Future<void> setRamp(TrendsCountry country, int level, {String? reason}) async =>
      _rpc('admin_trends_set_ramp', {'p_country': country.name, 'p_level': level, 'p_reason': _blankToNull(reason)});

  @override
  Future<HealthResult> recordHealth(HealthInput input) async {
    final err = input.validate();
    if (err != null) throw TrendsException(err, status: 400);
    return HealthResult.fromJson(_m(await _rpc('admin_trends_record_health', input.toParams())));
  }

  @override
  Future<TrendDraft> recordTraffic(String slug, int visits14d) async => TrendDraft.fromJson(
      _m(await _rpc('admin_trends_record_traffic', {'p_slug': slug, 'p_visits_14d': visits14d})));

  @override
  Future<TrendDraft> setDraftStatus(String id, DraftAction action, {String? reason}) async => TrendDraft.fromJson(_m(
      await _rpc('admin_trends_set_draft_status', {'p_draft_id': id, 'p_action': action.wire, 'p_reason': _blankToNull(reason)})));

  @override
  Future<TrendDraft> addCorrection(String id, String text) async =>
      TrendDraft.fromJson(_m(await _rpc('admin_trends_add_correction', {'p_draft_id': id, 'p_text': text})));

  @override
  Future<TrendDraft> supersede(String slug, String bySlug) async =>
      TrendDraft.fromJson(_m(await _rpc('admin_trends_supersede', {'p_slug': slug, 'p_by_slug': bySlug})));

  @override
  Future<List<TrendLogEntry>> publishLog({int limit = 100, String? draftId}) async => [
        for (final r in _l(await _rpc('admin_trends_publish_log', {'p_limit': limit, 'p_draft_id': draftId})))
          TrendLogEntry.fromJson(r),
      ];

  @override
  Future<TrendSource> addSource(TrendSourceDraft source) async {
    final err = source.validate();
    if (err != null) throw TrendsException('invalid_source', detail: err, status: 400);
    return TrendSource.fromJson(_m(await _rpc('admin_trends_upsert_source', {'p_source': source.toJson()})));
  }

  @override
  Future<TrendSource> setSourceEnabled(int id, bool enabled) async =>
      TrendSource.fromJson(_m(await _rpc('admin_trends_upsert_source', {'p_source': {'id': id, 'enabled': enabled}})));

  @override
  Future<RunNowResult> runNow(TrendsFunction fn) async {
    try {
      final res = await c.functions.invoke(fn.fnName, body: {'action': 'run'});
      return RunNowResult.fromJson(res.data);
    } on FunctionException catch (e) {
      throw trendsFunctionError(e.status, e.details);
    }
  }

  static String? _blankToNull(String? s) => (s ?? '').trim().isEmpty ? null : s!.trim();
}
