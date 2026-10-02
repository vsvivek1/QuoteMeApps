import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../../core/state/app_state.dart';
import '../../notifications/domain/app_notification.dart';
import '../domain/chat.dart';

part 'chat_providers.g.dart';

@riverpod
Stream<List<Chat>> myChats(Ref ref) {
  if (ref.watch(authSessionProvider).value == null) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchMyChats();
}

@riverpod
int unreadChatsCount(Ref ref) => (ref.watch(myChatsProvider).value ?? const []).fold(0, (a, c) => a + c.unread);

@riverpod
Stream<List<ChatMessage>> chatMessages(Ref ref, String chatId) =>
    ref.watch(chatRepositoryProvider).watchMessages(chatId);

@riverpod
Future<Chat?> chat(Ref ref, String chatId) {
  ref.watch(myChatsProvider);
  return ref.watch(chatRepositoryProvider).getChat(chatId);
}

@riverpod
Stream<List<AppNotification>> inbox(Ref ref) {
  if (ref.watch(authSessionProvider).value == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchInbox();
}

@riverpod
int unreadNotificationsCount(Ref ref) => (ref.watch(inboxProvider).value ?? const []).where((n) => !n.isRead).length;
