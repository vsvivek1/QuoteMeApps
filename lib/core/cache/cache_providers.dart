import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers.dart';
import 'app_cache.dart';
import 'outbox.dart';

part 'cache_providers.g.dart';

/// The flavor's offline cache file (`iwant_<country>_<env>`).
@Riverpod(keepAlive: true)
AppCache appCache(Ref ref) {
  final country = ref.watch(countryConfigProvider).country.name;
  final env = ref.watch(appEnvProvider).env.name;
  final cache = AppCache.forFlavor(country, env);
  ref.onDispose(cache.close);
  return cache;
}

@Riverpod(keepAlive: true)
Outbox outbox(Ref ref) {
  final o = Outbox(ref.watch(appCacheProvider))..start();
  ref.onDispose(o.dispose);
  return o;
}
