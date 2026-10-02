// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outreach_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(LeadFilterController)
final leadFilterControllerProvider = LeadFilterControllerProvider._();

final class LeadFilterControllerProvider
    extends $NotifierProvider<LeadFilterController, LeadFilter> {
  LeadFilterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadFilterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadFilterControllerHash();

  @$internal
  @override
  LeadFilterController create() => LeadFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeadFilter>(value),
    );
  }
}

String _$leadFilterControllerHash() =>
    r'0a7d558d0c4eca63598cc107ecbe8731019146d0';

abstract class _$LeadFilterController extends $Notifier<LeadFilter> {
  LeadFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeadFilter, LeadFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeadFilter, LeadFilter>,
              LeadFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(outreachLeads)
final outreachLeadsProvider = OutreachLeadsProvider._();

final class OutreachLeadsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutreachLead>>,
          List<OutreachLead>,
          FutureOr<List<OutreachLead>>
        >
    with
        $FutureModifier<List<OutreachLead>>,
        $FutureProvider<List<OutreachLead>> {
  OutreachLeadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outreachLeadsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outreachLeadsHash();

  @$internal
  @override
  $FutureProviderElement<List<OutreachLead>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OutreachLead>> create(Ref ref) {
    return outreachLeads(ref);
  }
}

String _$outreachLeadsHash() => r'641494a72ee3372d78efe1d91507d7431260a36d';

@ProviderFor(leadDetail)
final leadDetailProvider = LeadDetailFamily._();

final class LeadDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<OutreachLead>,
          OutreachLead,
          FutureOr<OutreachLead>
        >
    with $FutureModifier<OutreachLead>, $FutureProvider<OutreachLead> {
  LeadDetailProvider._({
    required LeadDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadDetailHash();

  @override
  String toString() {
    return r'leadDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<OutreachLead> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<OutreachLead> create(Ref ref) {
    final argument = this.argument as String;
    return leadDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadDetailHash() => r'94964b7ce6a60e4cea7791b2fb2d83b2885bebe6';

final class LeadDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<OutreachLead>, String> {
  LeadDetailFamily._()
    : super(
        retry: null,
        name: r'leadDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LeadDetailProvider call(String id) =>
      LeadDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'leadDetailProvider';
}

@ProviderFor(leadEvents)
final leadEventsProvider = LeadEventsFamily._();

final class LeadEventsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutreachEvent>>,
          List<OutreachEvent>,
          FutureOr<List<OutreachEvent>>
        >
    with
        $FutureModifier<List<OutreachEvent>>,
        $FutureProvider<List<OutreachEvent>> {
  LeadEventsProvider._({
    required LeadEventsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'leadEventsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$leadEventsHash();

  @override
  String toString() {
    return r'leadEventsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<OutreachEvent>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OutreachEvent>> create(Ref ref) {
    final argument = this.argument as String;
    return leadEvents(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LeadEventsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$leadEventsHash() => r'fd88b41b49cf257513b96f8525ef3ea9163c81ad';

final class LeadEventsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<OutreachEvent>>, String> {
  LeadEventsFamily._()
    : super(
        retry: null,
        name: r'leadEventsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  LeadEventsProvider call(String id) =>
      LeadEventsProvider._(argument: id, from: this);

  @override
  String toString() => r'leadEventsProvider';
}

@ProviderFor(suppressionList)
final suppressionListProvider = SuppressionListProvider._();

final class SuppressionListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SuppressionEntry>>,
          List<SuppressionEntry>,
          FutureOr<List<SuppressionEntry>>
        >
    with
        $FutureModifier<List<SuppressionEntry>>,
        $FutureProvider<List<SuppressionEntry>> {
  SuppressionListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suppressionListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suppressionListHash();

  @$internal
  @override
  $FutureProviderElement<List<SuppressionEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SuppressionEntry>> create(Ref ref) {
    return suppressionList(ref);
  }
}

String _$suppressionListHash() => r'b016517aca9808e730f0251b10f2593443bfbee7';

@ProviderFor(campaigns)
final campaignsProvider = CampaignsProvider._();

final class CampaignsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutreachCampaign>>,
          List<OutreachCampaign>,
          FutureOr<List<OutreachCampaign>>
        >
    with
        $FutureModifier<List<OutreachCampaign>>,
        $FutureProvider<List<OutreachCampaign>> {
  CampaignsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'campaignsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$campaignsHash();

  @$internal
  @override
  $FutureProviderElement<List<OutreachCampaign>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OutreachCampaign>> create(Ref ref) {
    return campaigns(ref);
  }
}

String _$campaignsHash() => r'd4c183e70d4b66748de9a26f810a8b0c771ead34';

@ProviderFor(sequences)
final sequencesProvider = SequencesProvider._();

final class SequencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutreachSequence>>,
          List<OutreachSequence>,
          FutureOr<List<OutreachSequence>>
        >
    with
        $FutureModifier<List<OutreachSequence>>,
        $FutureProvider<List<OutreachSequence>> {
  SequencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sequencesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sequencesHash();

  @$internal
  @override
  $FutureProviderElement<List<OutreachSequence>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OutreachSequence>> create(Ref ref) {
    return sequences(ref);
  }
}

String _$sequencesHash() => r'100f2f174a185b82331ad414e11c8487e7be3a93';

@ProviderFor(inboxes)
final inboxesProvider = InboxesProvider._();

final class InboxesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<OutreachInbox>>,
          List<OutreachInbox>,
          FutureOr<List<OutreachInbox>>
        >
    with
        $FutureModifier<List<OutreachInbox>>,
        $FutureProvider<List<OutreachInbox>> {
  InboxesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxesHash();

  @$internal
  @override
  $FutureProviderElement<List<OutreachInbox>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<OutreachInbox>> create(Ref ref) {
    return inboxes(ref);
  }
}

String _$inboxesHash() => r'7a5d65cf075b22afc699a1d992ce38d86ab8f078';

@ProviderFor(sendStats)
final sendStatsProvider = SendStatsProvider._();

final class SendStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<SendStats>,
          SendStats,
          FutureOr<SendStats>
        >
    with $FutureModifier<SendStats>, $FutureProvider<SendStats> {
  SendStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sendStatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sendStatsHash();

  @$internal
  @override
  $FutureProviderElement<SendStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<SendStats> create(Ref ref) {
    return sendStats(ref);
  }
}

String _$sendStatsHash() => r'43e4abcb0f2c15e0791be011c4cf92b854e97fa1';

@ProviderFor(coverage)
final coverageProvider = CoverageProvider._();

final class CoverageProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CoverageCell>>,
          List<CoverageCell>,
          FutureOr<List<CoverageCell>>
        >
    with
        $FutureModifier<List<CoverageCell>>,
        $FutureProvider<List<CoverageCell>> {
  CoverageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coverageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coverageHash();

  @$internal
  @override
  $FutureProviderElement<List<CoverageCell>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CoverageCell>> create(Ref ref) {
    return coverage(ref);
  }
}

String _$coverageHash() => r'4358f68f7cd5b7775a5db8aa516b9192650741dd';
