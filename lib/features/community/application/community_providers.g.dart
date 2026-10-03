// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(communityFeed)
final communityFeedProvider = CommunityFeedFamily._();

final class CommunityFeedProvider
    extends $FunctionalProvider<AsyncValue<List<FeedPost>>, List<FeedPost>, Stream<List<FeedPost>>>
    with $FutureModifier<List<FeedPost>>, $StreamProvider<List<FeedPost>> {
  CommunityFeedProvider._({required CommunityFeedFamily super.from, required FeedFilter super.argument})
    : super(
        retry: null,
        name: r'communityFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$communityFeedHash();

  @override
  String toString() {
    return r'communityFeedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<FeedPost>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<FeedPost>> create(Ref ref) {
    final argument = this.argument as FeedFilter;
    return communityFeed(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CommunityFeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$communityFeedHash() => r'6a5727fa22842e96d846054233d813c589cd9b7c';

final class CommunityFeedFamily extends $Family with $FunctionalFamilyOverride<Stream<List<FeedPost>>, FeedFilter> {
  CommunityFeedFamily._()
    : super(
        retry: null,
        name: r'communityFeedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CommunityFeedProvider call(FeedFilter filter) => CommunityFeedProvider._(argument: filter, from: this);

  @override
  String toString() => r'communityFeedProvider';
}

@ProviderFor(feedPost)
final feedPostProvider = FeedPostFamily._();

final class FeedPostProvider extends $FunctionalProvider<AsyncValue<FeedPost?>, FeedPost?, Stream<FeedPost?>>
    with $FutureModifier<FeedPost?>, $StreamProvider<FeedPost?> {
  FeedPostProvider._({required FeedPostFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'feedPostProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedPostHash();

  @override
  String toString() {
    return r'feedPostProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<FeedPost?> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<FeedPost?> create(Ref ref) {
    final argument = this.argument as String;
    return feedPost(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedPostProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedPostHash() => r'fd08251e53c71da208ae1e738d2fe0a01eb75e68';

final class FeedPostFamily extends $Family with $FunctionalFamilyOverride<Stream<FeedPost?>, String> {
  FeedPostFamily._()
    : super(
        retry: null,
        name: r'feedPostProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedPostProvider call(String requestId) => FeedPostProvider._(argument: requestId, from: this);

  @override
  String toString() => r'feedPostProvider';
}

@ProviderFor(feedComments)
final feedCommentsProvider = FeedCommentsFamily._();

final class FeedCommentsProvider
    extends $FunctionalProvider<AsyncValue<List<FeedComment>>, List<FeedComment>, Stream<List<FeedComment>>>
    with $FutureModifier<List<FeedComment>>, $StreamProvider<List<FeedComment>> {
  FeedCommentsProvider._({required FeedCommentsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'feedCommentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedCommentsHash();

  @override
  String toString() {
    return r'feedCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<FeedComment>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<FeedComment>> create(Ref ref) {
    final argument = this.argument as String;
    return feedComments(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedCommentsHash() => r'95339e29a6e65ccf7090a057b986b49fd01d5db4';

final class FeedCommentsFamily extends $Family with $FunctionalFamilyOverride<Stream<List<FeedComment>>, String> {
  FeedCommentsFamily._()
    : super(
        retry: null,
        name: r'feedCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FeedCommentsProvider call(String requestId) => FeedCommentsProvider._(argument: requestId, from: this);

  @override
  String toString() => r'feedCommentsProvider';
}

/// Group-buy summary for a request (null when it is not a group buy).

@ProviderFor(groupBuy)
final groupBuyProvider = GroupBuyFamily._();

/// Group-buy summary for a request (null when it is not a group buy).

final class GroupBuyProvider extends $FunctionalProvider<AsyncValue<GroupBuy?>, GroupBuy?, FutureOr<GroupBuy?>>
    with $FutureModifier<GroupBuy?>, $FutureProvider<GroupBuy?> {
  /// Group-buy summary for a request (null when it is not a group buy).
  GroupBuyProvider._({required GroupBuyFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'groupBuyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupBuyHash();

  @override
  String toString() {
    return r'groupBuyProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupBuy?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupBuy?> create(Ref ref) {
    final argument = this.argument as String;
    return groupBuy(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupBuyProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupBuyHash() => r'92ff0e1d8260ae2b0b9ba2039cfe0cb588d142a8';

/// Group-buy summary for a request (null when it is not a group buy).

final class GroupBuyFamily extends $Family with $FunctionalFamilyOverride<FutureOr<GroupBuy?>, String> {
  GroupBuyFamily._()
    : super(
        retry: null,
        name: r'groupBuyProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Group-buy summary for a request (null when it is not a group buy).

  GroupBuyProvider call(String requestId) => GroupBuyProvider._(argument: requestId, from: this);

  @override
  String toString() => r'groupBuyProvider';
}

@ProviderFor(groupMembers)
final groupMembersProvider = GroupMembersFamily._();

final class GroupMembersProvider
    extends $FunctionalProvider<AsyncValue<List<GroupMember>>, List<GroupMember>, FutureOr<List<GroupMember>>>
    with $FutureModifier<List<GroupMember>>, $FutureProvider<List<GroupMember>> {
  GroupMembersProvider._({required GroupMembersFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'groupMembersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupMembersHash();

  @override
  String toString() {
    return r'groupMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GroupMember>> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupMember>> create(Ref ref) {
    final argument = this.argument as String;
    return groupMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMembersHash() => r'5810eeae2145ee03008f7796406ee326058c4a70';

final class GroupMembersFamily extends $Family with $FunctionalFamilyOverride<FutureOr<List<GroupMember>>, String> {
  GroupMembersFamily._()
    : super(
        retry: null,
        name: r'groupMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GroupMembersProvider call(String requestId) => GroupMembersProvider._(argument: requestId, from: this);

  @override
  String toString() => r'groupMembersProvider';
}
