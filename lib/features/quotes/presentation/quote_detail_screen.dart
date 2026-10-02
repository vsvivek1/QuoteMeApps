import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money/money.dart';
import '../../../core/analytics/analytics.dart';
import '../../../core/money/tax.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../../safety/presentation/report_sheet.dart';
import '../application/quote_actions.dart';
import '../domain/quote.dart';
import 'quote_card.dart';

final _quoteProvider = FutureProvider.autoDispose.family<Quote?, String>(
  (ref, id) => ref.watch(quoteRepositoryProvider).getQuote(id),
);

class QuoteDetailScreen extends ConsumerStatefulWidget {
  const QuoteDetailScreen({super.key, required this.quoteId});
  final String quoteId;

  @override
  ConsumerState<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends ConsumerState<QuoteDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(quoteRepositoryProvider).markViewed(widget.quoteId);
    ref.read(analyticsProvider).log(AnalyticsEvent.quoteViewed, {'quote_id': widget.quoteId});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final initial = ref.watch(_quoteProvider(widget.quoteId));
    return AsyncView(
      value: initial,
      loading: const Scaffold(body: SkeletonList()),
      data: (first) {
        if (first == null) return Scaffold(appBar: AppBar(), body: const ErrorView());
        // Follow live updates through the request's quote stream.
        final live = ref.watch(requestQuotesProvider(first.requestId)).value;
        final q = live?.where((x) => x.id == first.id).firstOrNull ?? first;
        final actions = QuoteActions(context, ref);
        return Scaffold(
          appBar: AppBar(
            title: Text(q.seller.businessName),
            actions: [
              IconButton(
                tooltip: l10n.report,
                onPressed: () => showReportSheet(context, ref, targetType: 'quote', targetId: q.id),
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          body: MaxWidth(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(q.seller.businessName.characters.first)),
                  title: Row(
                    children: [
                      Flexible(child: Text(q.seller.businessName)),
                      if (q.seller.verified) ...[const SizedBox(width: 4), const VerifiedBadge()],
                    ],
                  ),
                  subtitle: q.seller.ratingCount > 0
                      ? RatingStars(rating: q.seller.ratingAvg, count: q.seller.ratingCount)
                      : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/s/${q.seller.id}'),
                ),
                if (q.seller.earlyPartner) StatusChip(l10n.quoteFoundingPartner),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (final line in q.lines) _Row('${line.description} × ${line.qty}', line.lineTotal.display),
                        const Divider(),
                        _Row(l10n.quoteSubtotal, q.subtotal.display),
                        ..._taxRows(context, q),
                        _Row(l10n.quoteDelivery, q.delivery.isZeroAmount ? l10n.quoteFreeDelivery : q.delivery.display),
                        const Divider(),
                        _Row(l10n.quoteTotal, q.total.display, bold: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (q.offeredBrandModel != null) _Row(l10n.quoteOffered, q.offeredBrandModel!),
                if (q.deliveryDate != null) _Row(l10n.quoteDeliveryDate, context.date(q.deliveryDate!)),
                if (q.warranty != null) _Row(l10n.quoteWarranty, q.warranty!),
                if (q.validUntil != null)
                  Text(l10n.quoteValidUntil(context.date(q.validUntil!)), style: context.text.bodySmall),
                if (q.notes != null && q.notes!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(l10n.quoteNotes, style: context.text.labelLarge),
                  Text(q.notes!),
                ],
                const SizedBox(height: 8),
                Text(
                  q.taxBreakdown is GstBreakdown ? l10n.taxIncludedNote : l10n.salesTaxNote,
                  style: context.text.bodySmall,
                ),
                if (!q.isActive) ...[const SizedBox(height: 12), StatusChip(quoteStatusLabel(context, q.status))],
              ],
            ),
          ),
          bottomNavigationBar: q.isActive
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconButton.outlined(
                          onPressed: () => actions.chat(q),
                          icon: const Icon(Icons.chat_bubble_outline_rounded),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => actions.counterOffer(q),
                            child: Text(l10n.counterOffer, textAlign: TextAlign.center),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton(onPressed: () => actions.accept(q), child: Text(l10n.accept)),
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  List<Widget> _taxRows(BuildContext context, Quote q) {
    final b = q.taxBreakdown;
    if (b is GstBreakdown) {
      final half = bpToPercent(b.rateBp ~/ 2);
      return b.intraState
          ? [_Row('CGST $half%', b.cgst.display), _Row('SGST $half%', b.sgst.display)]
          : [_Row('IGST ${bpToPercent(b.rateBp)}%', b.igst.display)];
    }
    return [_Row(taxLabel(context, b), q.tax.display)];
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? context.text.titleMedium?.copyWith(fontWeight: FontWeight.w800) : context.text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
