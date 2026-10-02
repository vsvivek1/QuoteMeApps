import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/money/tax.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/quote_actions.dart';
import '../domain/quote.dart';

/// A quote as the buyer sees it in the list: total incl. tax and delivery,
/// item offered, delivery date, warranty, rating, distance, verified badge and
/// response time.
class QuoteCard extends ConsumerWidget {
  const QuoteCard({
    super.key,
    required this.quote,
    required this.requestCreatedAt,
    this.onTap,
    this.selectable = false,
    this.selected = false,
    this.onSelected,
    this.showActions = true,
  });

  final Quote quote;
  final DateTime requestCreatedAt;
  final VoidCallback? onTap;
  final bool selectable;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final q = quote;
    final actions = QuoteActions(context, ref);
    final dim = !q.isActive && q.status != QuoteStatus.accepted;
    return Opacity(
      opacity: dim ? 0.6 : 1,
      child: Card(
        color: selected ? context.colors.primaryContainer.withValues(alpha: 0.4) : null,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selectable ? () => onSelected?.call(!selected) : onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (selectable)
                  Checkbox(value: selected, onChanged: (v) => onSelected?.call(v ?? false)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Flexible(
                        child: Text(q.seller.businessName,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ),
                      if (q.seller.verified) ...[const SizedBox(width: 4), const VerifiedBadge(compact: true)],
                    ]),
                    const SizedBox(height: 2),
                    Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      if (q.seller.ratingCount > 0) RatingStars(rating: q.seller.ratingAvg, count: q.seller.ratingCount),
                      if (q.seller.distanceKm != null)
                        Text(config.formatDistance(q.seller.distanceKm!), style: context.text.bodySmall),
                      Text(l10n.quoteResponseTime(context.shortDuration(q.createdAt.difference(requestCreatedAt))),
                          style: context.text.bodySmall),
                    ]),
                  ]),
                ),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(q.total.displayCompact,
                      style: context.text.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: context.colors.primary)),
                  if (!q.viewedByBuyer && q.isActive) StatusChip(l10n.quoteNew, color: Colors.green.shade700)
                  else if (q.status != QuoteStatus.sent) StatusChip(quoteStatusLabel(context, q.status)),
                ]),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 16, runSpacing: 6, children: [
                if (q.offeredBrandModel != null) _Info(Icons.sell_outlined, q.offeredBrandModel!),
                if (q.deliveryDate != null) _Info(Icons.local_shipping_outlined, context.date(q.deliveryDate!)),
                if (q.warranty != null) _Info(Icons.shield_outlined, q.warranty!),
                _Info(Icons.receipt_outlined, taxLabel(context, q.taxBreakdown)),
                if (q.delivery.isZeroAmount) _Info(Icons.check_circle_outline, '${l10n.quoteDelivery}: ${l10n.quoteFreeDelivery}'),
              ]),
              if (q.counterOfferTarget != null) ...[
                const SizedBox(height: 8),
                Text(l10n.counterOfferFrom(q.counterOfferTarget!.displayCompact),
                    style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
              if (showActions && q.isActive && !selectable) ...[
                const SizedBox(height: 12),
                Row(children: [
                  IconButton.outlined(
                    tooltip: l10n.chat,
                    onPressed: () => actions.chat(q),
                    icon: const Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: q.status == QuoteStatus.shortlisted ? l10n.shortlisted : l10n.shortlist,
                    onPressed: () => actions.toggleShortlist(q),
                    icon: Icon(q.status == QuoteStatus.shortlisted ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                  ),
                  const Spacer(),
                  TextButton(onPressed: () => actions.decline(q), child: Text(l10n.decline)),
                  const SizedBox(width: 4),
                  FilledButton(onPressed: () => actions.accept(q), child: Text(l10n.accept)),
                ]),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

String taxLabel(BuildContext context, TaxBreakdown b) {
  final l10n = context.l10n;
  return switch (b) {
    GstBreakdown(intraState: true, :final rateBp) => l10n.gstIntra(bpToPercent(rateBp ~/ 2)),
    GstBreakdown(:final rateBp) => l10n.gstInter(bpToPercent(rateBp)),
    SalesTaxBreakdown(:final rateBp) => l10n.salesTax(bpToPercent(rateBp)),
    NoTaxBreakdown() => l10n.quoteTax,
  };
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: context.colors.outline),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: context.text.bodySmall)),
      ]);
}
