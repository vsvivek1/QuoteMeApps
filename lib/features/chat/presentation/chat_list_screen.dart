import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/routing/shell.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/chat_providers.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final chats = ref.watch(myChatsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.chatsTitle), actions: const [NotificationsBell()]),
      body: AsyncView(
        value: chats,
        onRetry: () => ref.invalidate(myChatsProvider),
        data: (list) => list.isEmpty
            ? EmptyState(icon: Icons.forum_outlined, message: l10n.chatsEmpty)
            : ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(c.counterpartName.isEmpty ? '?' : c.counterpartName.characters.first),
                    ),
                    title: Text(c.counterpartName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      c.lastMessage ?? l10n.chatAboutRequest(c.requestTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (c.lastMessageAt != null)
                          Text(timeago.format(c.lastMessageAt!, locale: context.lang), style: context.text.labelSmall),
                        if (c.unread > 0) Badge(label: Text('${c.unread}')),
                      ],
                    ),
                    onTap: () => context.push('/chats/${c.id}'),
                  );
                },
              ),
      ),
    );
  }
}
