import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/category.dart';
import '../../requests/presentation/dynamic_fields.dart';
import '../../safety/presentation/report_sheet.dart';
import '../application/seller_providers.dart';

/// Everything about a request except the buyer's contact details and exact
/// address (only the locality is shown).
class LeadDetailScreen extends ConsumerStatefulWidget {
  const LeadDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends ConsumerState<LeadDetailScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(leadRepositoryProvider).markSeen(widget.requestId);
    ref.read(analyticsProvider).log(AnalyticsEvent.leadViewed, {'request_id': widget.requestId});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final lead = ref.watch(leadProvider(widget.requestId));
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    return AsyncView(
      value: lead,
      loading: const Scaffold(body: SkeletonList()),
      data: (l) {
        if (l == null) return Scaffold(appBar: AppBar(), body: const ErrorView());
        final cat = cats[l.categoryId];
        final disclaimer = cat?.disclaimerText(context.lang);
        return Scaffold(
          appBar: AppBar(
            title: Text(cat?.name(context.lang) ?? ''),
            actions: [
              IconButton(
                tooltip: l10n.report,
                onPressed: () => showReportSheet(context, ref, targetType: 'request', targetId: l.requestId),
                icon: const Icon(Icons.flag_outlined),
              ),
            ],
          ),
          body: MaxWidth(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(l.title, style: context.text.headlineSmall),
              if (l.buyerFirstName != null) Text(l.buyerFirstName!, style: context.text.bodySmall),
              const SizedBox(height: 12),
              if (l.description.isNotEmpty && l.description != l.title) Text(l.description),
              if (cat != null) ...[
                const SizedBox(height: 12),
                FieldSummary(fields: cat.fields, values: l.fields),
              ],
              if (l.media.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView(scrollDirection: Axis.horizontal, children: [
                    for (final m in l.media)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (m.url ?? '').startsWith('http')
                              ? CachedNetworkImage(imageUrl: m.url!, width: 120, height: 120, fit: BoxFit.cover)
                              : Container(width: 120, height: 120, color: context.colors.surfaceContainerHighest, child: const Icon(Icons.image)),
                        ),
                      ),
                  ]),
                ),
              ],
              const Divider(height: 32),
              _row(context, Icons.payments_outlined,
                  l.budgetMin != null || l.budgetMax != null ? l10n.leadBudget(moneyRange(l.budgetMin, l.budgetMax)) : l10n.leadBudgetHidden),
              if (l.neededBy != null) _row(context, Icons.event_outlined, l10n.leadNeededBy(context.date(l.neededBy!))),
              _row(context, Icons.place_outlined,
                  [l.locality, l.locationCode, if (l.distanceKm != null) l10n.leadAway(config.formatDistance(l.distanceKm!))]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' · ')),
              _row(context, Icons.groups_outlined, l10n.leadQuotesSent(l.quoteCount, l.maxQuotes)),
              if (l.quoteWindowEndsAt != null && l.quoteWindowEndsAt!.isAfter(DateTime.now()))
                _row(context, Icons.timer_outlined, l10n.closesIn(context.shortDuration(l.quoteWindowEndsAt!.difference(DateTime.now())))),
              const SizedBox(height: 12),
              Text(l10n.leadLocalityOnly, style: context.text.bodySmall),
              if (disclaimer != null) ...[
                const SizedBox(height: 12),
                Text(disclaimer, style: context.text.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                IconButton.outlined(
                  tooltip: l10n.chat,
                  onPressed: () async {
                    final me = ref.read(authSessionProvider).value!.userId;
                    final chatId = await ref.read(chatRepositoryProvider).openChat(requestId: l.requestId, sellerId: me);
                    if (context.mounted) context.push('/chats/$chatId');
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(leadFeedProvider.notifier).dismiss(l.requestId);
                    if (context.mounted) context.pop();
                  },
                  child: Text(l10n.leadDismiss),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: l.isFull || l.alreadyQuoted ? null : () => context.push('/seller/leads/${l.requestId}/quote'),
                    child: Text(l.alreadyQuoted ? l10n.leadAlreadyQuoted : l10n.leadSendQuote),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, size: 20, color: context.colors.outline),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}
