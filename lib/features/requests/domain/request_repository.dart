import 'buyer_request.dart';
import 'category.dart';

class RequestFailure implements Exception {
  const RequestFailure(this.code, [this.message]);

  /// rate_limited | duplicate | blocked_category | invalid | network
  final String code;
  final String? message;
  @override
  String toString() => 'RequestFailure($code, $message)';
}

abstract interface class CategoryRepository {
  /// Full tree for this country (cached on device, refreshed in background).
  Future<List<Category>> fetchAll({bool forceRefresh = false});

  /// Suggests leaf categories for free text (keywords now, ML later).
  Future<List<Category>> suggest(String text);

  /// Returns the blocked category the text matches, if any.
  Future<Category?> blockedMatch(String text);
}

abstract interface class RequestRepository {
  /// Calls the `create_request` RPC (rate limits, duplicate and blocked-category
  /// checks happen server side) and uploads media. Returns the new request.
  Future<BuyerRequest> createRequest(RequestDraft draft);
  Stream<List<BuyerRequest>> watchMyRequests();
  Stream<BuyerRequest?> watchRequest(String id);
  Future<void> cancelRequest(String id);
  Future<int> postalCodeLookupCount(String code);
}
