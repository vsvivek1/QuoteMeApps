import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/services/device_services.dart';
import '../../../core/state/app_state.dart';
import '../../../core/utils/context_x.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/common.dart';
import '../../safety/presentation/report_sheet.dart';
import '../application/chat_providers.dart';
import '../domain/chat.dart';

/// 1:1 chat per (request, seller): text, photos, quote cards, read receipts.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});
  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    ref.read(chatRepositoryProvider).markRead(widget.chatId);
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send(Chat chat) async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (!chat.quoteAccepted && !_warned && ContactInfoDetector.containsContactInfo(text)) {
      // Warn once; don't block (Section 2.6).
      setState(() => _warned = true);
      context.toast(context.l10n.chatContactWarning);
      return;
    }
    _input.clear();
    await ref.read(chatRepositoryProvider).sendText(widget.chatId, text);
  }

  Future<void> _sendPhoto() async {
    final paths = await ref.read(mediaServiceProvider).pickImages(limit: 1);
    if (paths.isNotEmpty) await ref.read(chatRepositoryProvider).sendImage(widget.chatId, paths.first);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(authSessionProvider).value?.userId;
    final chat = ref.watch(chatProvider(widget.chatId)).value;
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    ref.listen(chatMessagesProvider(widget.chatId), (_, _) {
      ref.read(chatRepositoryProvider).markRead(widget.chatId);
    });
    final isBuyer = chat?.buyerId == me;
    final otherId = chat == null ? null : (isBuyer ? chat.sellerId : chat.buyerId);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(chat?.counterpartName ?? '', overflow: TextOverflow.ellipsis),
            if (chat != null)
              Text(
                l10n.chatAboutRequest(chat.requestTitle),
                style: context.text.labelSmall,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        actions: [
          if (chat != null)
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'request':
                    context.push(isBuyer ? '/requests/${chat.requestId}' : '/seller/leads/${chat.requestId}');
                  case 'profile':
                    context.push('/s/${chat.sellerId}');
                  case 'report':
                    await showReportSheet(context, ref, targetType: 'user', targetId: otherId!);
                  case 'block':
                    final blocked = await confirmBlock(context, ref, userId: otherId!, name: chat.counterpartName);
                    if (blocked && context.mounted) context.pop();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'request',
                  child: Text(chat.requestTitle, overflow: TextOverflow.ellipsis),
                ),
                if (isBuyer) PopupMenuItem(value: 'profile', child: Text(l10n.sellerProfileTitle)),
                PopupMenuItem(value: 'report', child: Text(l10n.report)),
                PopupMenuItem(value: 'block', child: Text(l10n.block)),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          if (chat != null && !chat.quoteAccepted)
            Material(
              color: context.colors.surfaceContainerHigh,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(l10n.chatContactWarning, style: context.text.bodySmall)),
                  ],
                ),
              ),
            ),
          Expanded(
            child: AsyncView(
              value: messages,
              data: (list) => ListView.builder(
                reverse: true,
                padding: const EdgeInsets.all(12),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final m = list[list.length - 1 - i];
                  return _Bubble(message: m, mine: m.senderId == me);
                },
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: l10n.chatPhoto,
                    onPressed: _sendPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: l10n.chatHint,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      onSubmitted: (_) => chat == null ? null : _send(chat),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    tooltip: l10n.send,
                    onPressed: chat == null ? null : () => _send(chat),
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine});
  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final m = message;
    final bg = mine ? context.colors.primary : context.colors.surfaceContainerHighest;
    final fg = mine ? context.colors.onPrimary : context.colors.onSurface;
    if (m.type == MessageType.system) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(m.body, style: context.text.labelMedium),
        ),
      );
    }
    Widget content;
    if (m.type == MessageType.image) {
      final src = m.attachmentUrl ?? m.attachmentPath ?? '';
      content = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: src.startsWith('http')
            ? CachedNetworkImage(imageUrl: src, width: 220, fit: BoxFit.cover)
            : (kIsWeb || !isLocalFile(src))
            ? const SizedBox(width: 220, height: 160, child: Icon(Icons.image))
            : Image.file(File(src), width: 220, fit: BoxFit.cover, cacheWidth: 440),
      );
    } else {
      content = Text(m.body, style: TextStyle(color: fg));
    }
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: m.type == MessageType.image
            ? const EdgeInsets.all(4)
            : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.time(m.createdAt),
                  style: context.text.labelSmall?.copyWith(color: fg.withValues(alpha: 0.7)),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    m.sendState == SendState.failed
                        ? Icons.error_outline
                        : m.sendState == SendState.sending
                        ? Icons.schedule
                        : m.readAt != null
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: fg.withValues(alpha: 0.8),
                    semanticLabel: m.readAt != null ? context.l10n.chatRead : null,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
