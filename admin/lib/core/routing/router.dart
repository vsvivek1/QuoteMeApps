import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/brochures/presentation/brochure_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/flags/presentation/flags_screen.dart';
import '../../features/moderation/presentation/moderation_screen.dart';
import '../../features/outreach/presentation/import_screen.dart';
import '../../features/outreach/presentation/lead_detail_screen.dart';
import '../../features/outreach/presentation/outreach_screen.dart';
import '../../features/sellers/presentation/seller_detail_screen.dart';
import '../../features/sellers/presentation/sellers_screen.dart';
import '../../features/seo/presentation/seo_screen.dart';
import '../../features/trends/presentation/draft_detail_screen.dart';
import '../../features/trends/presentation/trends_screen.dart';
import '../../features/verification/presentation/verification_screen.dart';
import '../providers.dart';
import 'shell.dart';

part 'router.g.dart';

abstract final class Routes {
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const verification = '/verification';
  static const sellers = '/sellers';
  static String seller(String id) => '/sellers/$id';
  static const moderation = '/moderation';
  static const categories = '/categories';
  static const flags = '/flags';
  static const outreach = '/outreach';
  static const outreachImport = '/outreach/import';
  static String lead(String id) => '/outreach/lead/$id';
  static const brochures = '/brochures';
  static const seo = '/seo';
  static const trends = '/trends';
  static String trendDraft(String id) => '/trends/draft/$id';
}

/// Re-runs the redirect when the admin session changes.
class _SessionListenable extends ChangeNotifier {
  void ping() => notifyListeners();
}

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final refresh = _SessionListenable();
  ref.listen(adminSessionProvider, (_, _) => refresh.ping());
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.dashboard,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(adminSessionProvider);
      if (session.isLoading && !session.hasValue) return null;
      final signedIn = session.value != null;
      final atLogin = state.matchedLocation == Routes.login;
      if (!signedIn) return atLogin ? null : Routes.login;
      if (atLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/', redirect: (_, _) => Routes.dashboard),
          GoRoute(path: Routes.dashboard, builder: (_, _) => const DashboardScreen()),
          GoRoute(path: Routes.verification, builder: (_, _) => const VerificationScreen()),
          GoRoute(
            path: Routes.sellers,
            builder: (_, _) => const SellersScreen(),
            routes: [
              GoRoute(path: ':id', builder: (_, s) => SellerDetailScreen(sellerId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: Routes.moderation, builder: (_, _) => const ModerationScreen()),
          GoRoute(path: Routes.categories, builder: (_, _) => const CategoriesScreen()),
          GoRoute(path: Routes.flags, builder: (_, _) => const FlagsScreen()),
          GoRoute(
            path: Routes.outreach,
            builder: (_, _) => const OutreachScreen(),
            routes: [
              GoRoute(path: 'import', builder: (_, _) => const ImportScreen()),
              GoRoute(path: 'lead/:id', builder: (_, s) => LeadDetailScreen(leadId: s.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: Routes.brochures, builder: (_, _) => const BrochureScreen()),
          GoRoute(path: Routes.seo, builder: (_, _) => const SeoScreen()),
          GoRoute(
            path: Routes.trends,
            builder: (_, _) => const TrendsScreen(),
            routes: [
              GoRoute(path: 'draft/:id', builder: (_, s) => TrendDraftScreen(draftId: s.pathParameters['id']!)),
            ],
          ),
        ],
      ),
    ],
  );
}
