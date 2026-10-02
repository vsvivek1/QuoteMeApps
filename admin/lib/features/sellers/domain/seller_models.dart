import 'manual_payment.dart';

/// A seller as the admin sees it (sellers + profiles + seller_contacts).
class SellerSummary {
  const SellerSummary({
    required this.id,
    required this.businessName,
    this.ownerName,
    this.phone,
    this.businessPhone,
    this.email,
    this.city,
    this.state,
    this.verificationStatus = 'unverified',
    this.earlyPartner = false,
    this.freeUntil,
    this.hidden = false,
    this.createdAt,
  });

  final String id;
  final String businessName;
  final String? ownerName;

  /// Account phone (profiles.phone).
  final String? phone;

  /// Business phone (seller_contacts.business_phone).
  final String? businessPhone;
  final String? email;
  final String? city;
  final String? state;
  final String verificationStatus;
  final bool earlyPartner;
  final DateTime? freeUntil;
  final bool hidden;
  final DateTime? createdAt;
}

/// One `entitlements` row.
class EntitlementRecord {
  const EntitlementRecord({
    required this.id,
    required this.sellerId,
    required this.store,
    this.provider,
    required this.productId,
    required this.tier,
    required this.status,
    this.creditsBalance = 0,
    this.renewsAt,
    this.expiresAt,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String sellerId;

  /// play | apple | web | manual
  final String store;
  final String? provider;
  final String productId;

  /// pro | credits
  final String tier;
  final String status;
  final int creditsBalance;
  final DateTime? renewsAt;
  final DateTime? expiresAt;

  /// `raw.note` of a manual grant.
  final String? note;
  final DateTime createdAt;

  Map<String, dynamic>? get manualPayment => parseManualPaymentNote(note);

  bool isLive(DateTime now) => expiresAt == null || expiresAt!.isAfter(now);
}

/// What the seller can use right now, computed like `get_my_entitlement` /
/// `quote_entitlement`: the latest live Pro row, plus the sum of live credits.
class CurrentEntitlement {
  const CurrentEntitlement({this.pro, this.creditsBalance = 0});

  final EntitlementRecord? pro;
  final int creditsBalance;

  bool get hasPro => pro != null;
  bool get isEmpty => pro == null && creditsBalance == 0;

  static const _proStatuses = {'active', 'grace', 'on_hold', 'paused'};

  static CurrentEntitlement from(List<EntitlementRecord> rows, DateTime now) {
    final pros = rows.where((e) => e.tier == 'pro' && _proStatuses.contains(e.status) && e.isLive(now)).toList()
      ..sort((a, b) {
        // Latest end date first; open-ended (null) wins.
        final ae = a.expiresAt, be = b.expiresAt;
        if (ae == null && be == null) return b.createdAt.compareTo(a.createdAt);
        if (ae == null) return -1;
        if (be == null) return 1;
        return be.compareTo(ae);
      });
    final credits = rows
        .where((e) => e.tier == 'credits' && e.status == 'active' && e.isLive(now))
        .fold<int>(0, (sum, e) => sum + e.creditsBalance);
    return CurrentEntitlement(pro: pros.isEmpty ? null : pros.first, creditsBalance: credits);
  }
}

abstract interface class SellerRepository {
  /// By business name, or by phone when the query is mostly digits.
  Future<List<SellerSummary>> search(String query);

  Future<SellerSummary> seller(String id);

  /// All entitlement rows for a seller, newest first.
  Future<List<EntitlementRecord>> entitlements(String sellerId);

  /// Earlier manual grants that used this payment reference (any seller).
  Future<List<EntitlementRecord>> grantsWithReference(String reference);

  /// `admin_grant_entitlement` (audit-logged server side).
  Future<EntitlementRecord> grant(ManualPaymentGrant grant);
}

/// Phone-like search: at least 4 digits and nothing but digits, spaces, `+`,
/// `-`, `(`, `)`. Returns the digits, or null for a name search.
String? phoneDigits(String query) {
  final q = query.trim();
  if (!RegExp(r'^[\d\s+\-()]+$').hasMatch(q)) return null;
  final digits = q.replaceAll(RegExp(r'\D'), '');
  return digits.length >= 4 ? digits : null;
}
