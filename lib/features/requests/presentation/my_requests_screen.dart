import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/shell.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/request_providers.dart';
import '../domain/buyer_request.dart';
import 'widgets.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final requests = ref.watch(myRequestsProvider);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.tabRequests),
          actions: [
            IconButton(
              tooltip: l10n.ordersTitle,
              onPressed: () => context.push('/orders'),
              icon: const Icon(Icons.local_shipping_outlined),
            ),
            const NotificationsBell(),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.requestsOpen),
              Tab(text: l10n.requestsAwarded),
              Tab(text: l10n.requestsPast),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.push('/post'),
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.postTitle),
        ),
        body: AsyncView(
          value: requests,
          onRetry: () => ref.invalidate(myRequestsProvider),
          data: (list) => TabBarView(
            children: [
              _list(context, ref, list.where((r) => r.isOpen).toList(), l10n.requestsEmptyOpen),
              _list(
                context,
                ref,
                list.where((r) => r.status == RequestStatus.awarded).toList(),
                l10n.requestsEmptyAwarded,
              ),
              _list(context, ref, list.where((r) => r.isPast).toList(), l10n.requestsEmptyPast),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<BuyerRequest> items, String empty) {
    if (items.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, message: empty);
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myRequestsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => MaxWidth(child: RequestCard(request: items[i])),
      ),
    );
  }
}
