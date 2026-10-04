import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/providers.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../../requests/application/request_providers.dart';
import '../../requests/presentation/widgets.dart';
import '../domain/community.dart';
import '../domain/community_repository.dart';

String communityFailureText(BuildContext context, Object e) {
  final l10n = context.l10n;
  final code = e is CommunityFailure ? e.code : '';
  return switch (code) {
    'blocked_content' => l10n.commentBlockedContent,
    'comment_too_long' => l10n.commentTooLong,
    'rate_limited' => l10n.communityRateLimited,
    'group_closed' => l10n.groupClosed,
    'group_has_members' => l10n.groupHasMembers,
    'invalid_qty' => l10n.groupInvalidQty,
    'invalid_tiers' => l10n.quoteTiersInvalid,
    'post_not_found' => l10n.feedPostGone,
    _ => l10n.somethingWentWrong,
  };
}

/// Runs a community action and toasts a readable error.
Future<T?> runCommunityAction<T>(BuildContext context, Future<T> Function() action) async {
  try {
    return await action();
  } catch (e) {
    if (context.mounted) context.toast(communityFailureText(context, e));
    return null;
  }
}

class AuthorAvatar extends StatelessWidget {
  const AuthorAvatar({super.key, required this.name, this.photoUrl, this.business = false, this.radius = 18});
  final String name;
  final String? photoUrl;
  final bool business;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: radius,
      backgroundColor: business ? context.colors.tertiaryContainer : context.colors.secondaryContainer,
      foregroundImage: photoUrl == null ? null : NetworkImage(photoUrl!),
      child: business
          ? Icon(Icons.storefront_rounded, size: radius, color: context.colors.onTertiaryContainer)
          : Text(initial, style: TextStyle(color: context.colors.onSecondaryContainer)),
    );
  }
}

/// "12 people · 48 fans" plus best price and the next step.
class GroupProgress extends StatelessWidget {
  const GroupProgress({super.key, required this.group, this.dense = false});
  final GroupBuy group;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final g = group;
    final unit = g.unit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.groups_rounded, size: 18, color: context.colors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.groupJoinedSummary(g.members, formatQty(g.totalQty), unit),
                style: context.text.labelLarge,
              ),
            ),
            if (g.currentUnitPrice != null)
              Text(
                l10n.groupPriceEach(g.currentUnitPrice!.display),
                style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: context.colors.primary),
              ),
          ],
        ),
        if (g.nextMinQty != null) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: g.progressToNext, minHeight: dense ? 6 : 8),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.groupNextTier(formatQty(g.qtyToNext ?? 0), unit, g.nextUnitPrice?.display ?? ''),
            style: context.text.bodySmall,
          ),
        ] else if (g.currentUnitPrice == null) ...[
          const SizedBox(height: 4),
          Text(l10n.groupNoOffers, style: context.text.bodySmall),
        ],
      ],
    );
  }
}

class FeedPostCard extends ConsumerWidget {
  const FeedPostCard({super.key, required this.post, this.onTap, this.onComment});
  final FeedPost post;
  final VoidCallback? onTap;
  final VoidCallback? onComment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final p = post;
    final cat = ref.watch(categoryMapProvider).value?[p.categoryId];
    final meta = [
      if (cat != null) cat.name(context.lang),
      if (p.place.isNotEmpty) p.place,
      timeago.format(p.publishedAt, locale: context.lang),
    ].join(' · ');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AuthorAvatar(name: p.authorName, photoUrl: p.authorPhotoUrl),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.isMine ? l10n.feedYou : p.authorName, style: context.text.titleSmall),
                        Text(meta, style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  if (p.isGroupBuy) ...[
                    StatusChip(l10n.groupBuyBadge, color: context.colors.primary),
                    const SizedBox(width: 8),
                  ] else if (!p.isOpen) ...[
                    StatusChip(requestStatusLabel(context, p.status), color: requestStatusColor(context, p.status)),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(p.title, style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ),
              if (p.description.isNotEmpty && p.description != p.title) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(p.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                ),
              ],
              if (p.budgetMin != null || p.budgetMax != null) ...[
                const SizedBox(height: 6),
                Text('${l10n.postBudget}: ${moneyRange(p.budgetMin, p.budgetMax)}', style: context.text.bodySmall),
              ],
              if (p.group != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GroupProgress(group: p.group!, dense: true),
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  LikeButton(post: p),
                  TextButton.icon(
                    onPressed: onComment ?? onTap,
                    icon: const Icon(Icons.mode_comment_outlined, size: 20),
                    label: Text('${p.commentCount}'),
                  ),
                  const Spacer(),
                  Text(l10n.feedQuotesCount(p.quoteCount), style: context.text.bodySmall),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LikeButton extends ConsumerWidget {
  const LikeButton({super.key, required this.post});
  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = post.likedByMe;
    return TextButton.icon(
      onPressed: () => runCommunityAction(context, () => ref.read(communityRepositoryProvider).toggleLike(post.id)),
      icon: Icon(liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined, size: 20),
      label: Text('${post.likeCount}', semanticsLabel: context.l10n.feedLikes(post.likeCount)),
      style: liked ? TextButton.styleFrom(foregroundColor: context.colors.primary) : null,
    );
  }
}
