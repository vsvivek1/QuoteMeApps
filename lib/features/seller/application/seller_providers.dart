import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../quotes/domain/quote.dart';
import '../domain/lead.dart';
import '../domain/seller.dart';

part 'seller_providers.g.dart';

@riverpod
Stream<Seller?> mySeller(Ref ref) {
  if (ref.watch(authSessionProvider).value == null) return Stream.value(null);
  return ref.watch(sellerRepositoryProvider).watchMySeller();
}

@riverpod
Future<SellerStats> sellerStats(Ref ref) {
  ref.watch(myQuotesProvider('active'));
  return ref.watch(sellerRepositoryProvider).stats();
}

@riverpod
Stream<List<Quote>> myQuotes(Ref ref, String bucket) => ref.watch(quoteRepositoryProvider).watchMyQuotes(bucket);

@riverpod
Future<Seller?> sellerById(Ref ref, String id) => ref.watch(sellerRepositoryProvider).getSeller(id);

@riverpod
Future<Lead?> lead(Ref ref, String requestId) => ref.watch(leadRepositoryProvider).lead(requestId);

@riverpod
class LeadFilterState extends _$LeadFilterState {
  @override
  LeadFilters build() => const LeadFilters();

  void set(LeadFilters f) => state = f;
}

/// First page of the lead feed; refreshes when the seller's realtime channel
/// signals new leads.
@riverpod
class LeadFeed extends _$LeadFeed {
  String? _cursor;

  @override
  Future<List<Lead>> build() async {
    final filters = ref.watch(leadFilterStateProvider);
    ref.watch(mySellerProvider);
    final sub = ref.watch(leadRepositoryProvider).newLeadSignals().listen((_) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);
    final page = await ref.watch(leadRepositoryProvider).feed(filters);
    _cursor = page.nextCursor;
    return page.leads;
  }

  bool get hasMore => _cursor != null;

  Future<void> loadMore() async {
    final cursor = _cursor;
    if (cursor == null) return;
    final page = await ref.read(leadRepositoryProvider).feed(ref.read(leadFilterStateProvider), cursor: cursor);
    _cursor = page.nextCursor;
    state = AsyncData([...?state.value, ...page.leads]);
  }

  Future<void> dismiss(String requestId) async {
    state = AsyncData([...?state.value?.where((l) => l.requestId != requestId)]);
    await ref.read(leadRepositoryProvider).dismiss(requestId);
  }
}

@riverpod
Future<List<QuoteTemplate>> quoteTemplates(Ref ref) => ref.watch(sellerRepositoryProvider).templates();
