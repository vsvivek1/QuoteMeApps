import 'lead.dart';
import 'seller.dart';

abstract interface class SellerRepository {
  Stream<Seller?> watchMySeller();
  Future<Seller> upsertSeller(Seller seller, {String? logoPath, List<String> newPhotoPaths});
  Future<Seller?> getSeller(String id);
  Future<SellerStats> stats();

  /// Shows or hides the seller on the public website's seller directory
  /// (`set_seller_directory_opt_in`). Only business name, categories, city,
  /// rating and response time are published; never contact details.
  Future<void> setDirectoryOptIn(bool optIn);

  /// One-time onboarding fee (`get_my_onboarding_fee`, I Want USA only).
  /// Null when the caller is not a seller or the backend has no fee.
  Future<OnboardingFee?> onboardingFee();

  Future<List<SellerDocument>> myDocuments();
  Future<void> submitDocument(String docType, {String? number, String? filePath});
  Future<List<SellerLicence>> myLicences();
  Future<void> submitLicence(SellerLicence licence, {String? filePath});

  Future<List<QuoteTemplate>> templates();
  Future<void> saveTemplate(QuoteTemplate template);
  Future<void> deleteTemplate(String id);
}

class OnboardingFee {
  const OnboardingFee({required this.due, required this.paid, required this.amountMinor});

  /// True while the fee blocks quoting (switch on, US, not paid, not an early partner).
  final bool due;
  final bool paid;
  final int amountMinor;
}

abstract interface class LeadRepository {
  /// `get_lead_feed` RPC with keyset pagination.
  Future<LeadPage> feed(LeadFilters filters, {String? cursor});
  Future<Lead?> lead(String requestId);
  Future<void> dismiss(String requestId);
  Future<void> markSeen(String requestId);

  /// Fires when the seller's Realtime broadcast channel announces new leads.
  Stream<void> newLeadSignals();
}
