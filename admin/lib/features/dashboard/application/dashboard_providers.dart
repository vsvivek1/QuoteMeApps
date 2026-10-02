import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/metrics.dart';

part 'dashboard_providers.g.dart';

@riverpod
Future<DashboardMetrics> dashboardMetrics(Ref ref) => ref.watch(metricsRepositoryProvider).load();
