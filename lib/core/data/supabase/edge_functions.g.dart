// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edge_functions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(edgeFunctions)
final edgeFunctionsProvider = EdgeFunctionsProvider._();

final class EdgeFunctionsProvider extends $FunctionalProvider<EdgeFunctions, EdgeFunctions, EdgeFunctions>
    with $Provider<EdgeFunctions> {
  EdgeFunctionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'edgeFunctionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$edgeFunctionsHash();

  @$internal
  @override
  $ProviderElement<EdgeFunctions> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  EdgeFunctions create(Ref ref) {
    return edgeFunctions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EdgeFunctions value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<EdgeFunctions>(value));
  }
}

String _$edgeFunctionsHash() => r'09f99b81048c95b32338397a111860115e2c68e6';
