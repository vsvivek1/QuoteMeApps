// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trends_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(trendsRepository)
final trendsRepositoryProvider = TrendsRepositoryProvider._();

final class TrendsRepositoryProvider
    extends
        $FunctionalProvider<
          TrendsRepository,
          TrendsRepository,
          TrendsRepository
        >
    with $Provider<TrendsRepository> {
  TrendsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TrendsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TrendsRepository create(Ref ref) {
    return trendsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrendsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrendsRepository>(value),
    );
  }
}

String _$trendsRepositoryHash() => r'15aa36531795e0543bd671f1fb3124c33d41cd14';

/// Country filter shared by every Trends tab (null = both; the pipeline covers both).

@ProviderFor(TrendsCountryFilter)
final trendsCountryFilterProvider = TrendsCountryFilterProvider._();

/// Country filter shared by every Trends tab (null = both; the pipeline covers both).
final class TrendsCountryFilterProvider
    extends $NotifierProvider<TrendsCountryFilter, TrendsCountry?> {
  /// Country filter shared by every Trends tab (null = both; the pipeline covers both).
  TrendsCountryFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendsCountryFilterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendsCountryFilterHash();

  @$internal
  @override
  TrendsCountryFilter create() => TrendsCountryFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TrendsCountry? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TrendsCountry?>(value),
    );
  }
}

String _$trendsCountryFilterHash() =>
    r'1eaff01b39afdb01863be1cb61f036ef4b3e350d';

/// Country filter shared by every Trends tab (null = both; the pipeline covers both).

abstract class _$TrendsCountryFilter extends $Notifier<TrendsCountry?> {
  TrendsCountry? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<TrendsCountry?, TrendsCountry?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<TrendsCountry?, TrendsCountry?>,
              TrendsCountry?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(trendBoard)
final trendBoardProvider = TrendBoardFamily._();

final class TrendBoardProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendBoard>,
          TrendBoard,
          FutureOr<TrendBoard>
        >
    with $FutureModifier<TrendBoard>, $FutureProvider<TrendBoard> {
  TrendBoardProvider._({
    required TrendBoardFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'trendBoardProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendBoardHash();

  @override
  String toString() {
    return r'trendBoardProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrendBoard> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TrendBoard> create(Ref ref) {
    final argument = this.argument as int;
    return trendBoard(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendBoardProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendBoardHash() => r'2ba43f1f5c2d2e655acefbe8f83e3e052468fb0c';

final class TrendBoardFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrendBoard>, int> {
  TrendBoardFamily._()
    : super(
        retry: null,
        name: r'trendBoardProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendBoardProvider call(int hours) =>
      TrendBoardProvider._(argument: hours, from: this);

  @override
  String toString() => r'trendBoardProvider';
}

@ProviderFor(trendTopics)
final trendTopicsProvider = TrendTopicsFamily._();

final class TrendTopicsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrendTopic>>,
          List<TrendTopic>,
          FutureOr<List<TrendTopic>>
        >
    with $FutureModifier<List<TrendTopic>>, $FutureProvider<List<TrendTopic>> {
  TrendTopicsProvider._({
    required TrendTopicsFamily super.from,
    required TopicStatus? super.argument,
  }) : super(
         retry: null,
         name: r'trendTopicsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendTopicsHash();

  @override
  String toString() {
    return r'trendTopicsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TrendTopic>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrendTopic>> create(Ref ref) {
    final argument = this.argument as TopicStatus?;
    return trendTopics(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendTopicsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendTopicsHash() => r'ca23327e56c4f5dd7ddc1c068d7ef579272f3300';

final class TrendTopicsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TrendTopic>>, TopicStatus?> {
  TrendTopicsFamily._()
    : super(
        retry: null,
        name: r'trendTopicsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendTopicsProvider call(TopicStatus? status) =>
      TrendTopicsProvider._(argument: status, from: this);

  @override
  String toString() => r'trendTopicsProvider';
}

@ProviderFor(trendDrafts)
final trendDraftsProvider = TrendDraftsFamily._();

final class TrendDraftsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrendDraft>>,
          List<TrendDraft>,
          FutureOr<List<TrendDraft>>
        >
    with $FutureModifier<List<TrendDraft>>, $FutureProvider<List<TrendDraft>> {
  TrendDraftsProvider._({
    required TrendDraftsFamily super.from,
    required DraftStatus? super.argument,
  }) : super(
         retry: null,
         name: r'trendDraftsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendDraftsHash();

  @override
  String toString() {
    return r'trendDraftsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TrendDraft>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrendDraft>> create(Ref ref) {
    final argument = this.argument as DraftStatus?;
    return trendDrafts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendDraftsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendDraftsHash() => r'51008d2e59873bc62a47ca46a09f3cc177b4b6b9';

final class TrendDraftsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TrendDraft>>, DraftStatus?> {
  TrendDraftsFamily._()
    : super(
        retry: null,
        name: r'trendDraftsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendDraftsProvider call(DraftStatus? status) =>
      TrendDraftsProvider._(argument: status, from: this);

  @override
  String toString() => r'trendDraftsProvider';
}

@ProviderFor(trendDraftDetail)
final trendDraftDetailProvider = TrendDraftDetailFamily._();

final class TrendDraftDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendDraftDetail>,
          TrendDraftDetail,
          FutureOr<TrendDraftDetail>
        >
    with $FutureModifier<TrendDraftDetail>, $FutureProvider<TrendDraftDetail> {
  TrendDraftDetailProvider._({
    required TrendDraftDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'trendDraftDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trendDraftDetailHash();

  @override
  String toString() {
    return r'trendDraftDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrendDraftDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrendDraftDetail> create(Ref ref) {
    final argument = this.argument as String;
    return trendDraftDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrendDraftDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trendDraftDetailHash() => r'7b4c898332f33c76f72f2192fa5ab6fef0399ff3';

final class TrendDraftDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrendDraftDetail>, String> {
  TrendDraftDetailFamily._()
    : super(
        retry: null,
        name: r'trendDraftDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrendDraftDetailProvider call(String id) =>
      TrendDraftDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'trendDraftDetailProvider';
}

@ProviderFor(trendReviewQueue)
final trendReviewQueueProvider = TrendReviewQueueProvider._();

final class TrendReviewQueueProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrendDraft>>,
          List<TrendDraft>,
          FutureOr<List<TrendDraft>>
        >
    with $FutureModifier<List<TrendDraft>>, $FutureProvider<List<TrendDraft>> {
  TrendReviewQueueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendReviewQueueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendReviewQueueHash();

  @$internal
  @override
  $FutureProviderElement<List<TrendDraft>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrendDraft>> create(Ref ref) {
    return trendReviewQueue(ref);
  }
}

String _$trendReviewQueueHash() => r'd28a12bfe2ef19eb6e6dbd67fec20ba0f89f24e4';

@ProviderFor(trendSettings)
final trendSettingsProvider = TrendSettingsProvider._();

final class TrendSettingsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrendSettingsSnapshot>,
          TrendSettingsSnapshot,
          FutureOr<TrendSettingsSnapshot>
        >
    with
        $FutureModifier<TrendSettingsSnapshot>,
        $FutureProvider<TrendSettingsSnapshot> {
  TrendSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendSettingsHash();

  @$internal
  @override
  $FutureProviderElement<TrendSettingsSnapshot> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrendSettingsSnapshot> create(Ref ref) {
    return trendSettings(ref);
  }
}

String _$trendSettingsHash() => r'b02c87ca0521bc48f7f8c4e48840add5a4644424';

@ProviderFor(trendPublishLog)
final trendPublishLogProvider = TrendPublishLogProvider._();

final class TrendPublishLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrendLogEntry>>,
          List<TrendLogEntry>,
          FutureOr<List<TrendLogEntry>>
        >
    with
        $FutureModifier<List<TrendLogEntry>>,
        $FutureProvider<List<TrendLogEntry>> {
  TrendPublishLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trendPublishLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trendPublishLogHash();

  @$internal
  @override
  $FutureProviderElement<List<TrendLogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrendLogEntry>> create(Ref ref) {
    return trendPublishLog(ref);
  }
}

String _$trendPublishLogHash() => r'5d0a44c8f8b960096cc6b107e26dab84e218c8b5';
