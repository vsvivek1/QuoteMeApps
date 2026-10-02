import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/audit/domain/audit_models.dart';
import '../features/auth/domain/admin_auth_repository.dart';
import '../features/brochures/domain/brochure_models.dart';
import '../features/categories/domain/category_models.dart';
import '../features/dashboard/domain/metrics.dart';
import '../features/flags/domain/settings_models.dart';
import '../features/moderation/domain/moderation_models.dart';
import '../features/outreach/domain/outreach_repository.dart';
import '../features/sellers/domain/seller_models.dart';
import '../features/verification/domain/verification_models.dart';
import 'config/admin_country.dart';
import 'config/admin_env.dart';
import 'data/admin_backend.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AdminEnv adminEnv(Ref ref) => AdminEnv.fromEnvironment();

/// Injected in main.dart from the COUNTRY define.
@Riverpod(keepAlive: true)
AdminCountryConfig countryConfig(Ref ref) => AdminCountryConfig.forCode(ref.watch(adminEnvProvider).country);

/// Supabase, or the in-memory demo backend when SUPABASE_URL is empty.
@Riverpod(keepAlive: true)
AdminBackend adminBackend(Ref ref) {
  final env = ref.watch(adminEnvProvider);
  final config = ref.watch(countryConfigProvider);
  final b = env.isDemo ? AdminBackend.demo(config) : AdminBackend.supabase(config);
  ref.onDispose(b.dispose);
  return b;
}

@Riverpod(keepAlive: true)
AdminAuthRepository adminAuthRepository(Ref ref) => ref.watch(adminBackendProvider).auth;

@Riverpod(keepAlive: true)
MetricsRepository metricsRepository(Ref ref) => ref.watch(adminBackendProvider).metrics;

@Riverpod(keepAlive: true)
VerificationRepository verificationRepository(Ref ref) => ref.watch(adminBackendProvider).verification;

@Riverpod(keepAlive: true)
ModerationRepository moderationRepository(Ref ref) => ref.watch(adminBackendProvider).moderation;

@Riverpod(keepAlive: true)
AuditRepository auditRepository(Ref ref) => ref.watch(adminBackendProvider).audit;

@Riverpod(keepAlive: true)
CategoryAdminRepository categoryAdminRepository(Ref ref) => ref.watch(adminBackendProvider).categories;

@Riverpod(keepAlive: true)
SettingsRepository settingsRepository(Ref ref) => ref.watch(adminBackendProvider).settings;

@Riverpod(keepAlive: true)
OutreachRepository outreachRepository(Ref ref) => ref.watch(adminBackendProvider).outreach;

@Riverpod(keepAlive: true)
BrochureRepository brochureRepository(Ref ref) => ref.watch(adminBackendProvider).brochures;

@Riverpod(keepAlive: true)
SellerRepository sellerRepository(Ref ref) => ref.watch(adminBackendProvider).sellers;

@Riverpod(keepAlive: true)
Stream<AdminSession?> adminSession(Ref ref) => ref.watch(adminAuthRepositoryProvider).sessionChanges();
