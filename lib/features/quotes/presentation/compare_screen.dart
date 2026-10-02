import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../application/quote_actions.dart';
import '../domain/quote.dart';
import 'quote_card.dart';

/// Up to 3 quotes side by side.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key, required this.requestId, this.quoteIds});
  final String requestId;
  final List<String>? quoteIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final quotes = ref.watch(requestQuotesProvider(requestId));
    return Scaffold(
      appBar: AppBar(title: Text(l10n.compare)),
      body: AsyncView(
        value: quotes,
        data: (all) {
          final list = (quoteIds == null ? all.where((q) => q.isActive) : all.where((q) => quoteIds!.contains(q.id)))
              .take(3)
              .toList();
          final cheapest = list.isEmpty ? null : list.map((q) => q.total.minorUnits).reduce((a, b) => a < b ? a : b);
          final actions = QuoteActions(context, ref);
          final rows = <(String, String Function(Quote))>[
            (l10n.quoteTotal, (q) => q.total.display),
            (l10n.quoteSubtotal, (q) => q.subtotal.display),
            (l10n.quoteTax, (q) => '${q.tax.display}\n${taxLabel(context, q.taxBreakdown)}'),
            (l10n.quoteDelivery, (q) => q.delivery.isZeroAmount ? l10n.quoteFreeDelivery : q.delivery.display),
            (l10n.quoteOffered, (q) => q.offeredBrandModel ?? '—'),
            (l10n.quoteDeliveryDate, (q) => q.deliveryDate == null ? '—' : context.date(q.deliveryDate!)),
            (l10n.quoteWarranty, (q) => q.warranty ?? '—'),
            (
              l10n.sortRating,
              (q) => q.seller.ratingCount == 0
                  ? '—'
                  : '${q.seller.ratingAvg.toStringAsFixed(1)} ★ (${q.seller.ratingCount})',
            ),
            (l10n.sortDistance, (q) => q.seller.distanceKm == null ? '—' : config.formatDistance(q.seller.distanceKm!)),
            (l10n.quoteVerified, (q) => q.seller.verified ? '✓' : '—'),
          ];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowHeight: 72,
                dataRowMaxHeight: 72,
                columns: [
                  const DataColumn(label: SizedBox.shrink()),
                  for (final q in list)
                    DataColumn(
                      label: SizedBox(
                        width: 140,
                        child: Text(
                          q.seller.businessName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.titleSmall,
                        ),
                      ),
                    ),
                ],
                rows: [
                  for (final (label, value) in rows)
                    DataRow(
                      cells: [
                        DataCell(Text(label, style: context.text.labelLarge)),
                        for (final q in list)
                          DataCell(
                            SizedBox(
                              width: 140,
                              child: Text(
                                value(q),
                                style: label == l10n.quoteTotal && q.total.minorUnits == cheapest
                                    ? TextStyle(fontWeight: FontWeight.w800, color: Colors.green.shade700)
                                    : null,
                              ),
                            ),
                          ),
                      ],
                    ),
                  DataRow(
                    cells: [
                      const DataCell(SizedBox.shrink()),
                      for (final q in list)
                        DataCell(
                          q.isActive
                              ? FilledButton(onPressed: () => actions.accept(q), child: Text(l10n.accept))
                              : Text(quoteStatusLabel(context, q.status)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
