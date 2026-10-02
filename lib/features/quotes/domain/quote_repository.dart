import '../../../core/money/money.dart';
import 'quote.dart';

class QuoteFailure implements Exception {
  const QuoteFailure(this.code, [this.message]);

  /// cap_reached | request_closed | not_allowed | licence_required |
  /// no_credits | priority_window | rate_limited | network
  final String code;
  final String? message;
  @override
  String toString() => 'QuoteFailure($code, $message)';
}

abstract interface class QuoteRepository {
  /// Buyer: live quotes on one of their requests.
  Stream<List<Quote>> watchQuotesForRequest(String requestId);
  Future<Quote?> getQuote(String quoteId);

  /// Seller: `submit_quote` RPC.
  Future<Quote> submitQuote(QuoteDraft draft);
  Future<Quote> reviseQuote(String quoteId, QuoteDraft draft);
  Future<void> withdrawQuote(String quoteId);

  /// Seller: my quotes, filtered by bucket (active | won | lost).
  Stream<List<Quote>> watchMyQuotes(String bucket);

  /// Buyer actions.
  Future<String> acceptQuote(String quoteId);
  Future<void> declineQuote(String quoteId, {String? reason});
  Future<void> setShortlisted(String quoteId, bool shortlisted);
  Future<void> counterOffer(String quoteId, Money target, {String? note});
  Future<void> markViewed(String quoteId);
}
