import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../application/seller_providers.dart';
import '../domain/manual_payment.dart';
import '../domain/seller_models.dart';
import 'manual_payment_dialog.dart';

class SellerDetailScreen extends ConsumerWidget {
  const SellerDetailScreen({super.key, required this.sellerId});
  final String sellerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final seller = ref.watch(sellerDetailProvider(sellerId));
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(Routes.sellers)),
        title: Text(seller.value?.businessName ?? l.seller),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
              ..invalidate(sellerDetailProvider(sellerId))
              ..invalidate(sellerEntitlementsProvider(sellerId)),
          ),
        ],
      ),
      body: AsyncView(
        value: seller,
        onRetry: () => ref.invalidate(sellerDetailProvider(sellerId)),
        builder: (s) => ListView(padding: const EdgeInsets.all(16), children: [
          _SellerInfo(s),
          const SizedBox(height: 16),
          _Plans(s),
        ]),
      ),
    );
  }
}

class _SellerInfo extends StatelessWidget {
  const _SellerInfo(this.s);
  final SellerSummary s;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final place = [s.city, s.state].whereType<String>().join(', ');
    Widget row(String k, String? v) => v == null || v.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 140, child: Text(k, style: t.bodySmall)),
              Expanded(child: SelectableText(v)),
            ]),
          );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.businessName, style: t.titleLarge),
          const SizedBox(height: 8),
          row(l.ownerName, s.ownerName),
          row(l.phone, s.phone),
          row(l.businessPhone, s.businessPhone),
          row(l.email, s.email),
          row(l.city, place),
          row(l.verificationStatus, s.verificationStatus),
          if (s.earlyPartner) row('', l.foundingPartnerFreeUntil(fmtDate(s.freeUntil))),
          row('ID', s.id),
        ]),
      ),
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans(this.seller);
  final SellerSummary seller;

  Future<void> _record(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final row = await showManualPaymentDialog(context, seller);
    if (row == null || !context.mounted) return;
    invalidateAfterGrant(ref, seller.id);
    context.toast(l.grantDone(_entitlementTitle(l, row)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final t = Theme.of(context).textTheme;
    final ents = ref.watch(sellerEntitlementsProvider(seller.id));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(l.currentPlan, style: t.titleMedium)),
            FilledButton.icon(
              onPressed: () => _record(context, ref),
              icon: const Icon(Icons.payments_outlined),
              label: Text(l.recordPayment),
            ),
          ]),
          const SizedBox(height: 8),
          AsyncView(
            value: ents,
            onRetry: () => ref.invalidate(sellerEntitlementsProvider(seller.id)),
            builder: (rows) {
              final current = CurrentEntitlement.from(rows, DateTime.now());
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (current.isEmpty) Chip(label: Text(l.planNone)),
                  if (current.pro != null)
                    Chip(
                      avatar: const Icon(Icons.workspace_premium_outlined),
                      label: Text(current.pro!.expiresAt == null
                          ? l.planProOpenEnded
                          : l.planProUntil(fmtDate(current.pro!.expiresAt!.subtract(const Duration(seconds: 1))))),
                    ),
                  if (current.creditsBalance > 0)
                    Chip(
                      avatar: const Icon(Icons.toll_outlined),
                      label: Text(l.creditsBalance(current.creditsBalance)),
                    ),
                ]),
                const SizedBox(height: 16),
                Text(l.planHistory, style: t.titleSmall),
                if (rows.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 8), child: Text(l.planHistoryEmpty))
                else
                  for (final e in rows) _EntitlementTile(e),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

String _entitlementTitle(AppLocalizations l, EntitlementRecord e) {
  final pay = e.manualPayment;
  final plan = ManualPlan.values.where((p) => p.id == (pay?['plan'] ?? e.productId)).firstOrNull;
  final name = plan != null ? manualPlanLabel(l, plan) : e.productId;
  return e.expiresAt == null ? name : '$name, ${l.planProUntil(fmtDate(e.expiresAt!.subtract(const Duration(seconds: 1))))}';
}

class _EntitlementTile extends StatelessWidget {
  const _EntitlementTile(this.e);
  final EntitlementRecord e;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pay = e.manualPayment;
    final amount = pay?['amount_minor'];
    final lines = <String>[
      [e.tier, e.status, e.store, if (e.provider != null) e.provider!, if (e.tier == 'credits') '${e.creditsBalance}']
          .join(' · '),
      if (pay != null)
        [
          l.manualPaymentLine(
            paymentMethodLabel(l, '${pay['method']}'),
            '${pay['currency'] ?? ''}',
            amount is int ? formatMinor(amount) : '?',
            '${pay['ref']}',
          ),
          if (pay['payer'] != null) l.paidBy('${pay['payer']}'),
        ].join(', ')
      else if (e.note != null && e.note!.isNotEmpty)
        e.note!,
      fmtDateTime(e.createdAt),
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(e.tier == 'pro' ? Icons.workspace_premium_outlined : Icons.toll_outlined),
      title: Text(_entitlementTitle(l, e)),
      subtitle: Text(lines.join('\n')),
      isThreeLine: true,
    );
  }
}
