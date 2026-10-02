import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/shell.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/domain/category.dart';
import '../../requests/presentation/category_picker.dart';
import '../application/seller_providers.dart';
import '../domain/lead.dart';

class LeadFeedScreen extends ConsumerWidget {
  const LeadFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final seller = ref.watch(mySellerProvider);
    final feed = ref.watch(leadFeedProvider);
    final filters = ref.watch(leadFilterStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.leadsTitle),
        actions: [
          IconButton(
            tooltip: l10n.dashboardTitle,
            onPressed: () => context.push('/seller/dashboard'),
            icon: const Icon(Icons.insights_outlined),
          ),
          const NotificationsBell(),
        ],
      ),
      body: seller.when(
        loading: () => const SkeletonList(),
        error: (_, _) => ErrorView(onRetry: () => ref.invalidate(mySellerProvider)),
        data: (s) {
          if (s == null) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              message: l10n.leadsNoSellerProfile,
              action: FilledButton(
                onPressed: () => context.push('/seller/onboarding'),
                child: Text(l10n.sellerOnboardingTitle),
              ),
            );
          }
          return Column(
            children: [
              _FilterBar(filters: filters),
              if (!s.isVerified)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.verified_outlined),
                  title: Text(l10n.leadPriorityNote),
                  trailing: TextButton(
                    onPressed: () => context.push('/seller/verification'),
                    child: Text(l10n.verificationTitle),
                  ),
                ),
              Expanded(
                child: AsyncView(
                  value: feed,
                  onRetry: () => ref.invalidate(leadFeedProvider),
                  data: (leads) => leads.isEmpty
                      ? EmptyState(icon: Icons.inbox_outlined, message: l10n.leadsEmpty)
                      : RefreshIndicator(
                          onRefresh: () async => ref.invalidate(leadFeedProvider),
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (n) {
                              if (n.metrics.extentAfter < 400) ref.read(leadFeedProvider.notifier).loadMore();
                              return false;
                            },
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: leads.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (_, i) => MaxWidth(child: LeadCard(lead: leads[i])),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.filters});
  final LeadFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    final seller = ref.watch(mySellerProvider).value;
    final notifier = ref.read(leadFilterStateProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          FilterChip(
            avatar: const Icon(Icons.category_outlined, size: 18),
            label: Text(
              filters.categoryId == null
                  ? '${l10n.leadFilterCategory}: ${l10n.leadFilterAny}'
                  : cats[filters.categoryId]?.name(context.lang) ?? '',
            ),
            selected: filters.categoryId != null,
            onSelected: (_) async {
              if (filters.categoryId != null) {
                notifier.set(filters.copyWith(categoryId: null));
                return;
              }
              final mine = cats.values
                  .where((c) => c.parentId == null || (seller?.categoryIds.contains(c.id) ?? false))
                  .toList();
              final picked = await showCategoryPicker(context, mine);
              if (picked != null) notifier.set(filters.copyWith(categoryId: picked.id));
            },
          ),
          const SizedBox(width: 8),
          for (final km in const [5, 10, 25, 50])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${l10n.leadFilterDistance} ${config.formatDistance(km.toDouble())}'),
                selected: filters.maxDistanceKm == km,
                onSelected: (on) => notifier.set(filters.copyWith(maxDistanceKm: on ? km : null)),
              ),
            ),
        ],
      ),
    );
  }
}

class LeadCard extends ConsumerWidget {
  const LeadCard({super.key, required this.lead});
  final Lead lead;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(countryConfigProvider);
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};
    final l = lead;
    final budget = l.budgetMin != null || l.budgetMax != null
        ? l10n.leadBudget(moneyRange(l.budgetMin, l.budgetMax))
        : l10n.leadBudgetHidden;
    return Dismissible(
      key: ValueKey(l.requestId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: context.colors.errorContainer, borderRadius: BorderRadius.circular(14)),
        child: Text(l10n.leadDismiss, style: TextStyle(color: context.colors.onErrorContainer)),
      ),
      onDismissed: (_) => ref.read(leadFeedProvider.notifier).dismiss(l.requestId),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/seller/leads/${l.requestId}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!l.seen)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: CircleAvatar(radius: 4, backgroundColor: context.colors.primary),
                      ),
                    Expanded(
                      child: Text(
                        cats[l.categoryId]?.name(context.lang) ?? '',
                        style: context.text.labelLarge?.copyWith(color: context.colors.primary),
                      ),
                    ),
                    Text(context.shortDuration(DateTime.now().difference(l.createdAt)), style: context.text.labelSmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Text(budget, style: context.text.bodySmall),
                    if (l.distanceKm != null)
                      Text(l10n.leadAway(config.formatDistance(l.distanceKm!)), style: context.text.bodySmall),
                    if (l.locality != null) Text(l.locality!, style: context.text.bodySmall),
                    if (l.neededBy != null)
                      Text(l10n.leadNeededBy(context.date(l.neededBy!)), style: context.text.bodySmall),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.isFull ? l10n.leadFull : l10n.leadQuotesSent(l.quoteCount, l.maxQuotes),
                            style: context.text.labelMedium,
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: l.maxQuotes == 0 ? 0 : l.quoteCount / l.maxQuotes,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (l.alreadyQuoted)
                      StatusChip(l10n.leadAlreadyQuoted, color: Colors.green.shade700)
                    else
                      FilledButton.tonal(
                        onPressed: l.isFull ? null : () => context.push('/seller/leads/${l.requestId}/quote'),
                        child: Text(l10n.leadSendQuote),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
