/// A pending seller document or licence in the verification queue.
class VerificationItem {
  const VerificationItem({
    required this.id,
    required this.kind,
    required this.sellerId,
    required this.businessName,
    required this.docType,
    this.docNumber,
    this.filePath,
    this.city,
    this.state,
    this.issuer,
    this.expiresAt,
    this.categoryIds = const [],
    this.sellerStatus,
    required this.submittedAt,
  });

  final String id;

  /// `document` (seller_documents) or `licence` (seller_licences).
  final VerificationKind kind;
  final String sellerId;
  final String businessName;
  final String docType;
  final String? docNumber;

  /// Path in the private `verification-docs` bucket.
  final String? filePath;
  final String? city;
  final String? state;
  final String? issuer;
  final DateTime? expiresAt;
  final List<int> categoryIds;
  final String? sellerStatus;
  final DateTime submittedAt;
}

enum VerificationKind { document, licence }

abstract interface class VerificationRepository {
  Future<List<VerificationItem>> pending();

  /// Short-lived signed URL for a private document (never a public link).
  Future<Uri?> documentUrl(String filePath);

  Future<void> review(VerificationItem item, {required bool approve, String? reason});
}
