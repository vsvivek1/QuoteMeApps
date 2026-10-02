// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mediaService)
final mediaServiceProvider = MediaServiceProvider._();

final class MediaServiceProvider extends $FunctionalProvider<MediaService, MediaService, MediaService>
    with $Provider<MediaService> {
  MediaServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaServiceHash();

  @$internal
  @override
  $ProviderElement<MediaService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  MediaService create(Ref ref) {
    return mediaService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<MediaService>(value));
  }
}

String _$mediaServiceHash() => r'224288451f95360ebac38964777f5dc5e9853007';

@ProviderFor(locationService)
final locationServiceProvider = LocationServiceProvider._();

final class LocationServiceProvider extends $FunctionalProvider<LocationService, LocationService, LocationService>
    with $Provider<LocationService> {
  LocationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationServiceHash();

  @$internal
  @override
  $ProviderElement<LocationService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  LocationService create(Ref ref) {
    return locationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LocationService>(value));
  }
}

String _$locationServiceHash() => r'38ada00c14c0c2521e7d291f9897c53df2e7008a';

@ProviderFor(speechService)
final speechServiceProvider = SpeechServiceProvider._();

final class SpeechServiceProvider extends $FunctionalProvider<SpeechService, SpeechService, SpeechService>
    with $Provider<SpeechService> {
  SpeechServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'speechServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$speechServiceHash();

  @$internal
  @override
  $ProviderElement<SpeechService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SpeechService create(Ref ref) {
    return speechService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SpeechService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SpeechService>(value));
  }
}

String _$speechServiceHash() => r'bc2de8082a32a79d015796217cc44dc2964d9c54';
