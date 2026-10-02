// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SellerQuery)
final sellerQueryProvider = SellerQueryProvider._();

final class SellerQueryProvider extends $NotifierProvider<SellerQuery, String> {
  SellerQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerQueryHash();

  @$internal
  @override
  SellerQuery create() => SellerQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$sellerQueryHash() => r'a44ec67502ec13db4cd89b312cd8b100f8ad806e';

abstract class _$SellerQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(sellerSearch)
final sellerSearchProvider = SellerSearchProvider._();

final class SellerSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SellerSummary>>,
          List<SellerSummary>,
          FutureOr<List<SellerSummary>>
        >
    with
        $FutureModifier<List<SellerSummary>>,
        $FutureProvider<List<SellerSummary>> {
  SellerSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerSearchHash();

  @$internal
  @override
  $FutureProviderElement<List<SellerSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SellerSummary>> create(Ref ref) {
    return sellerSearch(ref);
  }
}

String _$sellerSearchHash() => r'e7a13323880b315453e3fa82b4234e1963f1685b';

@ProviderFor(sellerDetail)
final sellerDetailProvider = SellerDetailFamily._();

final class SellerDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<SellerSummary>,
          SellerSummary,
          FutureOr<SellerSummary>
        >
    with $FutureModifier<SellerSummary>, $FutureProvider<SellerSummary> {
  SellerDetailProvider._({
    required SellerDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sellerDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sellerDetailHash();

  @override
  String toString() {
    return r'sellerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SellerSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerSummary> create(Ref ref) {
    final argument = this.argument as String;
    return sellerDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sellerDetailHash() => r'35aedbfd5dff110a3684cdaff7cfc782c83ddcd0';

final class SellerDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SellerSummary>, String> {
  SellerDetailFamily._()
    : super(
        retry: null,
        name: r'sellerDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SellerDetailProvider call(String id) =>
      SellerDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'sellerDetailProvider';
}

@ProviderFor(sellerEntitlements)
final sellerEntitlementsProvider = SellerEntitlementsFamily._();

final class SellerEntitlementsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EntitlementRecord>>,
          List<EntitlementRecord>,
          FutureOr<List<EntitlementRecord>>
        >
    with
        $FutureModifier<List<EntitlementRecord>>,
        $FutureProvider<List<EntitlementRecord>> {
  SellerEntitlementsProvider._({
    required SellerEntitlementsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sellerEntitlementsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sellerEntitlementsHash();

  @override
  String toString() {
    return r'sellerEntitlementsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EntitlementRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EntitlementRecord>> create(Ref ref) {
    final argument = this.argument as String;
    return sellerEntitlements(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerEntitlementsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sellerEntitlementsHash() =>
    r'7b4341ad626969b7d4c4b2ee6bb2a2caf8e69200';

final class SellerEntitlementsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<EntitlementRecord>>, String> {
  SellerEntitlementsFamily._()
    : super(
        retry: null,
        name: r'sellerEntitlementsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SellerEntitlementsProvider call(String sellerId) =>
      SellerEntitlementsProvider._(argument: sellerId, from: this);

  @override
  String toString() => r'sellerEntitlementsProvider';
}
