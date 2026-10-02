import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/audit/domain/audit_models.dart';
import '../../features/auth/domain/admin_auth_repository.dart';
import '../../features/brochures/domain/brochure_models.dart';
import '../../features/categories/domain/category_models.dart';
import '../../features/dashboard/domain/metrics.dart';
import '../../features/flags/domain/settings_models.dart';
import '../../features/moderation/domain/moderation_models.dart';
import '../../features/outreach/domain/outreach_repository.dart';
import '../../features/sellers/domain/seller_models.dart';
import '../../features/seo/data/demo_seo_repository.dart';
import '../../features/seo/data/supabase_seo_repository.dart';
import '../../features/seo/domain/seo_models.dart';
import '../../features/verification/domain/verification_models.dart';
import '../config/admin_country.dart';
import '../demo/demo_repositories.dart';
import '../demo/demo_store.dart';
import 'supabase/supabase_repositories.dart';

/// All repositories for one backend. Screens only see the interfaces.
class AdminBackend {
  AdminBackend({
    required this.auth,
    required this.metrics,
    required this.verification,
    required this.moderation,
    required this.audit,
    required this.categories,
    required this.settings,
    required this.outreach,
    required this.brochures,
    required this.sellers,
    required this.seo,
    this.demo,
  });

  factory AdminBackend.demo(AdminCountryConfig config) {
    final s = DemoStore(config);
    return AdminBackend(
      auth: DemoAdminAuthRepository(s),
      metrics: DemoMetricsRepository(s),
      verification: DemoVerificationRepository(s),
      moderation: DemoModerationRepository(s),
      audit: DemoAuditRepository(s),
      categories: DemoCategoryRepository(s),
      settings: DemoSettingsRepository(s),
      outreach: DemoOutreachRepository(s),
      brochures: DemoBrochureRepository(s),
      sellers: DemoSellerRepository(s),
      seo: DemoSeoRepository(s),
      demo: s,
    );
  }

  /// Requires `Supabase.initialize` with the anon/publishable key first.
  factory AdminBackend.supabase(AdminCountryConfig config) {
    final c = Supabase.instance.client;
    return AdminBackend(
      auth: SupabaseAdminAuthRepository(c),
      metrics: SupabaseMetricsRepository(c),
      verification: SupabaseVerificationRepository(c),
      moderation: SupabaseModerationRepository(c),
      audit: SupabaseAuditRepository(c),
      categories: SupabaseCategoryRepository(c),
      settings: SupabaseSettingsRepository(c),
      outreach: SupabaseOutreachRepository(c),
      brochures: SupabaseBrochureRepository(c, config),
      sellers: SupabaseSellerRepository(c),
      seo: SupabaseSeoRepository(c),
    );
  }

  final AdminAuthRepository auth;
  final MetricsRepository metrics;
  final VerificationRepository verification;
  final ModerationRepository moderation;
  final AuditRepository audit;
  final CategoryAdminRepository categories;
  final SettingsRepository settings;
  final OutreachRepository outreach;
  final BrochureRepository brochures;
  final SellerRepository sellers;
  final SeoRepository seo;

  /// Non-null in demo mode.
  final DemoStore? demo;
  bool get isDemo => demo != null;

  void dispose() => demo?.dispose();
}
