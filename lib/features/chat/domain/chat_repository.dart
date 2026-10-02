import 'chat.dart';

abstract interface class ChatRepository {
  Stream<List<Chat>> watchMyChats();
  Future<Chat?> getChat(String chatId);

  /// Returns the chat id for (request, seller), creating it if needed.
  Future<String> openChat({required String requestId, required String sellerId});
  Stream<List<ChatMessage>> watchMessages(String chatId);
  Future<List<ChatMessage>> olderMessages(String chatId, DateTime before);

  /// Optimistic: emits a sending message immediately; retried via the outbox.
  Future<void> sendText(String chatId, String text);
  Future<void> sendImage(String chatId, String localPath);
  Future<void> markRead(String chatId);
  Stream<bool> typing(String chatId);
  void setTyping(String chatId, bool typing);
}
