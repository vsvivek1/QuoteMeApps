import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/chat/application/chat_providers.dart';
import '../providers.dart';
import '../utils/context_x.dart';
import '../../shared/widgets/common.dart';

/// Bottom navigation (rail on wide screens) for buyer and seller modes.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.shell, required this.mode});

  final StatefulNavigationShell shell;
  final AppMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final unreadChats = ref.watch(unreadChatsCountProvider);
    Widget chatIcon(IconData i) => Badge(
          isLabelVisible: unreadChats > 0,
          label: Text('$unreadChats'),
          child: Icon(i),
        );
    final destinations = mode == AppMode.buyer
        ? [
            (const Icon(Icons.home_outlined), const Icon(Icons.home_rounded), l10n.tabHome),
            (const Icon(Icons.receipt_long_outlined), const Icon(Icons.receipt_long_rounded), l10n.tabRequests),
            (chatIcon(Icons.chat_bubble_outline_rounded), chatIcon(Icons.chat_bubble_rounded), l10n.tabChats),
            (const Icon(Icons.person_outline_rounded), const Icon(Icons.person_rounded), l10n.tabAccount),
          ]
        : [
            (const Icon(Icons.inbox_outlined), const Icon(Icons.inbox_rounded), l10n.tabLeads),
            (const Icon(Icons.request_quote_outlined), const Icon(Icons.request_quote_rounded), l10n.tabMyQuotes),
            (chatIcon(Icons.chat_bubble_outline_rounded), chatIcon(Icons.chat_bubble_rounded), l10n.tabChats),
            (const Icon(Icons.storefront_outlined), const Icon(Icons.storefront_rounded), l10n.tabAccount),
          ];
    final isDemo = ref.watch(backendProvider).isDemo;
    final wide = MediaQuery.sizeOf(context).width >= 840;
    void onTap(int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex);

    final body = Column(
      children: [
        if (isDemo) const SafeArea(bottom: false, child: DemoBanner()),
        Expanded(
          child: isDemo
              ? MediaQuery.removePadding(context: context, removeTop: true, child: shell)
              : shell,
        ),
      ],
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: onTap,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in destinations)
                  NavigationRailDestination(icon: d.$1, selectedIcon: d.$2, label: Text(d.$3)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: onTap,
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: d.$1, selectedIcon: d.$2, label: d.$3),
        ],
      ),
    );
  }
}

/// Bell icon with unread count, used in app bars.
class NotificationsBell extends ConsumerWidget {
  const NotificationsBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    return IconButton(
      tooltip: context.l10n.notificationsTitle,
      onPressed: () => context.push('/notifications'),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}
