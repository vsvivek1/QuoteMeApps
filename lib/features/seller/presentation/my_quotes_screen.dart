import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/routing/shell.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../quotes/application/quote_actions.dart';
import '../../quotes/domain/quote.dart';
import '../application/seller_providers.dart';

class MyQuotesScreen extends ConsumerWidget {
  const MyQuotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabMyQuotes),
          actions: [
            IconButton(tooltip: l10n.templatesTitle, onPressed: () => context.push('/seller/templates'), icon: const Icon(Icons.bookmarks_outlined)),
            const NotificationsBell(),
          ],
          bottom: TabBar(tabs: [
            Tab(text: l10n.myQuotesActive),
            Tab(text: l10n.myQuotesWon),
            Tab(text: l10n.myQuotesLost),
          ]),
        ),
        body: const TabBarView(children: [
          _QuoteList(bucket: 'active'),
          _QuoteList(bucket: 'won'),
          _QuoteList(bucket: 'lost'),
        ]),
      ),
    );
  }
}

class _QuoteList extends ConsumerWidget {
  const _QuoteList({required this.bucket});
  final String bucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final quotes = ref.watch(myQuotesProvider(bucket));
    return AsyncView(
      value: quotes,
      data: (list) => list.isEmpty
          ? EmptyState(icon: Icons.request_quote_outlined, message: l10n.myQuotesEmpty)
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final q = list[i];
                return Card(
                  child: ListTile(
                    title: Text(q.lines.isEmpty ? '' : q.lines.first.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${quoteStatusLabel(context, q.status)} · ${context.date(q.createdAt)}'),
                    trailing: Text(q.total.displayCompact, style: context.text.titleMedium),
                    onTap: () => context.push('/seller/leads/${q.requestId}'),
                    onLongPress: q.isActive ? () => _actions(context, ref, q) : null,
                  ),
                );
              },
            ),
    );
  }

  Future<void> _actions(BuildContext context, WidgetRef ref, Quote q) async {
    final l10n = context.l10n;
    final v = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.edit_outlined), title: Text(l10n.quoteRevise), onTap: () => Navigator.pop(ctx, 'revise')),
          ListTile(leading: const Icon(Icons.undo_rounded), title: Text(l10n.quoteWithdraw), onTap: () => Navigator.pop(ctx, 'withdraw')),
        ]),
      ),
    );
    if (!context.mounted) return;
    if (v == 'revise') context.push('/seller/leads/${q.requestId}/quote?revise=${q.id}');
    if (v == 'withdraw') await ref.read(quoteRepositoryProvider).withdrawQuote(q.id);
  }
}
