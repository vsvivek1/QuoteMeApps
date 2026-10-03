import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/data/supabase/edge_functions.dart';
import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../billing/data/billing_services.dart';
import '../../billing/domain/billing_service.dart';
import '../application/seller_providers.dart';
import '../domain/seller_repository.dart';

final _productsProvider = FutureProvider.autoDispose<List<PlanProduct>>(
  (ref) => ref.watch(billingServiceProvider).products(),
);

final _onboardingFeeProvider = FutureProvider.autoDispose<OnboardingFee?>(
  (ref) => ref.watch(sellerRepositoryProvider).onboardingFee(),
);

/// Plan and billing. While `monetization_enabled` is off everything is free
/// and no paywall is shown. The paywall states price, period, auto-renewal,
/// how to cancel, Terms/Privacy, and offers Restore Purchases.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final flags = ref.watch(appFlagsProvider).value;
    final seller = ref.watch(mySellerProvider).value;
    final billing = ref.watch(billingServiceProvider);
    final freeUntil = seller?.freeUntil ?? flags?.earlyPartnerFreeUntil;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.planTitle)),
      body: MaxWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (seller?.earlyPartner ?? false)
              Card(
                color: context.colors.primaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: Text(
                    freeUntil == null ? l10n.quoteFoundingPartner : l10n.foundingPartnerBadge(context.date(freeUntil)),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            ..._onboardingFee(context, ref),
            if (flags == null || !flags.monetizationEnabled)
              EmptyState(icon: Icons.celebration_outlined, message: l10n.planFreeLaunch)
            else
              ..._paywall(context, ref, billing),
          ],
        ),
      ),
    );
  }

  /// I Want USA one-time fee, paid by Stripe Checkout in the browser.
  List<Widget> _onboardingFee(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final fee = ref.watch(_onboardingFeeProvider).value;
    if (fee == null || !(fee.due || fee.paid)) return const [];
    if (fee.paid) {
      return [
        Card(child: ListTile(leading: const Icon(Icons.verified_outlined), title: Text(l10n.onboardingFeePaid))),
        const SizedBox(height: 12),
      ];
    }
    final amount = ref.watch(countryConfigProvider).money(fee.amountMinor).display;
    return [
      Card(
        color: context.colors.secondaryContainer,
        child: ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text(l10n.onboardingFeeTitle),
          subtitle: Text(l10n.onboardingFeeBody),
          trailing: FilledButton(
            onPressed: () async {
              final res = await ref.read(edgeFunctionsProvider).invoke('create-checkout', {
                'product_id': 'seller_onboarding',
              });
              final url = res['url'];
              if (url is String) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              ref.invalidate(_onboardingFeeProvider);
            },
            child: Text(l10n.onboardingFeePay(amount)),
          ),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _paywall(BuildContext context, WidgetRef ref, BillingService billing) {
    final l10n = context.l10n;
    final products = ref.watch(_productsProvider);
    final storeName = billing.store == 'apple'
        ? 'App Store'
        : billing.store == 'play'
        ? 'Google Play'
        : billing.store;
    return [
      products.when(
        loading: () => const SkeletonList(count: 3),
        error: (_, _) => Text(l10n.planNotAvailable),
        data: (list) => Column(
          children: [
            for (final p in list)
              Card(
                child: ListTile(
                  title: Text(switch (p.kind) {
                    PlanKind.monthly => l10n.planMonthly,
                    PlanKind.annual => l10n.planAnnual,
                    PlanKind.credits => l10n.planCredits,
                  }),
                  subtitle: Text(
                    [
                      p.priceText ?? p.price.display,
                      if (p.credits != null) l10n.planCreditsBalance(p.credits!),
                    ].join(' · '),
                  ),
                  trailing: FilledButton(
                    onPressed: () async {
                      final r = await billing.buy(p);
                      if (r.success) {
                        await ref.read(analyticsProvider).log(
                          p.kind == PlanKind.credits
                              ? AnalyticsEvent.creditPackBought
                              : AnalyticsEvent.subscriptionStarted,
                          {'product_id': p.id, 'store': billing.store},
                        );
                        ref.invalidate(mySellerProvider);
                      }
                    },
                    child: Text(p.kind == PlanKind.credits ? l10n.planBuyCredits : l10n.planSubscribe),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Text(l10n.planRenewal(storeName), style: context.text.bodySmall),
      Wrap(
        spacing: 8,
        children: [
          TextButton(onPressed: () => context.push('/legal/subscription-terms'), child: Text(l10n.termsLink)),
          TextButton(onPressed: () => context.push('/legal/privacy'), child: Text(l10n.privacyLink)),
          if (billing.supportsRestore) TextButton(onPressed: billing.restore, child: Text(l10n.planRestore)),
          if (billing.manageSubscriptionsUrl(null) != null)
            TextButton(
              onPressed: () => launchUrl(billing.manageSubscriptionsUrl(null)!, mode: LaunchMode.externalApplication),
              child: Text(l10n.planManage),
            ),
        ],
      ),
    ];
  }
}
