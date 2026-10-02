import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/country_config.dart';
import '../../../core/data/supabase/edge_functions.dart';
import '../../../core/providers.dart';
import '../domain/billing_service.dart';

part 'billing_services.g.dart';

/// Product IDs are the same in both stores and both apps; prices are set per
/// storefront (INR for India, USD for USA).
abstract final class ProductIds {
  static const monthly = 'seller_pro_monthly';
  static const annual = 'seller_pro_annual';
  static const credits10 = 'quote_credits_10';
  static const credits50 = 'quote_credits_50';
  static const subscriptions = {monthly, annual};
  static const all = {monthly, annual, credits10, credits50};
}

/// Play Billing / StoreKit 2 via in_app_purchase. Purchases are sent to the
/// `verify-purchase` Edge Function, which validates with the Play Developer
/// API / App Store Server API before granting an entitlement.
class StoreBillingService implements BillingService {
  StoreBillingService(this._functions, this._config) {
    _sub = _iap.purchaseStream.listen(_onPurchases);
  }

  final EdgeFunctions _functions;
  final CountryConfig _config;
  final _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _pending = <String, Completer<PurchaseResult>>{};
  final _details = <String, ProductDetails>{};

  @override
  String get store => !kIsWeb && Platform.isIOS ? 'apple' : 'play';

  @override
  bool get supportsRestore => true;

  @override
  Future<List<PlanProduct>> products() async {
    if (!await _iap.isAvailable()) return const [];
    final resp = await _iap.queryProductDetails(ProductIds.all);
    return [
      for (final p in resp.productDetails)
        () {
          _details[p.id] = p;
          return PlanProduct(
            id: p.id,
            kind: p.id == ProductIds.monthly
                ? PlanKind.monthly
                : p.id == ProductIds.annual
                ? PlanKind.annual
                : PlanKind.credits,
            title: p.title,
            price: _config.money((p.rawPrice * 100).round()),
            priceText: p.price,
            credits: p.id == ProductIds.credits10
                ? 10
                : p.id == ProductIds.credits50
                ? 50
                : null,
          );
        }(),
    ];
  }

  @override
  Future<PurchaseResult> buy(PlanProduct product) {
    final details = _details[product.id];
    if (details == null) return Future.value(const PurchaseResult(success: false, error: 'unknown_product'));
    final c = Completer<PurchaseResult>();
    _pending[product.id] = c;
    final param = PurchaseParam(productDetails: details);
    if (ProductIds.subscriptions.contains(product.id)) {
      _iap.buyNonConsumable(purchaseParam: param);
    } else {
      _iap.buyConsumable(purchaseParam: param, autoConsume: true);
    }
    return c.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      final c = _pending.remove(p.productID);
      switch (p.status) {
        case PurchaseStatus.pending:
          c?.complete(const PurchaseResult(success: false, pending: true));
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          c?.complete(PurchaseResult(success: false, error: p.error?.message ?? 'cancelled'));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            await _functions.invoke('verify-purchase', {
              'store': store,
              'product_id': p.productID,
              'purchase_token': p.verificationData.serverVerificationData,
              'transaction_id': p.purchaseID,
            });
            c?.complete(const PurchaseResult(success: true));
          } catch (e) {
            c?.complete(PurchaseResult(success: false, error: '$e'));
          }
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Uri? manageSubscriptionsUrl(String? productId) => store == 'apple'
      ? Uri.parse('https://apps.apple.com/account/subscriptions')
      : Uri.parse(
          'https://play.google.com/store/account/subscriptions'
          '${productId == null ? '' : '?sku=$productId&package=com.calecute.iwant.${_config.country.name}'}',
        );

  void dispose() => _sub.cancel();
}

/// Stripe (USA) or Razorpay (India) checkout on the web, used where store
/// policy allows external purchase links and by the web seller dashboard.
class WebCheckoutBillingService implements BillingService {
  WebCheckoutBillingService(this._functions, this._config);
  final EdgeFunctions _functions;
  final CountryConfig _config;

  @override
  String get store => _config.paymentProvider == PaymentProvider.stripe ? 'stripe' : 'razorpay';

  @override
  bool get supportsRestore => false;

  @override
  Future<List<PlanProduct>> products() async {
    final res = await _functions.invoke('create-checkout', {'action': 'list_products'});
    return [
      for (final p in (res['products'] as List? ?? const []))
        PlanProduct(
          id: p['id'] as String,
          kind: PlanKind.values.byName(p['kind'] as String),
          title: p['title'] as String,
          price: _config.money((p['amount_minor'] as num).toInt()),
          credits: (p['credits'] as num?)?.toInt(),
        ),
    ];
  }

  @override
  Future<PurchaseResult> buy(PlanProduct product) async {
    final res = await _functions.invoke('create-checkout', {'action': 'checkout', 'product_id': product.id});
    final url = res['url'] as String?;
    if (url == null) return const PurchaseResult(success: false, error: 'no_url');
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    // The webhook grants the entitlement; the plan screen refreshes on return.
    return const PurchaseResult(success: false, pending: true);
  }

  @override
  Future<void> restore() async {}

  @override
  Uri? manageSubscriptionsUrl(String? productId) => Uri.https(_config.webDomain, '/seller/billing');
}

/// Demo mode: shows representative local prices, buys nothing.
class DemoBillingService implements BillingService {
  DemoBillingService(this._config);
  final CountryConfig _config;

  @override
  String get store => 'demo';
  @override
  bool get supportsRestore => true;

  @override
  Future<List<PlanProduct>> products() async {
    final india = _config.country == Country.india;
    return [
      PlanProduct(
        id: ProductIds.monthly,
        kind: PlanKind.monthly,
        title: 'Pro',
        price: _config.money(india ? 19900 : 1999),
        trialDays: 14,
      ),
      PlanProduct(
        id: ProductIds.annual,
        kind: PlanKind.annual,
        title: 'Pro',
        price: _config.money(india ? 199900 : 19900),
      ),
      PlanProduct(
        id: ProductIds.credits10,
        kind: PlanKind.credits,
        title: '10 credits',
        price: _config.money(india ? 9900 : 999),
        credits: 10,
      ),
    ];
  }

  @override
  Future<PurchaseResult> buy(PlanProduct product) async => const PurchaseResult(success: true);
  @override
  Future<void> restore() async {}
  @override
  Uri? manageSubscriptionsUrl(String? productId) => null;
}

@Riverpod(keepAlive: true)
BillingService billingService(Ref ref) {
  final config = ref.watch(countryConfigProvider);
  final backend = ref.watch(backendProvider);
  if (backend.isDemo) return DemoBillingService(config);
  final functions = ref.watch(edgeFunctionsProvider);
  if (kIsWeb) return WebCheckoutBillingService(functions, config);
  final s = StoreBillingService(functions, config);
  ref.onDispose(s.dispose);
  return s;
}
