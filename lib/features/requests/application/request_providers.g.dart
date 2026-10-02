// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Category>>,
          List<Category>,
          FutureOr<List<Category>>
        >
    with $FutureModifier<List<Category>>, $FutureProvider<List<Category>> {
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Category>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'97b0f89516353800c913d75473fdfb7476ee2ea5';

@ProviderFor(categoryMap)
final categoryMapProvider = CategoryMapProvider._();

final class CategoryMapProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, Category>>,
          Map<int, Category>,
          FutureOr<Map<int, Category>>
        >
    with
        $FutureModifier<Map<int, Category>>,
        $FutureProvider<Map<int, Category>> {
  CategoryMapProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryMapHash();

  @$internal
  @override
  $FutureProviderElement<Map<int, Category>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, Category>> create(Ref ref) {
    return categoryMap(ref);
  }
}

String _$categoryMapHash() => r'0a18f779fd208b5be125f718d4511ae725ed0a05';

@ProviderFor(myRequests)
final myRequestsProvider = MyRequestsProvider._();

final class MyRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BuyerRequest>>,
          List<BuyerRequest>,
          Stream<List<BuyerRequest>>
        >
    with
        $FutureModifier<List<BuyerRequest>>,
        $StreamProvider<List<BuyerRequest>> {
  MyRequestsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myRequestsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myRequestsHash();

  @$internal
  @override
  $StreamProviderElement<List<BuyerRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BuyerRequest>> create(Ref ref) {
    return myRequests(ref);
  }
}

String _$myRequestsHash() => r'b30594c28787da73463b3a344d8767291f8f753d';

@ProviderFor(request)
final requestProvider = RequestFamily._();

final class RequestProvider
    extends
        $FunctionalProvider<
          AsyncValue<BuyerRequest?>,
          BuyerRequest?,
          Stream<BuyerRequest?>
        >
    with $FutureModifier<BuyerRequest?>, $StreamProvider<BuyerRequest?> {
  RequestProvider._({
    required RequestFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'requestProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$requestHash();

  @override
  String toString() {
    return r'requestProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<BuyerRequest?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BuyerRequest?> create(Ref ref) {
    final argument = this.argument as String;
    return request(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$requestHash() => r'5e2101e82d0ad12db9b07f595509b31862c5ea7c';

final class RequestFamily extends $Family
    with $FunctionalFamilyOverride<Stream<BuyerRequest?>, String> {
  RequestFamily._()
    : super(
        retry: null,
        name: r'requestProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RequestProvider call(String id) =>
      RequestProvider._(argument: id, from: this);

  @override
  String toString() => r'requestProvider';
}

@ProviderFor(requestQuotes)
final requestQuotesProvider = RequestQuotesFamily._();

final class RequestQuotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Quote>>,
          List<Quote>,
          Stream<List<Quote>>
        >
    with $FutureModifier<List<Quote>>, $StreamProvider<List<Quote>> {
  RequestQuotesProvider._({
    required RequestQuotesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'requestQuotesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$requestQuotesHash();

  @override
  String toString() {
    return r'requestQuotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Quote>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Quote>> create(Ref ref) {
    final argument = this.argument as String;
    return requestQuotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RequestQuotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$requestQuotesHash() => r'9b4610ac593e2d289694f39a7c2b757d98ef98ff';

final class RequestQuotesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Quote>>, String> {
  RequestQuotesFamily._()
    : super(
        retry: null,
        name: r'requestQuotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RequestQuotesProvider call(String requestId) =>
      RequestQuotesProvider._(argument: requestId, from: this);

  @override
  String toString() => r'requestQuotesProvider';
}
