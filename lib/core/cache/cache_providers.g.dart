// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The flavor's offline cache file (`iwant_<country>_<env>`).

@ProviderFor(appCache)
final appCacheProvider = AppCacheProvider._();

/// The flavor's offline cache file (`iwant_<country>_<env>`).

final class AppCacheProvider extends $FunctionalProvider<AppCache, AppCache, AppCache> with $Provider<AppCache> {
  /// The flavor's offline cache file (`iwant_<country>_<env>`).
  AppCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appCacheHash();

  @$internal
  @override
  $ProviderElement<AppCache> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppCache create(Ref ref) {
    return appCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppCache value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppCache>(value));
  }
}

String _$appCacheHash() => r'71a48d9f0489201fe8dce7e6a1ba9b324920e913';

@ProviderFor(outbox)
final outboxProvider = OutboxProvider._();

final class OutboxProvider extends $FunctionalProvider<Outbox, Outbox, Outbox> with $Provider<Outbox> {
  OutboxProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboxProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboxHash();

  @$internal
  @override
  $ProviderElement<Outbox> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Outbox create(Ref ref) {
    return outbox(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Outbox value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Outbox>(value));
  }
}

String _$outboxHash() => r'e33ab3726e3c4fb3720094bfacc5ded683302f3f';
