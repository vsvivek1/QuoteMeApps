import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/outreach_models.dart';

part 'outreach_providers.g.dart';

@riverpod
class LeadFilterController extends _$LeadFilterController {
  @override
  LeadFilter build() => const LeadFilter();

  void set(LeadFilter f) => state = f;
  void clear() => state = const LeadFilter();
}

@riverpod
Future<List<OutreachLead>> outreachLeads(Ref ref) =>
    ref.watch(outreachRepositoryProvider).leads(ref.watch(leadFilterControllerProvider));

@riverpod
Future<OutreachLead> leadDetail(Ref ref, String id) => ref.watch(outreachRepositoryProvider).lead(id);

@riverpod
Future<List<OutreachEvent>> leadEvents(Ref ref, String id) => ref.watch(outreachRepositoryProvider).events(id);

@riverpod
Future<List<SuppressionEntry>> suppressionList(Ref ref) => ref.watch(outreachRepositoryProvider).suppression();

@riverpod
Future<List<OutreachCampaign>> campaigns(Ref ref) => ref.watch(outreachRepositoryProvider).campaigns();

@riverpod
Future<List<OutreachSequence>> sequences(Ref ref) => ref.watch(outreachRepositoryProvider).sequences();

@riverpod
Future<List<OutreachInbox>> inboxes(Ref ref) => ref.watch(outreachRepositoryProvider).inboxes();

@riverpod
Future<SendStats> sendStats(Ref ref) => ref.watch(outreachRepositoryProvider).sendStats();

@riverpod
Future<List<CoverageCell>> coverage(Ref ref) => ref.watch(outreachRepositoryProvider).coverage();

/// Refresh everything that depends on leads after a CRM change.
void invalidateOutreach(WidgetRef ref, {String? leadId}) {
  ref.invalidate(outreachLeadsProvider);
  ref.invalidate(suppressionListProvider);
  ref.invalidate(sendStatsProvider);
  if (leadId != null) {
    ref.invalidate(leadDetailProvider(leadId));
    ref.invalidate(leadEventsProvider(leadId));
  }
}
