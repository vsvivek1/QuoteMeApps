import 'app_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchInbox();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  Future<void> registerDeviceToken(String token, String platform);
  Future<void> removeDeviceToken(String token);
}
