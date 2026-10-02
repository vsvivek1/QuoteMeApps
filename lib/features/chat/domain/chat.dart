import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat.freezed.dart';

enum MessageType { text, image, quoteCard, system }

@freezed
abstract class Chat with _$Chat {
  const factory Chat({
    required String id,
    required String requestId,
    required String buyerId,
    required String sellerId,
    required String requestTitle,
    required String counterpartName,
    String? counterpartPhotoUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    @Default(0) int unread,
    @Default(false) bool quoteAccepted,
  }) = _Chat;
}

enum SendState { sending, sent, failed }

@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String chatId,
    required String senderId,
    @Default(MessageType.text) MessageType type,
    @Default('') String body,
    String? attachmentPath,
    String? attachmentUrl,
    required DateTime createdAt,
    DateTime? readAt,
    @Default(SendState.sent) SendState sendState,
    String? clientId,
  }) = _ChatMessage;
}
