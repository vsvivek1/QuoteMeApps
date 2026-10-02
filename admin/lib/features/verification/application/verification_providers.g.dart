// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(verificationQueue)
final verificationQueueProvider = VerificationQueueProvider._();

final class VerificationQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<VerificationItem>>,
          List<VerificationItem>,
          FutureOr<List<VerificationItem>>
        >
    with
        $FutureModifier<List<VerificationItem>>,
        $FutureProvider<List<VerificationItem>> {
  VerificationQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationQueueHash();

  @$internal
  @override
  $FutureProviderElement<List<VerificationItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<VerificationItem>> create(Ref ref) {
    return verificationQueue(ref);
  }
}

String _$verificationQueueHash() => r'294a3f4642eda96df08beae173f3d57ce7e2f0f0';
