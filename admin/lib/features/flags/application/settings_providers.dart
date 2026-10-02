import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/settings_models.dart';

part 'settings_providers.g.dart';

@riverpod
Future<List<AppSetting>> appSettings(Ref ref) => ref.watch(settingsRepositoryProvider).list();
