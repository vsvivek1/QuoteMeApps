// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(myChats)
final myChatsProvider = MyChatsProvider._();

final class MyChatsProvider extends $FunctionalProvider<AsyncValue<List<Chat>>, List<Chat>, Stream<List<Chat>>>
    with $FutureModifier<List<Chat>>, $StreamProvider<List<Chat>> {
  MyChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myChatsHash();

  @$internal
  @override
  $StreamProviderElement<List<Chat>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<Chat>> create(Ref ref) {
    return myChats(ref);
  }
}

String _$myChatsHash() => r'ec96fb6ef49ebfd6bb60a5ebbea76db16d0ad1e1';

@ProviderFor(unreadChatsCount)
final unreadChatsCountProvider = UnreadChatsCountProvider._();

final class UnreadChatsCountProvider extends $FunctionalProvider<int, int, int> with $Provider<int> {
  UnreadChatsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadChatsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadChatsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadChatsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<int>(value));
  }
}

String _$unreadChatsCountHash() => r'fcaf5e9e95562b8c57aa8a13d74694de3af0380d';

@ProviderFor(chatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

final class ChatMessagesProvider
    extends $FunctionalProvider<AsyncValue<List<ChatMessage>>, List<ChatMessage>, Stream<List<ChatMessage>>>
    with $FutureModifier<List<ChatMessage>>, $StreamProvider<List<ChatMessage>> {
  ChatMessagesProvider._({required ChatMessagesFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return chatMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'a17a7a708bfa2f7b76c3be9d382eaca09b43b11d';

final class ChatMessagesFamily extends $Family with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  ChatMessagesFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesProvider call(String chatId) => ChatMessagesProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

@ProviderFor(chat)
final chatProvider = ChatFamily._();

final class ChatProvider extends $FunctionalProvider<AsyncValue<Chat?>, Chat?, FutureOr<Chat?>>
    with $FutureModifier<Chat?>, $FutureProvider<Chat?> {
  ChatProvider._({required ChatFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'chatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatHash();

  @override
  String toString() {
    return r'chatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Chat?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Chat?> create(Ref ref) {
    final argument = this.argument as String;
    return chat(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatHash() => r'90ef2a50c8e42e440ec9d0add2b81964d4a172c9';

final class ChatFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Chat?>, String> {
  ChatFamily._()
    : super(
        retry: null,
        name: r'chatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatProvider call(String chatId) => ChatProvider._(argument: chatId, from: this);

  @override
  String toString() => r'chatProvider';
}

@ProviderFor(inbox)
final inboxProvider = InboxProvider._();

final class InboxProvider
    extends $FunctionalProvider<AsyncValue<List<AppNotification>>, List<AppNotification>, Stream<List<AppNotification>>>
    with $FutureModifier<List<AppNotification>>, $StreamProvider<List<AppNotification>> {
  InboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxHash();

  @$internal
  @override
  $StreamProviderElement<List<AppNotification>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<AppNotification>> create(Ref ref) {
    return inbox(ref);
  }
}

String _$inboxHash() => r'52656bf07a607a137bdbc669ad8a5c46ebb0a808';

@ProviderFor(unreadNotificationsCount)
final unreadNotificationsCountProvider = UnreadNotificationsCountProvider._();

final class UnreadNotificationsCountProvider extends $FunctionalProvider<int, int, int> with $Provider<int> {
  UnreadNotificationsCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationsCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationsCountHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return unreadNotificationsCount(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<int>(value));
  }
}

String _$unreadNotificationsCountHash() => r'0aba35642468b12b17e6266153d902f347e0365e';
