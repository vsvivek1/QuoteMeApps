// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'billing_services.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(billingService)
final billingServiceProvider = BillingServiceProvider._();

final class BillingServiceProvider extends $FunctionalProvider<BillingService, BillingService, BillingService>
    with $Provider<BillingService> {
  BillingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'billingServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$billingServiceHash();

  @$internal
  @override
  $ProviderElement<BillingService> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  BillingService create(Ref ref) {
    return billingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BillingService value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<BillingService>(value));
  }
}

String _$billingServiceHash() => r'15cbb10835ba887e41d76ba2a5eecd65f8854061';
