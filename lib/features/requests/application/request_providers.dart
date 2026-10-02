import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../quotes/domain/quote.dart';
import '../domain/buyer_request.dart';
import '../domain/category.dart';

part 'request_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<Category>> categories(Ref ref) => ref.watch(categoryRepositoryProvider).fetchAll();

@riverpod
Future<Map<int, Category>> categoryMap(Ref ref) async {
  final list = await ref.watch(categoriesProvider.future);
  return {for (final c in list) c.id: c};
}

@riverpod
Stream<List<BuyerRequest>> myRequests(Ref ref) => ref.watch(requestRepositoryProvider).watchMyRequests();

@riverpod
Stream<BuyerRequest?> request(Ref ref, String id) => ref.watch(requestRepositoryProvider).watchRequest(id);

@riverpod
Stream<List<Quote>> requestQuotes(Ref ref, String requestId) =>
    ref.watch(quoteRepositoryProvider).watchQuotesForRequest(requestId);
