import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../domain/community.dart';

part 'community_providers.g.dart';

@riverpod
Stream<List<FeedPost>> communityFeed(Ref ref, FeedFilter filter) {
  ref.watch(authSessionProvider); // liked_by_me / is_mine change with the user
  return ref.watch(communityRepositoryProvider).watchFeed(filter);
}

@riverpod
Stream<FeedPost?> feedPost(Ref ref, String requestId) {
  ref.watch(authSessionProvider);
  return ref.watch(communityRepositoryProvider).watchPost(requestId);
}

@riverpod
Stream<List<FeedComment>> feedComments(Ref ref, String requestId) {
  ref.watch(authSessionProvider);
  return ref.watch(communityRepositoryProvider).watchComments(requestId);
}

/// Group-buy summary for a request (null when it is not a group buy).
@riverpod
Future<GroupBuy?> groupBuy(Ref ref, String requestId) => ref.watch(communityRepositoryProvider).getGroupBuy(requestId);

@riverpod
Future<List<GroupMember>> groupMembers(Ref ref, String requestId) {
  ref.watch(feedPostProvider(requestId)); // refresh when the group changes
  return ref.watch(communityRepositoryProvider).groupMembers(requestId);
}
