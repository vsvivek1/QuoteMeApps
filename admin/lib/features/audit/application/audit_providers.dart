import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/audit_models.dart';

part 'audit_providers.g.dart';

@riverpod
Future<List<AuditEntry>> auditLog(Ref ref) => ref.watch(auditRepositoryProvider).recent();
