import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../domain/order.dart';

final _ordersProvider = StreamProvider.autoDispose<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).watchMyOrders(),
);
final _orderProvider = StreamProvider.autoDispose.family<Order?, String>(
  (ref, id) => ref.watch(orderRepositoryProvider).watchOrder(id),
);

String orderStatusLabel(BuildContext context, OrderStatus s) {
  final l10n = context.l10n;
  return switch (s) {
    OrderStatus.accepted => l10n.orderStatusAccepted,
    OrderStatus.scheduled => l10n.orderStatusScheduled,
    OrderStatus.dispatched => l10n.orderStatusDispatched,
    OrderStatus.delivered => l10n.orderStatusDelivered,
    OrderStatus.completed => l10n.orderStatusCompleted,
    OrderStatus.cancelled => l10n.orderStatusCancelled,
  };
}

String paymentMethodLabel(BuildContext context, String key) {
  final l10n = context.l10n;
  return switch (key) {
    'upi' => l10n.paymentMethodUpi,
    'cash' => l10n.paymentMethodCash,
    'card' => l10n.paymentMethodCard,
    'bank_transfer' => l10n.paymentMethodBankTransfer,
    'seller_link' => l10n.paymentMethodSellerLink,
    'zelle' => l10n.paymentMethodZelle,
    'check' => l10n.paymentMethodCheck,
    _ => key,
  };
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ordersTitle)),
      body: AsyncView(
        value: ref.watch(_ordersProvider),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.local_shipping_outlined, message: l10n.requestsEmptyAwarded)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final o = list[i];
                  return Card(
                    child: ListTile(
                      title: Text(o.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${o.sellerName} · ${orderStatusLabel(context, o.status)}'),
                      trailing: Text(o.total.displayCompact),
                      onTap: () => context.push('/orders/${o.id}'),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Order card with status timeline. Contact details are unlocked here (only
/// after acceptance). Payment happens off-platform and is recorded.
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  static const _flow = [OrderStatus.accepted, OrderStatus.scheduled, OrderStatus.dispatched, OrderStatus.delivered, OrderStatus.completed];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(authSessionProvider).value?.userId;
    final config = ref.watch(countryConfigProvider);
    return AsyncView(
      value: ref.watch(_orderProvider(orderId)),
      loading: const Scaffold(body: SkeletonList()),
      data: (o) {
        if (o == null) return Scaffold(appBar: AppBar(), body: const ErrorView());
        final isBuyer = o.buyerId == me;
        final reached = {for (final e in o.events) e.status: e};
        final idx = _flow.indexOf(o.status);
        final next = idx >= 0 && idx < _flow.length - 1 ? _flow[idx + 1] : null;
        final phone = isBuyer ? o.sellerPhone : o.buyerPhone;
        final reviewed = isBuyer ? o.buyerReviewed : o.sellerReviewed;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.orderTitle)),
          body: MaxWidth(
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Text(o.title, style: context.text.titleLarge),
              Text('${isBuyer ? o.sellerName : (o.buyerName ?? '')} · ${o.total.display}'),
              const SizedBox(height: 16),
              Text(l10n.orderTimeline, style: context.text.titleMedium),
              for (final s in _flow)
                ListTile(
                  dense: true,
                  leading: Icon(
                    reached.containsKey(s) ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: reached.containsKey(s) ? Colors.green.shade600 : context.colors.outline,
                  ),
                  title: Text(orderStatusLabel(context, s)),
                  subtitle: reached[s] == null ? null : Text(context.dateTime(reached[s]!.at)),
                ),
              if (next != null && o.status != OrderStatus.cancelled)
                OutlinedButton(
                  onPressed: () => ref.read(orderRepositoryProvider).updateStatus(o.id, next),
                  child: Text(l10n.orderMarkAs(orderStatusLabel(context, next))),
                ),
              const Divider(height: 32),
              Text(l10n.orderContact, style: context.text.titleMedium),
              if (phone != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(phone),
                  trailing: IconButton.filledTonal(
                    tooltip: l10n.call,
                    onPressed: () => launchUrl(Uri(scheme: 'tel', path: phone)),
                    icon: const Icon(Icons.call_rounded),
                  ),
                ),
              if (o.fullAddress != null)
                ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.place_outlined), title: Text(o.fullAddress!)),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chat_bubble_outline_rounded),
                title: Text(l10n.chat),
                onTap: () async {
                  final id = await ref.read(chatRepositoryProvider).openChat(requestId: o.requestId, sellerId: o.sellerId);
                  if (context.mounted) context.push('/chats/$id');
                },
              ),
              const Divider(height: 32),
              Text(l10n.orderPayment, style: context.text.titleMedium),
              if (o.paymentRecordedAt != null)
                Text(l10n.orderPaymentRecorded(o.paymentAmount!.display, paymentMethodLabel(context, o.paymentMethod!)))
              else ...[
                Text(l10n.orderPaymentOffPlatform, style: context.text.bodySmall),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final m in config.offPlatformPaymentMethods)
                    ActionChip(
                      label: Text(paymentMethodLabel(context, m)),
                      onPressed: () => ref.read(orderRepositoryProvider).recordPayment(o.id, m, o.total),
                    ),
                ]),
              ],
              if (o.isCompleted && !reviewed) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.push('/orders/${o.id}/review'),
                  icon: const Icon(Icons.star_outline_rounded),
                  label: Text(isBuyer ? l10n.rateSeller : l10n.rateBuyer),
                ),
              ],
            ]),
          ),
        );
      },
    );
  }
}

