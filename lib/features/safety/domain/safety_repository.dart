abstract interface class SafetyRepository {
  /// target_type: user | seller | request | quote | message | review
  Future<void> report(String targetType, String targetId, String reason, {String? details});
  Future<void> block(String userId);
  Future<void> unblock(String userId);
  Future<Set<String>> blockedUserIds();
}
