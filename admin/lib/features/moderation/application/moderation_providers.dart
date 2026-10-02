import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/moderation_models.dart';

part 'moderation_providers.g.dart';

@riverpod
Future<List<ReportItem>> openReports(Ref ref) => ref.watch(moderationRepositoryProvider).openReports();

@riverpod
Future<List<UserSummary>> userSearch(Ref ref, String query) =>
    ref.watch(moderationRepositoryProvider).searchUsers(query);
