import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/shell.dart';
import '../../../core/utils/context_x.dart';
import '../../../shared/widgets/common.dart';
import '../application/community_providers.dart';
import '../domain/community.dart';
import 'community_widgets.dart';

/// The public request feed: what people nearby need, with likes, comments
/// and group buys.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  FeedFilter _filter = FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final feed = ref.watch(communityFeedProvider(_filter));
    final filters = {
      FeedFilter.all: l10n.feedFilterAll,
      FeedFilter.groupBuys: l10n.feedFilterGroupBuys,
      FeedFilter.open: l10n.feedFilterOpen,
      FeedFilter.mine: l10n.feedFilterMine,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l10n.communityTitle), actions: const [NotificationsBell()]),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community-post',
        onPressed: () => context.push('/post'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.whatDoYouNeed),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(communityFeedProvider(_filter)),
        child: MaxWidth(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(l10n.communitySubtitle, style: context.text.bodyMedium),
                ),
              ),
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      for (final e in filters.entries)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(e.value),
                            selected: _filter == e.key,
                            onSelected: (_) => setState(() => _filter = e.key),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              ...feed.when(
                data: (posts) => posts.isEmpty
                    ? [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: EmptyState(icon: Icons.forum_outlined, message: l10n.feedEmpty),
                        ),
                      ]
                    : [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          sliver: SliverList.separated(
                            itemCount: posts.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => FeedPostCard(
                              post: posts[i],
                              onTap: () => context.push('/feed/${posts[i].id}'),
                              onComment: () => context.push('/feed/${posts[i].id}?comment=1'),
                            ),
                          ),
                        ),
                      ],
                loading: () => [const SliverFillRemaining(child: SkeletonList(count: 3))],
                error: (_, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(onRetry: () => ref.invalidate(communityFeedProvider(_filter))),
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
