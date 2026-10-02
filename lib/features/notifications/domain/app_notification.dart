import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';

@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String type,
    @Default({}) Map<String, Object?> payload,
    required DateTime createdAt,
    DateTime? readAt,
  }) = _AppNotification;

  const AppNotification._();

  bool get isRead => readAt != null;

  /// In-app route this notification opens (same as the push deep link).
  String? get route {
    final p = payload;
    if (p['route'] is String) return p['route'] as String;
    if (p['chat_id'] != null) return '/chats/${p['chat_id']}';
    if (p['order_id'] != null) return '/orders/${p['order_id']}';
    if (p['request_id'] != null) {
      return type.startsWith('lead') || type == 'new_request'
          ? '/seller/leads/${p['request_id']}'
          : '/requests/${p['request_id']}';
    }
    return null;
  }
}
