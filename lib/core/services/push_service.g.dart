// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// FCM: asks for permission (Android 13+ / iOS), stores the token in
/// `device_tokens` through the notification repository, and opens the
/// deep link carried in a tapped push (`data.route`).

@ProviderFor(pushRegistration)
final pushRegistrationProvider = PushRegistrationProvider._();

/// FCM: asks for permission (Android 13+ / iOS), stores the token in
/// `device_tokens` through the notification repository, and opens the
/// deep link carried in a tapped push (`data.route`).

final class PushRegistrationProvider
    extends $FunctionalProvider<AsyncValue<void>, void, FutureOr<void>>
    with $FutureModifier<void>, $FutureProvider<void> {
  /// FCM: asks for permission (Android 13+ / iOS), stores the token in
  /// `device_tokens` through the notification repository, and opens the
  /// deep link carried in a tapped push (`data.route`).
  PushRegistrationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushRegistrationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushRegistrationHash();

  @$internal
  @override
  $FutureProviderElement<void> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<void> create(Ref ref) {
    return pushRegistration(ref);
  }
}

String _$pushRegistrationHash() => r'6bef503427969990d026dd74e056283063179695';
