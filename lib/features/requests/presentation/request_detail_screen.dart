import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/analytics/analytics.dart';
import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../quotes/domain/quote.dart';
import '../../quotes/presentation/quote_card.dart';
import '../application/request_providers.dart';
import '../domain/buyer_request.dart';
import '../domain/category.dart';
import 'dynamic_fields.dart';
import 'widgets.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  QuoteSort _sort = QuoteSort.price;
  bool _selecting = false;
  final _selected = <String>{};

  Future<void> _share(BuyerRequest r, {bool whatsapp = false}) async {
    final config = ref.read(countryConfigProvider);
    final text = context.l10n.shareRequestText(config.requestLink(r.id).toString());
    if (whatsapp) {
      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  Future<void> _cancel(BuyerRequest r) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelRequest),
        content: Text(l10n.cancelRequestConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.no)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.yes)),
        ],
      ),
    );
    if (ok == true) await ref.read(requestRepositoryProvider).cancelRequest(r.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final request = ref.watch(requestProvider(widget.requestId));
    final quotes = ref.watch(requestQuotesProvider(widget.requestId));
    final cats = ref.watch(categoryMapProvider).value ?? const <int, Category>{};

    return AsyncView(
      value: request,
      loading: const Scaffold(body: SkeletonList()),
      data: (r) {
        if (r == null) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(onRetry: () => ref.invalidate(requestProvider(widget.requestId))),
          );
        }
        final cat = cats[r.categoryId];
        final list = sortQuotes(quotes.value ?? const [], _sort);
        return Scaffold(
          appBar: AppBar(
            title: Text(r.title, overflow: TextOverflow.ellipsis),
            actions: [
              IconButton(
                tooltip: l10n.shareRequest,
                onPressed: () => _share(r),
                icon: const Icon(Icons.share_outlined),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => switch (v) {
                  'whatsapp' => _share(r, whatsapp: true),
                  'cancel' => _cancel(r),
                  _ => null,
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'whatsapp', child: Text(l10n.shareRequestWhatsapp)),
                  if (r.isOpen) PopupMenuItem(value: 'cancel', child: Text(l10n.cancelRequest)),
                ],
              ),
            ],
          ),
          floatingActionButton: _selecting && _selected.length >= 2
              ? FloatingActionButton.extended(
                  onPressed: () {
                    ref.read(analyticsProvider).log(AnalyticsEvent.compareOpened, {'count': _selected.length});
                    context.push('/requests/${r.id}/compare', extra: _selected.toList());
                  },
                  icon: const Icon(Icons.compare_arrows_rounded),
                  label: Text('${l10n.compare} (${_selected.length})'),
                )
              : null,
          body: RefreshIndicator(
            onRefresh: () async => ref.invalidate(requestQuotesProvider(widget.requestId)),
            child: MaxWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  _Header(request: r, category: cat),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.quotesOfMax(r.quoteCount, r.maxQuotes),
                          style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (list.length >= 2)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _selecting = !_selecting;
                            _selected.clear();
                          }),
                          icon: Icon(_selecting ? Icons.close_rounded : Icons.compare_arrows_rounded),
                          label: Text(_selecting ? l10n.cancel : l10n.compare),
                        ),
                      PopupMenuButton<QuoteSort>(
                        tooltip: l10n.sortBy,
                        icon: const Icon(Icons.sort_rounded),
                        initialValue: _sort,
                        onSelected: (v) => setState(() => _sort = v),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: QuoteSort.price, child: Text(l10n.sortPrice)),
                          PopupMenuItem(value: QuoteSort.rating, child: Text(l10n.sortRating)),
                          PopupMenuItem(value: QuoteSort.deliveryDate, child: Text(l10n.sortDelivery)),
                          PopupMenuItem(value: QuoteSort.distance, child: Text(l10n.sortDistance)),
                        ],
                      ),
                    ],
                  ),
                  if (_selecting) Text(l10n.compareSelect, style: context.text.bodySmall),
                  const SizedBox(height: 8),
                  if (quotes.isLoading && !quotes.hasValue)
                    const SizedBox(height: 200, child: SkeletonList(count: 2))
                  else if (list.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: EmptyState(icon: Icons.hourglass_top_rounded, message: l10n.noQuotesYet),
                    )
                  else
                    for (final q in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: QuoteCard(
                          quote: q,
                          requestCreatedAt: r.createdAt,
                          showActions: r.isOpen,
                          selectable: _selecting,
                          selected: _selected.contains(q.id),
                          onSelected: (on) => setState(() {
                            if (on && _selected.length < 3) {
                              _selected.add(q.id);
                            } else {
                              _selected.remove(q.id);
                            }
                          }),
                          onTap: () => context.push('/quotes/${q.id}'),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request, required this.category});
  final BuyerRequest request;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final r = request;
    final ends = r.quoteWindowEndsAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusChip(requestStatusLabel(context, r.status), color: requestStatusColor(context, r.status)),
                const SizedBox(width: 8),
                if (category != null)
                  Expanded(child: Text(category!.name(context.lang), style: context.text.labelLarge)),
              ],
            ),
            if (r.description.isNotEmpty && r.description != r.title) ...[
              const SizedBox(height: 8),
              Text(r.description),
            ],
            if (category != null && r.fields.isNotEmpty) ...[
              const SizedBox(height: 8),
              FieldSummary(fields: category!.fields, values: r.fields),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (r.budgetMin != null || r.budgetMax != null)
                  Text('${l10n.postBudget}: ${moneyRange(r.budgetMin, r.budgetMax)}'),
                if (r.neededBy != null) Text(l10n.leadNeededBy(context.date(r.neededBy!))),
                if (r.locality != null || r.locationCode != null)
                  Text([r.locality, r.locationCode].whereType<String>().where((s) => s.isNotEmpty).join(', ')),
                if (r.isOpen && ends != null)
                  Text(
                    ends.isAfter(DateTime.now())
                        ? l10n.closesIn(context.shortDuration(ends.difference(DateTime.now())))
                        : l10n.closed,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
