import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../../core/state/app_state.dart';
import '../../safety/presentation/report_sheet.dart';
import '../application/community_providers.dart';
import '../domain/community.dart';
import 'community_widgets.dart';

/// One community post: the request, its group buy (join, price ladder,
/// members) and the comment thread.
class FeedPostScreen extends ConsumerStatefulWidget {
  const FeedPostScreen({super.key, required this.requestId, this.focusComment = false});
  final String requestId;
  final bool focusComment;

  @override
  ConsumerState<FeedPostScreen> createState() => _FeedPostScreenState();
}

class _FeedPostScreenState extends ConsumerState<FeedPostScreen> {
  final _comment = TextEditingController();
  final _focus = FocusNode();
  FeedComment? _replyTo;
  bool _asBusiness = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusComment) WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _comment.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final ok = await runCommunityAction(
      context,
      () => ref
          .read(communityRepositoryProvider)
          .addComment(widget.requestId, text, parentId: _replyTo?.id, asSeller: _asBusiness),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok != null) {
        _comment.clear();
        _replyTo = null;
      }
    });
  }

  Future<void> _commentMenu(FeedComment c, FeedPost post) async {
    final l10n = context.l10n;
    final canDelete = c.isMine || post.isMine;
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: Text(MaterialLocalizations.of(ctx).copyButtonLabel),
              onTap: () => Navigator.pop(ctx, 'copy'),
            ),
            if (canDelete)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l10n.delete),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            if (!c.isMine)
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.report),
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: c.body));
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(l10n.commentDeleteConfirm),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.delete)),
            ],
          ),
        );
        if (ok == true && mounted) {
          await runCommunityAction(context, () => ref.read(communityRepositoryProvider).deleteComment(c.id));
        }
      case 'report':
        await showReportSheet(context, ref, targetType: 'comment', targetId: c.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final post = ref.watch(feedPostProvider(widget.requestId));
    final comments = ref.watch(feedCommentsProvider(widget.requestId));
    final isSeller = ref.watch(myProfileProvider).value?.isSeller ?? false;

    return AsyncView(
      value: post,
      loading: const Scaffold(body: SkeletonList(count: 3)),
      onRetry: () => ref.invalidate(feedPostProvider(widget.requestId)),
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(),
            body: EmptyState(icon: Icons.visibility_off_outlined, message: l10n.feedPostGone),
          );
        }
        final all = comments.value ?? const <FeedComment>[];
        final top = all.where((c) => c.parentId == null).toList();
        List<FeedComment> repliesOf(String id) => all.where((c) => c.parentId == id).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.feedPostTitle),
            actions: [
              IconButton(
                tooltip: l10n.share,
                onPressed: () {
                  final link = ref.read(countryConfigProvider).requestLink(p.id).toString();
                  SharePlus.instance.share(ShareParams(text: '${p.title}\n$link'));
                },
                icon: const Icon(Icons.share_outlined),
              ),
              if (p.isMine)
                IconButton(
                  tooltip: l10n.feedOpenPost,
                  onPressed: () => context.push('/requests/${p.id}'),
                  icon: const Icon(Icons.receipt_long_outlined),
                )
              else
                IconButton(
                  tooltip: l10n.report,
                  onPressed: () => showReportSheet(context, ref, targetType: 'request', targetId: p.id),
                  icon: const Icon(Icons.flag_outlined),
                ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref
                ..invalidate(feedPostProvider(widget.requestId))
                ..invalidate(feedCommentsProvider(widget.requestId));
            },
            child: MaxWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  FeedPostCard(post: p, onComment: () => _focus.requestFocus()),
                  if (p.group != null) ...[const SizedBox(height: 12), _GroupPanel(post: p)],
                  const SizedBox(height: 16),
                  Text(l10n.commentsTitle, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  if (comments.isLoading && !comments.hasValue)
                    const SizedBox(height: 120, child: SkeletonList(count: 2))
                  else if (top.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l10n.commentsEmpty, textAlign: TextAlign.center, style: context.text.bodyMedium),
                    )
                  else
                    for (final c in top) ...[
                      _CommentTile(
                        comment: c,
                        onReply: p.isOpen || p.isMine ? () => _startReply(c) : null,
                        onMenu: () => _commentMenu(c, p),
                      ),
                      for (final r in repliesOf(c.id))
                        Padding(
                          padding: const EdgeInsets.only(left: 44),
                          child: _CommentTile(
                            comment: r,
                            onReply: () => _startReply(c),
                            onMenu: () => _commentMenu(r, p),
                          ),
                        ),
                    ],
                ],
              ),
            ),
          ),
          bottomNavigationBar: _Composer(
            controller: _comment,
            focusNode: _focus,
            replyTo: _replyTo,
            sending: _sending,
            showAsBusiness: isSeller,
            asBusiness: _asBusiness,
            onAsBusiness: (v) => setState(() => _asBusiness = v),
            onCancelReply: () => setState(() => _replyTo = null),
            onSend: _send,
          ),
        );
      },
    );
  }

  void _startReply(FeedComment c) {
    setState(() => _replyTo = c);
    _focus.requestFocus();
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onMenu, this.onReply});
  final FeedComment comment;
  final VoidCallback onMenu;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = comment;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: c.sellerId == null ? null : () => context.push('/s/${c.sellerId}'),
            child: AuthorAvatar(name: c.authorName, photoUrl: c.authorPhotoUrl, business: c.asSeller, radius: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onLongPress: onMenu,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              c.isMine ? l10n.feedYou : c.authorName,
                              style: context.text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (c.sellerVerified) const VerifiedBadge(compact: true),
                            if (c.isPostAuthor)
                              Text(
                                l10n.commentAuthor,
                                style: context.text.labelSmall?.copyWith(color: context.colors.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(c.body),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 8),
                      Text(timeago.format(c.createdAt, locale: context.lang), style: context.text.labelSmall),
                      if (onReply != null)
                        TextButton(
                          onPressed: onReply,
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          child: Text(l10n.commentReply),
                        ),
                      const Spacer(),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        onPressed: onMenu,
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ],
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

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.replyTo,
    required this.sending,
    required this.showAsBusiness,
    required this.asBusiness,
    required this.onAsBusiness,
    required this.onCancelReply,
    required this.onSend,
  });
  final TextEditingController controller;
  final FocusNode focusNode;
  final FeedComment? replyTo;
  final bool sending;
  final bool showAsBusiness;
  final bool asBusiness;
  final ValueChanged<bool> onAsBusiness;
  final VoidCallback onCancelReply;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      elevation: 3,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 6, 8, 6 + MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (replyTo != null)
                Row(
                  children: [
                    Expanded(child: Text(l10n.commentReplyingTo(replyTo!.authorName), style: context.text.labelMedium)),
                    IconButton(
                      tooltip: l10n.cancel,
                      visualDensity: VisualDensity.compact,
                      onPressed: onCancelReply,
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
                  ],
                ),
              if (showAsBusiness)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: asBusiness,
                  onChanged: onAsBusiness,
                  title: Text(l10n.commentAsBusiness),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(hintText: l10n.commentHint, counterText: '', isDense: true),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton.filled(
                    tooltip: l10n.commentSend,
                    onPressed: sending ? null : onSend,
                    icon: sending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Group-buy card: progress, the price ladder, join / change / leave, and
/// for the organiser the member list.
class _GroupPanel extends ConsumerWidget {
  const _GroupPanel({required this.post});
  final FeedPost post;

  Future<void> _join(BuildContext context, WidgetRef ref, GroupBuy g) async {
    final l10n = context.l10n;
    final qty = TextEditingController(text: g.myQty == null ? '1' : formatQty(g.myQty!));
    final note = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.groupJoinTitle(g.unit)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: qty,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,4}(\.\d{0,3})?'))],
                decoration: InputDecoration(labelText: l10n.groupQtyLabel, suffixText: g.unit),
                validator: (v) {
                  final n = num.tryParse((v ?? '').trim());
                  return n == null || n <= 0 || n > 1000 ? l10n.groupInvalidQty : null;
                },
              ),
              if (g.myQty == null) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: note,
                  maxLength: 280,
                  decoration: InputDecoration(labelText: l10n.groupNoteLabel),
                ),
              ],
              const SizedBox(height: 8),
              Text(l10n.groupJoinPrivacy, style: Theme.of(ctx).textTheme.bodySmall),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(g.myQty == null ? l10n.groupJoin : l10n.save),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final joined = await runCommunityAction(
      context,
      () => ref
          .read(communityRepositoryProvider)
          .joinGroupBuy(post.id, num.parse(qty.text.trim()), note: note.text.trim().isEmpty ? null : note.text.trim()),
    );
    if (joined != null && context.mounted && g.myQty == null) context.toast(l10n.groupJoinedToast);
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final left = await runCommunityAction(context, () => ref.read(communityRepositoryProvider).leaveGroupBuy(post.id));
    if (left != null && context.mounted) context.toast(context.l10n.groupLeftToast);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final g = post.group!;
    final open = post.isOpen && (post.quoteWindowEndsAt?.isAfter(DateTime.now()) ?? true);
    return Card(
      color: context.colors.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.groups_rounded, color: context.colors.primary),
                const SizedBox(width: 8),
                Text(l10n.groupBuyTitle, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(l10n.groupBuyExplainer, style: context.text.bodySmall),
            const SizedBox(height: 12),
            GroupProgress(group: g),
            if (g.ladder.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.groupLadderTitle, style: context.text.labelLarge),
              const SizedBox(height: 4),
              for (final (i, t) in g.ladder.indexed)
                _TierRow(
                  tier: t,
                  unit: g.unit,
                  current: t.minQty <= g.totalQty && (i == g.ladder.length - 1 || g.ladder[i + 1].minQty > g.totalQty),
                ),
            ],
            if (g.winner != null) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.celebration_outlined),
                title: Text(l10n.groupWinner(g.winner!.businessName)),
                subtitle: Text(
                  [
                    if (g.winner!.unitPrice != null) l10n.groupPriceEach(g.winner!.unitPrice!.display),
                    l10n.groupWinnerContact,
                  ].join(' · '),
                ),
                onTap: () => context.push('/s/${g.winner!.sellerId}'),
              ),
            ],
            const SizedBox(height: 12),
            if (g.joined)
              Text(
                l10n.groupYouJoined(formatQty(g.myQty!), g.unit),
                style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            if (!open && g.winner == null) Text(l10n.groupClosed, style: context.text.bodyMedium),
            if (open)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (!g.joined)
                    FilledButton.icon(
                      onPressed: () => _join(context, ref, g),
                      icon: const Icon(Icons.group_add_rounded),
                      label: Text(l10n.groupJoin),
                    )
                  else
                    OutlinedButton(onPressed: () => _join(context, ref, g), child: Text(l10n.groupChangeQty)),
                  if (g.joined && !post.isMine)
                    TextButton(onPressed: () => _leave(context, ref), child: Text(l10n.groupLeave)),
                ],
              ),
            if (post.isMine) _Members(requestId: post.id, unit: g.unit),
          ],
        ),
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow({required this.tier, required this.unit, required this.current});
  final PriceTier tier;
  final String unit;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = current ? context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w800) : context.text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            current ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: current ? context.colors.primary : context.colors.outline,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.groupTierFrom(formatQty(tier.minQty), unit), style: style)),
          if (current) ...[StatusChip(l10n.groupCurrentTier, color: context.colors.primary), const SizedBox(width: 8)],
          Text(l10n.groupPriceEach(tier.unitPrice.display), style: style),
        ],
      ),
    );
  }
}

class _Members extends ConsumerWidget {
  const _Members({required this.requestId, required this.unit});
  final String requestId;
  final String unit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final members = ref.watch(groupMembersProvider(requestId)).value ?? const <GroupMember>[];
    final me = ref.watch(authSessionProvider).value?.userId;
    if (members.isEmpty) return const SizedBox.shrink();
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('${l10n.groupMembersTitle} (${members.length})'),
      children: [
        for (final m in members)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: AuthorAvatar(name: m.name, radius: 14),
            title: Text(m.userId == me ? '${l10n.feedYou} · ${l10n.groupOrganiser}' : m.name),
            subtitle: m.note == null ? null : Text(m.note!),
            trailing: Text('${formatQty(m.qty)} $unit'),
          ),
      ],
    );
  }
}
