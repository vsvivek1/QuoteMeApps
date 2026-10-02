/// One admin action (who, what, on what, when). Written server side by the
/// admin RPCs; the panel only reads it.
class AuditEntry {
  const AuditEntry({
    required this.id,
    required this.action,
    this.actorId,
    this.actorEmail,
    this.targetType,
    this.targetId,
    this.details = const {},
    required this.createdAt,
  });
  final String id;
  final String action;
  final String? actorId;
  final String? actorEmail;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic> details;
  final DateTime createdAt;
}

abstract interface class AuditRepository {
  Future<List<AuditEntry>> recent({int limit = 200, String? targetType});
}
