import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/seller_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stats = ref.watch(sellerStatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      body: AsyncView(
        value: stats,
        onRetry: () => ref.invalidate(sellerStatsProvider),
        data: (s) {
          final tiles = [
            (l10n.dashActive, '${s.activeQuotes}', Icons.request_quote_outlined),
            (l10n.dashWon, '${s.won}', Icons.emoji_events_outlined),
            (l10n.dashWinRate, '${(s.winRate * 100).round()}%', Icons.percent_rounded),
            (l10n.dashResponse, s.avgResponseMins == null ? '—' : context.shortDuration(Duration(minutes: s.avgResponseMins!)), Icons.timer_outlined),
            (l10n.dashRevenue, s.revenueLogged?.displayCompact ?? '—', Icons.payments_outlined),
            (l10n.dashRating, s.ratingCount == 0 ? '—' : '${s.ratingAvg.toStringAsFixed(1)} ★', Icons.star_outline_rounded),
            (l10n.dashQuotesThisMonth, '${s.quotesThisMonth}', Icons.calendar_month_outlined),
          ];
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(sellerStatsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: tiles.length + 1,
              itemBuilder: (_, i) {
                if (i == tiles.length) {
                  return Card(
                    child: InkWell(
                      onTap: () => context.push('/orders'),
                      child: Center(child: Text(l10n.ordersTitle, style: context.text.titleMedium)),
                    ),
                  );
                }
                final (label, value, icon) = tiles[i];
                return Semantics(
                  label: '$label: $value',
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(icon, color: context.colors.primary),
                        const Spacer(),
                        Text(value, style: context.text.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                        Text(label, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
