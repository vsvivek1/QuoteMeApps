import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/trends_models.dart';

part 'trends_providers.g.dart';

@Riverpod(keepAlive: true)
TrendsRepository trendsRepository(Ref ref) => ref.watch(adminBackendProvider).trends;

/// Country filter shared by every Trends tab (null = both; the pipeline covers both).
@Riverpod(keepAlive: true)
class TrendsCountryFilter extends _$TrendsCountryFilter {
  @override
  TrendsCountry? build() => null;

  void set(TrendsCountry? c) => state = c;
}

@riverpod
Future<TrendBoard> trendBoard(Ref ref, int hours) =>
    ref.watch(trendsRepositoryProvider).board(country: ref.watch(trendsCountryFilterProvider), hours: hours);

@riverpod
Future<List<TrendTopic>> trendTopics(Ref ref, TopicStatus? status) =>
    ref.watch(trendsRepositoryProvider).topics(status: status, country: ref.watch(trendsCountryFilterProvider));

@riverpod
Future<List<TrendDraft>> trendDrafts(Ref ref, DraftStatus? status) =>
    ref.watch(trendsRepositoryProvider).drafts(status: status, country: ref.watch(trendsCountryFilterProvider));

@riverpod
Future<TrendDraftDetail> trendDraftDetail(Ref ref, String id) => ref.watch(trendsRepositoryProvider).draft(id);

@riverpod
Future<List<TrendDraft>> trendReviewQueue(Ref ref) =>
    ref.watch(trendsRepositoryProvider).reviewQueue(country: ref.watch(trendsCountryFilterProvider));

@riverpod
Future<TrendSettingsSnapshot> trendSettings(Ref ref) => ref.watch(trendsRepositoryProvider).settings();

@riverpod
Future<List<TrendLogEntry>> trendPublishLog(Ref ref) => ref.watch(trendsRepositoryProvider).publishLog(limit: 50);

/// Refresh everything after a change (cheap: the lists are small).
void invalidateTrends(WidgetRef ref, {String? draftId}) {
  ref
    ..invalidate(trendBoardProvider)
    ..invalidate(trendTopicsProvider)
    ..invalidate(trendDraftsProvider)
    ..invalidate(trendReviewQueueProvider)
    ..invalidate(trendSettingsProvider)
    ..invalidate(trendPublishLogProvider);
  if (draftId != null) ref.invalidate(trendDraftDetailProvider(draftId));
}
