import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../chat/application/chat_providers.dart';
import '../domain/app_notification.dart';

String notificationTitle(BuildContext context, AppNotification n) {
  final l10n = context.l10n;
  final p = n.payload;
  return switch (n.type) {
    'new_quote' => l10n.notifNewQuote('${p['seller'] ?? ''}'),
    'quote_revised' => l10n.notifQuoteRevised,
    'message' => l10n.notifMessage,
    'new_request' => l10n.notifNewRequest('${p['title'] ?? ''}'),
    'quote_accepted' => l10n.notifQuoteAccepted,
    'quote_declined' => l10n.notifQuoteDeclined,
    'quote_shortlisted' => l10n.notifQuoteShortlisted,
    'counter_offer' => l10n.notifCounterOffer,
    'order_status' => l10n.notifOrderStatus,
    _ => l10n.notifGeneric,
  };
}

IconData _icon(String type) => switch (type) {
  'new_quote' || 'quote_revised' => Icons.request_quote_outlined,
  'message' => Icons.chat_bubble_outline_rounded,
  'new_request' => Icons.inbox_outlined,
  'quote_accepted' => Icons.celebration_outlined,
  'order_status' => Icons.local_shipping_outlined,
  _ => Icons.notifications_none_rounded,
};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final inbox = ref.watch(inboxProvider);
    final repo = ref.watch(notificationRepositoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [TextButton(onPressed: repo.markAllRead, child: Text(l10n.markAllRead))],
      ),
      body: AsyncView(
        value: inbox,
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.notifications_none_rounded, message: l10n.notificationsEmpty)
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final n = list[i];
                  return ListTile(
                    tileColor: n.isRead ? null : context.colors.primaryContainer.withValues(alpha: 0.25),
                    leading: Icon(_icon(n.type)),
                    title: Text(
                      notificationTitle(context, n),
                      style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600),
                    ),
                    subtitle: Text(timeago.format(n.createdAt, locale: context.lang)),
                    onTap: () {
                      repo.markRead(n.id);
                      final route = n.route;
                      if (route != null) context.push(route);
                    },
                  );
                },
              ),
      ),
    );
  }
}
