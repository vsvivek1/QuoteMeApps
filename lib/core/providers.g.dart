// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Injected by the country entry point.

@ProviderFor(countryConfig)
final countryConfigProvider = CountryConfigProvider._();

/// Injected by the country entry point.

final class CountryConfigProvider extends $FunctionalProvider<CountryConfig, CountryConfig, CountryConfig>
    with $Provider<CountryConfig> {
  /// Injected by the country entry point.
  CountryConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'countryConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$countryConfigHash();

  @$internal
  @override
  $ProviderElement<CountryConfig> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CountryConfig create(Ref ref) {
    return countryConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CountryConfig value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CountryConfig>(value));
  }
}

String _$countryConfigHash() => r'ee43942c3858f1424a63c7d8548d124766d59ed5';

@ProviderFor(appEnv)
final appEnvProvider = AppEnvProvider._();

final class AppEnvProvider extends $FunctionalProvider<AppEnv, AppEnv, AppEnv> with $Provider<AppEnv> {
  AppEnvProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appEnvProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appEnvHash();

  @$internal
  @override
  $ProviderElement<AppEnv> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AppEnv create(Ref ref) {
    return appEnv(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppEnv value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AppEnv>(value));
  }
}

String _$appEnvHash() => r'6753f6cd7309820934abb47023866db6d36ae441';

/// The backend: Supabase, or the in-memory demo marketplace.

@ProviderFor(backend)
final backendProvider = BackendProvider._();

/// The backend: Supabase, or the in-memory demo marketplace.

final class BackendProvider extends $FunctionalProvider<Backend, Backend, Backend> with $Provider<Backend> {
  /// The backend: Supabase, or the in-memory demo marketplace.
  BackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backendHash();

  @$internal
  @override
  $ProviderElement<Backend> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Backend create(Ref ref) {
    return backend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Backend value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Backend>(value));
  }
}

String _$backendHash() => r'36abcd59991ddc38daad4dd9b54ac21f4116551d';

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<AuthRepository>(value));
  }
}

String _$authRepositoryHash() => r'eabe99bc1e6f52ecc8a5c99dfc7454c72ba1d93b';

@ProviderFor(profileRepository)
final profileRepositoryProvider = ProfileRepositoryProvider._();

final class ProfileRepositoryProvider
    extends $FunctionalProvider<ProfileRepository, ProfileRepository, ProfileRepository>
    with $Provider<ProfileRepository> {
  ProfileRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileRepositoryHash();

  @$internal
  @override
  $ProviderElement<ProfileRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ProfileRepository create(Ref ref) {
    return profileRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProfileRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ProfileRepository>(value));
  }
}

String _$profileRepositoryHash() => r'27ef8ba9506da26015bb774ed27fe00c9ec206d2';

@ProviderFor(categoryRepository)
final categoryRepositoryProvider = CategoryRepositoryProvider._();

final class CategoryRepositoryProvider
    extends $FunctionalProvider<CategoryRepository, CategoryRepository, CategoryRepository>
    with $Provider<CategoryRepository> {
  CategoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  CategoryRepository create(Ref ref) {
    return categoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<CategoryRepository>(value));
  }
}

String _$categoryRepositoryHash() => r'7896b1fe815de19ca54a3d262c37c622f5cb160a';

@ProviderFor(requestRepository)
final requestRepositoryProvider = RequestRepositoryProvider._();

final class RequestRepositoryProvider
    extends $FunctionalProvider<RequestRepository, RequestRepository, RequestRepository>
    with $Provider<RequestRepository> {
  RequestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestRepositoryHash();

  @$internal
  @override
  $ProviderElement<RequestRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  RequestRepository create(Ref ref) {
    return requestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<RequestRepository>(value));
  }
}

String _$requestRepositoryHash() => r'1262333b69f0a021061cb0290b2344c63651dc08';

@ProviderFor(quoteRepository)
final quoteRepositoryProvider = QuoteRepositoryProvider._();

final class QuoteRepositoryProvider extends $FunctionalProvider<QuoteRepository, QuoteRepository, QuoteRepository>
    with $Provider<QuoteRepository> {
  QuoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'quoteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$quoteRepositoryHash();

  @$internal
  @override
  $ProviderElement<QuoteRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  QuoteRepository create(Ref ref) {
    return quoteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(QuoteRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<QuoteRepository>(value));
  }
}

String _$quoteRepositoryHash() => r'1035f957c10bfc2def43f2dd4407fb8011771c61';

@ProviderFor(sellerRepository)
final sellerRepositoryProvider = SellerRepositoryProvider._();

final class SellerRepositoryProvider extends $FunctionalProvider<SellerRepository, SellerRepository, SellerRepository>
    with $Provider<SellerRepository> {
  SellerRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sellerRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sellerRepositoryHash();

  @$internal
  @override
  $ProviderElement<SellerRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SellerRepository create(Ref ref) {
    return sellerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SellerRepository>(value));
  }
}

String _$sellerRepositoryHash() => r'f301a9f95a3ee75f48199f6afd93fc69ff0b9b5f';

@ProviderFor(leadRepository)
final leadRepositoryProvider = LeadRepositoryProvider._();

final class LeadRepositoryProvider extends $FunctionalProvider<LeadRepository, LeadRepository, LeadRepository>
    with $Provider<LeadRepository> {
  LeadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leadRepositoryHash();

  @$internal
  @override
  $ProviderElement<LeadRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  LeadRepository create(Ref ref) {
    return leadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeadRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LeadRepository>(value));
  }
}

String _$leadRepositoryHash() => r'8d606082055dc8a3f9d55c148d0a8a0eaa008c1a';

@ProviderFor(chatRepository)
final chatRepositoryProvider = ChatRepositoryProvider._();

final class ChatRepositoryProvider extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  ChatRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    return chatRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ChatRepository>(value));
  }
}

String _$chatRepositoryHash() => r'ac65c59a65e392f023086623537579b3b083a8fc';

@ProviderFor(orderRepository)
final orderRepositoryProvider = OrderRepositoryProvider._();

final class OrderRepositoryProvider extends $FunctionalProvider<OrderRepository, OrderRepository, OrderRepository>
    with $Provider<OrderRepository> {
  OrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'orderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$orderRepositoryHash();

  @$internal
  @override
  $ProviderElement<OrderRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  OrderRepository create(Ref ref) {
    return orderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OrderRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<OrderRepository>(value));
  }
}

String _$orderRepositoryHash() => r'c3e3a010c1b1c8828df90a76901e82f363d01835';

@ProviderFor(reviewRepository)
final reviewRepositoryProvider = ReviewRepositoryProvider._();

final class ReviewRepositoryProvider extends $FunctionalProvider<ReviewRepository, ReviewRepository, ReviewRepository>
    with $Provider<ReviewRepository> {
  ReviewRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ReviewRepository create(Ref ref) {
    return reviewRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ReviewRepository>(value));
  }
}

String _$reviewRepositoryHash() => r'a1208276d655773e40d60bf8a7d8c9c80e2fedf5';

@ProviderFor(notificationRepository)
final notificationRepositoryProvider = NotificationRepositoryProvider._();

final class NotificationRepositoryProvider
    extends $FunctionalProvider<NotificationRepository, NotificationRepository, NotificationRepository>
    with $Provider<NotificationRepository> {
  NotificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<NotificationRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  NotificationRepository create(Ref ref) {
    return notificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<NotificationRepository>(value));
  }
}

String _$notificationRepositoryHash() => r'90f552d27241d733158d8980abba9e74d0eb531f';

@ProviderFor(safetyRepository)
final safetyRepositoryProvider = SafetyRepositoryProvider._();

final class SafetyRepositoryProvider extends $FunctionalProvider<SafetyRepository, SafetyRepository, SafetyRepository>
    with $Provider<SafetyRepository> {
  SafetyRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyRepositoryHash();

  @$internal
  @override
  $ProviderElement<SafetyRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  SafetyRepository create(Ref ref) {
    return safetyRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SafetyRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<SafetyRepository>(value));
  }
}

String _$safetyRepositoryHash() => r'46fb52d5cc1a753092ce09e3ade2dc2ccb936194';

@ProviderFor(flagsRepository)
final flagsRepositoryProvider = FlagsRepositoryProvider._();

final class FlagsRepositoryProvider extends $FunctionalProvider<FlagsRepository, FlagsRepository, FlagsRepository>
    with $Provider<FlagsRepository> {
  FlagsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'flagsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$flagsRepositoryHash();

  @$internal
  @override
  $ProviderElement<FlagsRepository> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  FlagsRepository create(Ref ref) {
    return flagsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FlagsRepository value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<FlagsRepository>(value));
  }
}

String _$flagsRepositoryHash() => r'ae054dc6cb6549b49289b13210dc609640a9fd62';
