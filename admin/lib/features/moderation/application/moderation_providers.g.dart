// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moderation_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(openReports)
final openReportsProvider = OpenReportsProvider._();

final class OpenReportsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ReportItem>>,
          List<ReportItem>,
          FutureOr<List<ReportItem>>
        >
    with $FutureModifier<List<ReportItem>>, $FutureProvider<List<ReportItem>> {
  OpenReportsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openReportsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openReportsHash();

  @$internal
  @override
  $FutureProviderElement<List<ReportItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ReportItem>> create(Ref ref) {
    return openReports(ref);
  }
}

String _$openReportsHash() => r'3b53b0075c22896449289ffb329fd353a9b07cb4';

@ProviderFor(userSearch)
final userSearchProvider = UserSearchFamily._();

final class UserSearchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<UserSummary>>,
          List<UserSummary>,
          FutureOr<List<UserSummary>>
        >
    with
        $FutureModifier<List<UserSummary>>,
        $FutureProvider<List<UserSummary>> {
  UserSearchProvider._({
    required UserSearchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userSearchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userSearchHash();

  @override
  String toString() {
    return r'userSearchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<UserSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<UserSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return userSearch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UserSearchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userSearchHash() => r'dfa8a1c48b58c0e37120814bc8488ecc53ec74ff';

final class UserSearchFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<UserSummary>>, String> {
  UserSearchFamily._()
    : super(
        retry: null,
        name: r'userSearchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  UserSearchProvider call(String query) =>
      UserSearchProvider._(argument: query, from: this);

  @override
  String toString() => r'userSearchProvider';
}
