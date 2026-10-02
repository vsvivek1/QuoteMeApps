// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seller_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mySeller)
final mySellerProvider = MySellerProvider._();

final class MySellerProvider extends $FunctionalProvider<AsyncValue<Seller?>, Seller?, Stream<Seller?>>
    with $FutureModifier<Seller?>, $StreamProvider<Seller?> {
  MySellerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySellerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySellerHash();

  @$internal
  @override
  $StreamProviderElement<Seller?> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Seller?> create(Ref ref) {
    return mySeller(ref);
  }
}

String _$mySellerHash() => r'a55a671f9f611f2742652e6acf3191147f0722b9';

@ProviderFor(sellerStats)
final sellerStatsProvider = SellerStatsProvider._();

final class SellerStatsProvider extends $FunctionalProvider<AsyncValue<SellerStats>, SellerStats, FutureOr<SellerStats>>
    with $FutureModifier<SellerStats>, $FutureProvider<SellerStats> {
  SellerStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerStatsHash();

  @$internal
  @override
  $FutureProviderElement<SellerStats> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<SellerStats> create(Ref ref) {
    return sellerStats(ref);
  }
}

String _$sellerStatsHash() => r'205ed7349b554926fff520af7b7e9b921ecc31b7';

@ProviderFor(myQuotes)
final myQuotesProvider = MyQuotesFamily._();

final class MyQuotesProvider extends $FunctionalProvider<AsyncValue<List<Quote>>, List<Quote>, Stream<List<Quote>>>
    with $FutureModifier<List<Quote>>, $StreamProvider<List<Quote>> {
  MyQuotesProvider._({required MyQuotesFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'myQuotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myQuotesHash();

  @override
  String toString() {
    return r'myQuotesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Quote>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<List<Quote>> create(Ref ref) {
    final argument = this.argument as String;
    return myQuotes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MyQuotesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$myQuotesHash() => r'1d013e3d61e3246df9fcb099a2fcda1a38dae516';

final class MyQuotesFamily extends $Family with $FunctionalFamilyOverride<Stream<List<Quote>>, String> {
  MyQuotesFamily._()
    : super(
        retry: null,
        name: r'myQuotesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MyQuotesProvider call(String bucket) => MyQuotesProvider._(argument: bucket, from: this);

  @override
  String toString() => r'myQuotesProvider';
}

@ProviderFor(sellerById)
final sellerByIdProvider = SellerByIdFamily._();

final class SellerByIdProvider extends $FunctionalProvider<AsyncValue<Seller?>, Seller?, FutureOr<Seller?>>
    with $FutureModifier<Seller?>, $FutureProvider<Seller?> {
  SellerByIdProvider._({required SellerByIdFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'sellerByIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerByIdHash();

  @override
  String toString() {
    return r'sellerByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Seller?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Seller?> create(Ref ref) {
    final argument = this.argument as String;
    return sellerById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SellerByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sellerByIdHash() => r'd891b0405515e773a17e5ee52ea8b7ed387f3b8f';

final class SellerByIdFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Seller?>, String> {
  SellerByIdFamily._()
    : super(
        retry: null,
        name: r'sellerByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  SellerByIdProvider call(String id) => SellerByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'sellerByIdProvider';
}

@ProviderFor(lead)
final leadProvider = LeadFamily._();

final class LeadProvider extends $FunctionalProvider<AsyncValue<Lead?>, Lead?, FutureOr<Lead?>>
    with $FutureModifier<Lead?>, $FutureProvider<Lead?> {
  LeadProvider._({required LeadFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'leadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadHash();

  @override
  String toString() {
    return r'leadProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Lead?> $createElement($ProviderPointer pointer) => $FutureProviderElement(pointer);

  @override
  FutureOr<Lead?> create(Ref ref) {
    final argument = this.argument as String;
    return lead(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadHash() => r'd95a7c112213c2fba7f523a0431ac625f10573cc';

final class LeadFamily extends $Family with $FunctionalFamilyOverride<FutureOr<Lead?>, String> {
  LeadFamily._()
    : super(
        retry: null,
        name: r'leadProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LeadProvider call(String requestId) => LeadProvider._(argument: requestId, from: this);

  @override
  String toString() => r'leadProvider';
}

@ProviderFor(LeadFilterState)
final leadFilterStateProvider = LeadFilterStateProvider._();

final class LeadFilterStateProvider extends $NotifierProvider<LeadFilterState, LeadFilters> {
  LeadFilterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadFilterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadFilterStateHash();

  @$internal
  @override
  LeadFilterState create() => LeadFilterState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadFilters value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LeadFilters>(value));
  }
}

String _$leadFilterStateHash() => r'a001250cb6ba468d81c757d824ff3be505a34b6b';

abstract class _$LeadFilterState extends $Notifier<LeadFilters> {
  LeadFilters build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeadFilters, LeadFilters>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<LeadFilters, LeadFilters>, LeadFilters, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// First page of the lead feed; refreshes when the seller's realtime channel
/// signals new leads.

@ProviderFor(LeadFeed)
final leadFeedProvider = LeadFeedProvider._();

/// First page of the lead feed; refreshes when the seller's realtime channel
/// signals new leads.
final class LeadFeedProvider extends $AsyncNotifierProvider<LeadFeed, List<Lead>> {
  /// First page of the lead feed; refreshes when the seller's realtime channel
  /// signals new leads.
  LeadFeedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadFeedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadFeedHash();

  @$internal
  @override
  LeadFeed create() => LeadFeed();
}

String _$leadFeedHash() => r'f4c41f389610d9079f01093285c0c8f1d05bed1d';

/// First page of the lead feed; refreshes when the seller's realtime channel
/// signals new leads.

abstract class _$LeadFeed extends $AsyncNotifier<List<Lead>> {
  FutureOr<List<Lead>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Lead>>, List<Lead>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Lead>>, List<Lead>>,
              AsyncValue<List<Lead>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(quoteTemplates)
final quoteTemplatesProvider = QuoteTemplatesProvider._();

final class QuoteTemplatesProvider
    extends $FunctionalProvider<AsyncValue<List<QuoteTemplate>>, List<QuoteTemplate>, FutureOr<List<QuoteTemplate>>>
    with $FutureModifier<List<QuoteTemplate>>, $FutureProvider<List<QuoteTemplate>> {
  QuoteTemplatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quoteTemplatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quoteTemplatesHash();

  @$internal
  @override
  $FutureProviderElement<List<QuoteTemplate>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<QuoteTemplate>> create(Ref ref) {
    return quoteTemplates(ref);
  }
}

String _$quoteTemplatesHash() => r'28720600bcb6c458078dc65e81a03b0aa7e07a49';
