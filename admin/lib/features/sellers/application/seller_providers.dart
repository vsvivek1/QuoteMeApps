import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../audit/application/audit_providers.dart';
import '../domain/seller_models.dart';

part 'seller_providers.g.dart';

@riverpod
class SellerQuery extends _$SellerQuery {
  @override
  String build() => '';

  void set(String q) => state = q.trim();
}

@riverpod
Future<List<SellerSummary>> sellerSearch(Ref ref) {
  final q = ref.watch(sellerQueryProvider);
  if (q.isEmpty) return Future.value(const []);
  return ref.watch(sellerRepositoryProvider).search(q);
}

@riverpod
Future<SellerSummary> sellerDetail(Ref ref, String id) => ref.watch(sellerRepositoryProvider).seller(id);

@riverpod
Future<List<EntitlementRecord>> sellerEntitlements(Ref ref, String sellerId) =>
    ref.watch(sellerRepositoryProvider).entitlements(sellerId);

/// Refresh what a grant changes.
void invalidateAfterGrant(WidgetRef ref, String sellerId) {
  ref
    ..invalidate(sellerEntitlementsProvider(sellerId))
    ..invalidate(auditLogProvider);
}
