/// Section 13 KPIs plus queue sizes for the dashboard. Every field is
/// nullable: a missing backend metric shows as "n/a", never as zero.
class DashboardMetrics {
  const DashboardMetrics({
    this.users,
    this.sellers,
    this.verifiedSellers,
    this.pendingVerifications,
    this.pendingLicences,
    this.openReports,
    this.openRequests,
    this.requests7d,
    this.quotes7d,
    this.orders7d,
    this.requestsWith3QuotesPct,
    this.medianFirstQuoteMins,
    this.requestToAcceptancePct,
    this.sellerResponseRatePct,
    this.freeToPaidPct,
    this.retention = const {},
    this.revenuePerSellerMinor,
    this.refunds30d,
    this.leadsPerStage = const {},
    this.outreachSentToday,
    this.outreachDailyCapacity,
    this.outreachQueue,
    this.replyRatePct,
    this.signupRatePct,
  });

  final int? users;
  final int? sellers;
  final int? verifiedSellers;
  final int? pendingVerifications;
  final int? pendingLicences;
  final int? openReports;
  final int? openRequests;
  final int? requests7d;
  final int? quotes7d;
  final int? orders7d;

  /// % of requests (30 days) with at least 3 quotes.
  final double? requestsWith3QuotesPct;

  /// Time to first quote (target under 2h in metros).
  final double? medianFirstQuoteMins;
  final double? requestToAcceptancePct;
  final double? sellerResponseRatePct;
  final double? freeToPaidPct;

  /// e.g. {'buyer_d1': 41.0, 'buyer_d7': ..., 'seller_d30': ...}
  final Map<String, double> retention;
  final int? revenuePerSellerMinor;
  final int? refunds30d;

  /// CRM funnel (21.5).
  final Map<String, int> leadsPerStage;
  final int? outreachSentToday;
  final int? outreachDailyCapacity;
  final int? outreachQueue;
  final double? replyRatePct;
  final double? signupRatePct;
}

abstract interface class MetricsRepository {
  Future<DashboardMetrics> load();
}
