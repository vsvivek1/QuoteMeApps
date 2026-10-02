// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seo_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(seoRepository)
final seoRepositoryProvider = SeoRepositoryProvider._();

final class SeoRepositoryProvider
    extends $FunctionalProvider<SeoRepository, SeoRepository, SeoRepository>
    with $Provider<SeoRepository> {
  SeoRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seoRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seoRepositoryHash();

  @$internal
  @override
  $ProviderElement<SeoRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SeoRepository create(Ref ref) {
    return seoRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SeoRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SeoRepository>(value),
    );
  }
}

String _$seoRepositoryHash() => r'3ecde2fe18b9e6352c3e4f9c17d7462a2fb5358b';

@ProviderFor(seoPages)
final seoPagesProvider = SeoPagesProvider._();

final class SeoPagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeoPageRow>>,
          List<SeoPageRow>,
          FutureOr<List<SeoPageRow>>
        >
    with $FutureModifier<List<SeoPageRow>>, $FutureProvider<List<SeoPageRow>> {
  SeoPagesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seoPagesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seoPagesHash();

  @$internal
  @override
  $FutureProviderElement<List<SeoPageRow>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeoPageRow>> create(Ref ref) {
    return seoPages(ref);
  }
}

String _$seoPagesHash() => r'a4af14073144557d24f4ab7bb3526a27bca23a55';

@ProviderFor(seoExportRuns)
final seoExportRunsProvider = SeoExportRunsProvider._();

final class SeoExportRunsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeoExportRun>>,
          List<SeoExportRun>,
          FutureOr<List<SeoExportRun>>
        >
    with
        $FutureModifier<List<SeoExportRun>>,
        $FutureProvider<List<SeoExportRun>> {
  SeoExportRunsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seoExportRunsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seoExportRunsHash();

  @$internal
  @override
  $FutureProviderElement<List<SeoExportRun>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeoExportRun>> create(Ref ref) {
    return seoExportRuns(ref);
  }
}

String _$seoExportRunsHash() => r'eb91b6658839d50ed1603acf74934a295f3a42ad';

@ProviderFor(seoGuides)
final seoGuidesProvider = SeoGuidesProvider._();

final class SeoGuidesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SeoGuide>>,
          List<SeoGuide>,
          FutureOr<List<SeoGuide>>
        >
    with $FutureModifier<List<SeoGuide>>, $FutureProvider<List<SeoGuide>> {
  SeoGuidesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seoGuidesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seoGuidesHash();

  @$internal
  @override
  $FutureProviderElement<List<SeoGuide>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeoGuide>> create(Ref ref) {
    return seoGuides(ref);
  }
}

String _$seoGuidesHash() => r'e619d86b03a1995985e6d51f20cd59f0e0ff83eb';

/// Thresholds and the weekly AI-guide cap from app_settings.

@ProviderFor(seoSettings)
final seoSettingsProvider = SeoSettingsProvider._();

/// Thresholds and the weekly AI-guide cap from app_settings.

final class SeoSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<({int aiGuideCap, SeoThresholds thresholds})>,
          ({int aiGuideCap, SeoThresholds thresholds}),
          FutureOr<({int aiGuideCap, SeoThresholds thresholds})>
        >
    with
        $FutureModifier<({int aiGuideCap, SeoThresholds thresholds})>,
        $FutureProvider<({int aiGuideCap, SeoThresholds thresholds})> {
  /// Thresholds and the weekly AI-guide cap from app_settings.
  SeoSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'seoSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$seoSettingsHash();

  @$internal
  @override
  $FutureProviderElement<({int aiGuideCap, SeoThresholds thresholds})>
  $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<({int aiGuideCap, SeoThresholds thresholds})> create(Ref ref) {
    return seoSettings(ref);
  }
}

String _$seoSettingsHash() => r'a23b74fffa97d7a3179784661273532eb94c1f81';
