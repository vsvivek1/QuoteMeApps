class ReportItem {
  const ReportItem({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.details,
    this.reporterId,
    this.targetPreview,
    this.targetOwnerId,
    this.reportCount = 1,
    required this.createdAt,
  });

  final String id;

  /// request | quote | message | review | seller | user | comment
  final String targetType;
  final String targetId;
  final String reason;
  final String? details;
  final String? reporterId;
  final String? targetPreview;

  /// The user who wrote the content (for "ban user").
  final String? targetOwnerId;
  final int reportCount;
  final DateTime createdAt;
}

class UserSummary {
  const UserSummary({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.roles = const [],
    required this.status,
    this.suspendedUntil,
    this.statusReason,
  });
  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final List<String> roles;

  /// active | suspended | banned | deleted
  final String status;
  final DateTime? suspendedUntil;
  final String? statusReason;
}

/// `dismiss` keeps content visible, `hide` hides it, `restore` unhides it.
enum ReportAction { dismiss, hide, restore }

abstract interface class ModerationRepository {
  Future<List<ReportItem>> openReports();
  Future<int> resolve(String reportId, ReportAction action, {String? note});
  Future<List<UserSummary>> searchUsers(String query);
  Future<UserSummary> setUserStatus(String userId, String status, {DateTime? until, String? reason});
}
