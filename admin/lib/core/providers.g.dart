// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminEnv)
final adminEnvProvider = AdminEnvProvider._();

final class AdminEnvProvider
    extends $FunctionalProvider<AdminEnv, AdminEnv, AdminEnv>
    with $Provider<AdminEnv> {
  AdminEnvProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminEnvProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminEnvHash();

  @$internal
  @override
  $ProviderElement<AdminEnv> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminEnv create(Ref ref) {
    return adminEnv(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminEnv value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminEnv>(value),
    );
  }
}

String _$adminEnvHash() => r'f914e6d35d573b141d871453935d73614183e007';

/// Injected in main.dart from the COUNTRY define.

@ProviderFor(countryConfig)
final countryConfigProvider = CountryConfigProvider._();

/// Injected in main.dart from the COUNTRY define.

final class CountryConfigProvider
    extends
        $FunctionalProvider<
          AdminCountryConfig,
          AdminCountryConfig,
          AdminCountryConfig
        >
    with $Provider<AdminCountryConfig> {
  /// Injected in main.dart from the COUNTRY define.
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
  $ProviderElement<AdminCountryConfig> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminCountryConfig create(Ref ref) {
    return countryConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminCountryConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminCountryConfig>(value),
    );
  }
}

String _$countryConfigHash() => r'2e1d5004ed88ea13458839411443b2733e2e3a18';

/// Supabase, or the in-memory demo backend when SUPABASE_URL is empty.

@ProviderFor(adminBackend)
final adminBackendProvider = AdminBackendProvider._();

/// Supabase, or the in-memory demo backend when SUPABASE_URL is empty.

final class AdminBackendProvider
    extends $FunctionalProvider<AdminBackend, AdminBackend, AdminBackend>
    with $Provider<AdminBackend> {
  /// Supabase, or the in-memory demo backend when SUPABASE_URL is empty.
  AdminBackendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminBackendProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminBackendHash();

  @$internal
  @override
  $ProviderElement<AdminBackend> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminBackend create(Ref ref) {
    return adminBackend(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminBackend value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminBackend>(value),
    );
  }
}

String _$adminBackendHash() => r'7936d3d74dd84f39993c6a1629794caf53cb6423';

@ProviderFor(adminAuthRepository)
final adminAuthRepositoryProvider = AdminAuthRepositoryProvider._();

final class AdminAuthRepositoryProvider
    extends
        $FunctionalProvider<
          AdminAuthRepository,
          AdminAuthRepository,
          AdminAuthRepository
        >
    with $Provider<AdminAuthRepository> {
  AdminAuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminAuthRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminAuthRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminAuthRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminAuthRepository create(Ref ref) {
    return adminAuthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminAuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminAuthRepository>(value),
    );
  }
}

String _$adminAuthRepositoryHash() =>
    r'40f4d5ca5df25a00042e1d87a780d61a830f5918';

@ProviderFor(metricsRepository)
final metricsRepositoryProvider = MetricsRepositoryProvider._();

final class MetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  MetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return metricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$metricsRepositoryHash() => r'd08990ddad0a3e5e4cc75756e6c0fb3445d29c80';

@ProviderFor(verificationRepository)
final verificationRepositoryProvider = VerificationRepositoryProvider._();

final class VerificationRepositoryProvider
    extends
        $FunctionalProvider<
          VerificationRepository,
          VerificationRepository,
          VerificationRepository
        >
    with $Provider<VerificationRepository> {
  VerificationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'verificationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$verificationRepositoryHash();

  @$internal
  @override
  $ProviderElement<VerificationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VerificationRepository create(Ref ref) {
    return verificationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VerificationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VerificationRepository>(value),
    );
  }
}

String _$verificationRepositoryHash() =>
    r'cc9d4878f9d70ead9ae5f053379d1aea33fc00ed';

@ProviderFor(moderationRepository)
final moderationRepositoryProvider = ModerationRepositoryProvider._();

final class ModerationRepositoryProvider
    extends
        $FunctionalProvider<
          ModerationRepository,
          ModerationRepository,
          ModerationRepository
        >
    with $Provider<ModerationRepository> {
  ModerationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'moderationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$moderationRepositoryHash();

  @$internal
  @override
  $ProviderElement<ModerationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ModerationRepository create(Ref ref) {
    return moderationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ModerationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ModerationRepository>(value),
    );
  }
}

String _$moderationRepositoryHash() =>
    r'e3dec3f9a92931b5d2a18b04d789f0f5d83379f8';

@ProviderFor(auditRepository)
final auditRepositoryProvider = AuditRepositoryProvider._();

final class AuditRepositoryProvider
    extends
        $FunctionalProvider<AuditRepository, AuditRepository, AuditRepository>
    with $Provider<AuditRepository> {
  AuditRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuditRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditRepository create(Ref ref) {
    return auditRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditRepository>(value),
    );
  }
}

String _$auditRepositoryHash() => r'd86384e0c6f7b46f2c943d4d074568bc456de48f';

@ProviderFor(categoryAdminRepository)
final categoryAdminRepositoryProvider = CategoryAdminRepositoryProvider._();

final class CategoryAdminRepositoryProvider
    extends
        $FunctionalProvider<
          CategoryAdminRepository,
          CategoryAdminRepository,
          CategoryAdminRepository
        >
    with $Provider<CategoryAdminRepository> {
  CategoryAdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryAdminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryAdminRepositoryHash();

  @$internal
  @override
  $ProviderElement<CategoryAdminRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CategoryAdminRepository create(Ref ref) {
    return categoryAdminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CategoryAdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CategoryAdminRepository>(value),
    );
  }
}

String _$categoryAdminRepositoryHash() =>
    r'1063046f6852ae9de56e90bf0ddcc8ce81779668';

@ProviderFor(settingsRepository)
final settingsRepositoryProvider = SettingsRepositoryProvider._();

final class SettingsRepositoryProvider
    extends
        $FunctionalProvider<
          SettingsRepository,
          SettingsRepository,
          SettingsRepository
        >
    with $Provider<SettingsRepository> {
  SettingsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SettingsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SettingsRepository create(Ref ref) {
    return settingsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsRepository>(value),
    );
  }
}

String _$settingsRepositoryHash() =>
    r'4ee3554ec3acd40a7b17ab734140b654d0c920f1';

@ProviderFor(outreachRepository)
final outreachRepositoryProvider = OutreachRepositoryProvider._();

final class OutreachRepositoryProvider
    extends
        $FunctionalProvider<
          OutreachRepository,
          OutreachRepository,
          OutreachRepository
        >
    with $Provider<OutreachRepository> {
  OutreachRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outreachRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outreachRepositoryHash();

  @$internal
  @override
  $ProviderElement<OutreachRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OutreachRepository create(Ref ref) {
    return outreachRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OutreachRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OutreachRepository>(value),
    );
  }
}

String _$outreachRepositoryHash() =>
    r'e75b4e9d79fe9bd4068ae41c52355fc14503e13a';

@ProviderFor(brochureRepository)
final brochureRepositoryProvider = BrochureRepositoryProvider._();

final class BrochureRepositoryProvider
    extends
        $FunctionalProvider<
          BrochureRepository,
          BrochureRepository,
          BrochureRepository
        >
    with $Provider<BrochureRepository> {
  BrochureRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brochureRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brochureRepositoryHash();

  @$internal
  @override
  $ProviderElement<BrochureRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BrochureRepository create(Ref ref) {
    return brochureRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrochureRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrochureRepository>(value),
    );
  }
}

String _$brochureRepositoryHash() =>
    r'44c59dd915711faebcaa2bcea634bdb00c611bb2';

@ProviderFor(sellerRepository)
final sellerRepositoryProvider = SellerRepositoryProvider._();

final class SellerRepositoryProvider
    extends
        $FunctionalProvider<
          SellerRepository,
          SellerRepository,
          SellerRepository
        >
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
  $ProviderElement<SellerRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SellerRepository create(Ref ref) {
    return sellerRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SellerRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SellerRepository>(value),
    );
  }
}

String _$sellerRepositoryHash() => r'118137da3814b15dff0a46bbe8866ecb402050bb';

@ProviderFor(adminSession)
final adminSessionProvider = AdminSessionProvider._();

final class AdminSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdminSession?>,
          AdminSession?,
          Stream<AdminSession?>
        >
    with $FutureModifier<AdminSession?>, $StreamProvider<AdminSession?> {
  AdminSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminSessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminSessionHash();

  @$internal
  @override
  $StreamProviderElement<AdminSession?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<AdminSession?> create(Ref ref) {
    return adminSession(ref);
  }
}

String _$adminSessionHash() => r'00a86f4cbb0f1a889a6d15cd176399e4f3f2a24c';
