// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brochure_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(brochureList)
final brochureListProvider = BrochureListProvider._();

final class BrochureListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BrochureRecord>>,
          List<BrochureRecord>,
          FutureOr<List<BrochureRecord>>
        >
    with
        $FutureModifier<List<BrochureRecord>>,
        $FutureProvider<List<BrochureRecord>> {
  BrochureListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brochureListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brochureListHash();

  @$internal
  @override
  $FutureProviderElement<List<BrochureRecord>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<BrochureRecord>> create(Ref ref) {
    return brochureList(ref);
  }
}

String _$brochureListHash() => r'd762c0ee8b0528e843608aaf9f8606a7650fbb78';
