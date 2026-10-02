import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/router.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/formatting.dart';
import '../../../core/widgets/async_view.dart';
import '../../outreach/domain/outreach_models.dart';
import '../../outreach/presentation/stage_labels.dart';
import '../application/dashboard_providers.dart';
import '../domain/metrics.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.navDashboard),
        actions: [
          IconButton(
            tooltip: l.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardMetricsProvider),
          ),
        ],
      ),
      body: AsyncView(
        value: metrics,
        onRetry: () => ref.invalidate(dashboardMetricsProvider),
        builder: (m) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Section(title: l.dashQueues, tiles: [
              _Tile(l.kpiPendingVerifications, fmtInt(m.pendingVerifications),
                  icon: Icons.verified_user_outlined, onTap: () => context.go(Routes.verification)),
              _Tile(l.kpiPendingLicences, fmtInt(m.pendingLicences),
                  icon: Icons.badge_outlined, onTap: () => context.go(Routes.verification)),
              _Tile(l.kpiOpenReports, fmtInt(m.openReports),
                  icon: Icons.flag_outlined, onTap: () => context.go(Routes.moderation)),
            ]),
            _Section(title: l.dashMarketplace, tiles: [
              _Tile(l.kpiTimeToFirstQuote, fmtMins(m.medianFirstQuoteMins), hint: l.kpiTimeToFirstQuoteHint),
              _Tile(l.kpiRequests3Quotes, fmtPct(m.requestsWith3QuotesPct)),
              _Tile(l.kpiRequestToAcceptance, fmtPct(m.requestToAcceptancePct)),
              _Tile(l.kpiSellerResponseRate, fmtPct(m.sellerResponseRatePct)),
              _Tile(l.kpiFreeToPaid, fmtPct(m.freeToPaidPct)),
              _Tile(l.kpiRevenuePerSeller, m.revenuePerSellerMinor == null ? 'n/a' : fmtInt(m.revenuePerSellerMinor! ~/ 100)),
              _Tile(l.kpiRefunds, fmtInt(m.refunds30d)),
              _Tile(l.kpiOpenRequests, fmtInt(m.openRequests)),
              _Tile(l.kpiRequests7d, fmtInt(m.requests7d)),
              _Tile(l.kpiQuotes7d, fmtInt(m.quotes7d)),
              _Tile(l.kpiOrders7d, fmtInt(m.orders7d)),
              _Tile(l.kpiUsers, fmtInt(m.users)),
              _Tile(l.kpiSellers, '${fmtInt(m.sellers)} / ${fmtInt(m.verifiedSellers)} ${l.verified}'),
            ]),
            _Section(title: l.dashRetention, tiles: [
              for (final k in const ['buyer_d1', 'buyer_d7', 'buyer_d30', 'seller_d1', 'seller_d7', 'seller_d30'])
                _Tile(k.replaceAll('_', ' ').toUpperCase(), fmtPct(m.retention[k])),
            ]),
            _OutreachSection(m),
          ],
        ),
      ),
    );
  }
}

class _OutreachSection extends StatelessWidget {
  const _OutreachSection(this.m);
  final DashboardMetrics m;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cap = m.outreachDailyCapacity;
    final queue = m.outreachQueue;
    final days = (cap == null || cap == 0 || queue == null) ? null : (queue / cap).ceil();
    return _Section(title: l.dashOutreach, tiles: [
      for (final st in LeadStage.values)
        _Tile(stageLabel(context, st), fmtInt(m.leadsPerStage[st.wire]), onTap: () => context.go(Routes.outreach)),
      _Tile(l.kpiReplyRate, fmtPct(m.replyRatePct)),
      _Tile(l.kpiSignupRate, fmtPct(m.signupRatePct)),
      _Tile(l.kpiSentToday, '${fmtInt(m.outreachSentToday)} / ${fmtInt(cap)}'),
      _Tile(l.kpiQueue, fmtInt(queue), hint: days == null ? null : l.kpiQueueDays(days)),
    ]);
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});
  final String title;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: tiles),
        ]),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.label, this.value, {this.hint, this.icon, this.onTap});
  final String label;
  final String value;
  final String? hint;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (icon != null) ...[Icon(icon, size: 16), const SizedBox(width: 6)],
                Expanded(child: Text(label, style: t.labelMedium, maxLines: 2, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 6),
              Text(value, style: t.headlineSmall),
              if (hint != null) Text(hint!, style: t.bodySmall),
            ]),
          ),
        ),
      ),
    );
  }
}
