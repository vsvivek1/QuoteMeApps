import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../../flags/application/settings_providers.dart';
import '../domain/seo_models.dart';

part 'seo_providers.g.dart';

@Riverpod(keepAlive: true)
SeoRepository seoRepository(Ref ref) => ref.watch(adminBackendProvider).seo;

@riverpod
Future<List<SeoPageRow>> seoPages(Ref ref) => ref.watch(seoRepositoryProvider).pages();

@riverpod
Future<List<SeoExportRun>> seoExportRuns(Ref ref) => ref.watch(seoRepositoryProvider).runs();

@riverpod
Future<List<SeoGuide>> seoGuides(Ref ref) => ref.watch(seoRepositoryProvider).guides();

/// Thresholds and the weekly AI-guide cap from app_settings.
@riverpod
Future<({SeoThresholds thresholds, int aiGuideCap})> seoSettings(Ref ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  final byKey = {for (final s in settings) s.key: s.value};
  return (
    thresholds: SeoThresholds.fromJson(byKey[SeoThresholds.settingKey]),
    aiGuideCap: (byKey[SeoThresholds.guideCapKey] as num?)?.toInt() ?? 10,
  );
}
