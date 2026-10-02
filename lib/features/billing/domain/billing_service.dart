import '../../../core/money/money.dart';

enum PlanKind { monthly, annual, credits }

class PlanProduct {
  const PlanProduct({
    required this.id,
    required this.kind,
    required this.title,
    required this.price,
    this.priceText,
    this.credits,
    this.trialDays,
  });

  final String id;
  final PlanKind kind;
  final String title;
  final Money price;

  /// Store-formatted price when the store provides one.
  final String? priceText;
  final int? credits;
  final int? trialDays;
}

class PurchaseResult {
  const PurchaseResult({required this.success, this.pending = false, this.error});
  final bool success;
  final bool pending;
  final String? error;
}

/// One interface over Play Billing, StoreKit, Stripe and Razorpay so the mix
/// can change per store policy without touching the plan screen. All grants
/// are verified server side and land in `entitlements`.
abstract interface class BillingService {
  /// play | apple | stripe | razorpay | demo
  String get store;
  bool get supportsRestore;
  Future<List<PlanProduct>> products();
  Future<PurchaseResult> buy(PlanProduct product);
  Future<void> restore();

  /// Store subscription centre or web customer portal.
  Uri? manageSubscriptionsUrl(String? productId);
}
