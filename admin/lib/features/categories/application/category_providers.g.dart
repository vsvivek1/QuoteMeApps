// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminCategories)
final adminCategoriesProvider = AdminCategoriesProvider._();

final class AdminCategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminCategory>>,
          List<AdminCategory>,
          FutureOr<List<AdminCategory>>
        >
    with
        $FutureModifier<List<AdminCategory>>,
        $FutureProvider<List<AdminCategory>> {
  AdminCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminCategoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminCategoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminCategory>> create(Ref ref) {
    return adminCategories(ref);
  }
}

String _$adminCategoriesHash() => r'ea997b2a28a353bc2a537ba5bc268e990509c3ad';

/// id -> category, for labels in other screens.

@ProviderFor(categoryIndex)
final categoryIndexProvider = CategoryIndexProvider._();

/// id -> category, for labels in other screens.

final class CategoryIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, AdminCategory>>,
          Map<int, AdminCategory>,
          FutureOr<Map<int, AdminCategory>>
        >
    with
        $FutureModifier<Map<int, AdminCategory>>,
        $FutureProvider<Map<int, AdminCategory>> {
  /// id -> category, for labels in other screens.
  CategoryIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryIndexProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryIndexHash();

  @$internal
  @override
  $FutureProviderElement<Map<int, AdminCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, AdminCategory>> create(Ref ref) {
    return categoryIndex(ref);
  }
}

String _$categoryIndexHash() => r'5214efd7abbe550c962ff6d65b16bbf1376ecdfd';
