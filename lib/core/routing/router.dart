import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/auth/presentation/account_blocked_screen.dart';
import '../../features/auth/presentation/consent_screen.dart';
import '../../features/auth/presentation/phone_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/community/presentation/community_screen.dart';
import '../../features/community/presentation/feed_post_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/presentation/language_screen.dart';
import '../../features/orders/presentation/order_screens.dart';
import '../../features/quotes/presentation/compare_screen.dart';
import '../../features/quotes/presentation/quote_detail_screen.dart';
import '../../features/requests/presentation/home_screen.dart';
import '../../features/requests/presentation/my_requests_screen.dart';
import '../../features/requests/presentation/post_request_screen.dart';
import '../../features/requests/presentation/request_detail_screen.dart';
import '../../features/reviews/presentation/review_screens.dart';
import '../../features/seller/presentation/dashboard_screen.dart';
import '../../features/seller/presentation/lead_detail_screen.dart';
import '../../features/seller/presentation/lead_feed_screen.dart';
import '../../features/seller/presentation/my_quotes_screen.dart';
import '../../features/seller/presentation/plan_screen.dart';
import '../../features/seller/presentation/quote_form_screen.dart';
import '../../features/seller/presentation/seller_onboarding_screen.dart';
import '../../features/seller/presentation/seller_profile_screen.dart';
import '../../features/seller/presentation/templates_screen.dart';
import '../../features/seller/presentation/verification_screen.dart';
import '../../features/settings/presentation/account_screen.dart';
import '../../features/settings/presentation/delete_account_screen.dart';
import '../../features/settings/presentation/help_screen.dart';
import '../../features/settings/presentation/legal_screens.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../state/app_state.dart';
import 'deep_link_screen.dart';
import 'shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

const _publicPrefixes = ['/language', '/welcome', '/auth/', '/legal', '/help', '/splash'];
const _onboardingPaths = [
  '/',
  '/splash',
  '/language',
  '/welcome',
  '/auth/phone',
  '/auth/otp',
  '/consent',
  '/profile-setup',
];

String homeFor(AppMode mode) => mode == AppMode.seller ? '/seller/leads' : '/home';

/// Re-runs the redirect when auth, profile, consent or locale change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authSessionProvider, (_, _) => notifyListeners());
    ref.listen(myProfileProvider, (_, _) => notifyListeners());
    ref.listen(consentAcceptedProvider, (_, _) => notifyListeners());
    ref.listen(localeControllerProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  String? redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final isPublic = _publicPrefixes.any(loc.startsWith);

    if (ref.read(localeControllerProvider) == null) {
      return loc == '/language' || loc.startsWith('/legal') ? null : '/language';
    }
    final session = ref.read(authSessionProvider);
    if (session.isLoading && !session.hasValue) return loc == '/splash' ? null : '/splash';
    if (session.value == null) {
      return isPublic && loc != '/splash' ? null : '/welcome';
    }
    final consent = ref.read(consentAcceptedProvider);
    if (!consent.hasValue) return loc == '/splash' ? null : '/splash';
    if (consent.value == false) {
      return loc == '/consent' || loc.startsWith('/legal') ? null : '/consent';
    }
    final profile = ref.read(myProfileProvider);
    if (!profile.hasValue || profile.value == null) return loc == '/splash' ? null : '/splash';
    if (profile.value!.isBlocked) {
      return loc == '/account-blocked' || loc.startsWith('/legal') || loc == '/help' ? null : '/account-blocked';
    }
    if (loc == '/account-blocked') return homeFor(profile.value!.activeMode);
    if (profile.value!.needsProfileSetup) return loc == '/profile-setup' ? null : '/profile-setup';
    if (_onboardingPaths.contains(loc)) return homeFor(profile.value!.activeMode);
    return null;
  }

  Page<void> fullscreen(Widget child, GoRouterState s) => MaterialPage(key: s.pageKey, child: child);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: redirect,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/language', builder: (_, _) => const LanguageScreen()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/auth/phone', builder: (_, _) => const PhoneScreen()),
      GoRoute(path: '/auth/link-phone', builder: (_, _) => const PhoneScreen(link: true)),
      GoRoute(
        path: '/auth/otp',
        builder: (_, s) {
          final extra = (s.extra as Map?) ?? const {};
          return OtpScreen(phone: extra['phone'] as String? ?? '', link: extra['link'] == true);
        },
      ),
      GoRoute(path: '/consent', builder: (_, _) => const ConsentScreen()),
      GoRoute(path: '/account-blocked', builder: (_, _) => const AccountBlockedScreen()),
      GoRoute(path: '/profile-setup', builder: (_, _) => const ProfileSetupScreen()),

      // Buyer tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, mode: AppMode.buyer),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/community', builder: (_, _) => const CommunityScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/requests', builder: (_, _) => const MyRequestsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/chats', builder: (_, _) => const ChatListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())],
          ),
        ],
      ),
      // Seller tabs.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell, mode: AppMode.seller),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/seller/leads', builder: (_, _) => const LeadFeedScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/seller/community', builder: (_, _) => const CommunityScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/seller/quotes', builder: (_, _) => const MyQuotesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/seller/chats', builder: (_, _) => const ChatListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/seller/account', builder: (_, _) => const AccountScreen())],
          ),
        ],
      ),

      // Buyer screens.
      GoRoute(
        path: '/post',
        pageBuilder: (_, s) => fullscreen(
          PostRequestScreen(
            initialText: s.uri.queryParameters['q'],
            categoryId: int.tryParse(s.uri.queryParameters['c'] ?? ''),
          ),
          s,
        ),
      ),
      GoRoute(
        path: '/requests/:id',
        pageBuilder: (_, s) => fullscreen(RequestDetailScreen(requestId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/requests/:id/compare',
        pageBuilder: (_, s) => fullscreen(
          CompareScreen(requestId: s.pathParameters['id']!, quoteIds: (s.extra as List?)?.cast<String>()),
          s,
        ),
      ),
      GoRoute(
        path: '/quotes/:id',
        pageBuilder: (_, s) => fullscreen(QuoteDetailScreen(quoteId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/chats/:id',
        pageBuilder: (_, s) => fullscreen(ChatScreen(chatId: s.pathParameters['id']!), s),
      ),
      GoRoute(path: '/orders', pageBuilder: (_, s) => fullscreen(const OrdersScreen(), s)),
      GoRoute(
        path: '/orders/:id',
        pageBuilder: (_, s) => fullscreen(OrderDetailScreen(orderId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/orders/:id/review',
        pageBuilder: (_, s) => fullscreen(ReviewFormScreen(orderId: s.pathParameters['id']!), s),
      ),
      GoRoute(path: '/notifications', pageBuilder: (_, s) => fullscreen(const NotificationsScreen(), s)),
      GoRoute(
        path: '/feed/:id',
        pageBuilder: (_, s) => fullscreen(
          FeedPostScreen(requestId: s.pathParameters['id']!, focusComment: s.uri.queryParameters['comment'] == '1'),
          s,
        ),
      ),

      // Seller screens.
      GoRoute(path: '/seller/onboarding', pageBuilder: (_, s) => fullscreen(const SellerOnboardingScreen(), s)),
      GoRoute(path: '/seller/verification', pageBuilder: (_, s) => fullscreen(const VerificationScreen(), s)),
      GoRoute(
        path: '/seller/leads/:id',
        pageBuilder: (_, s) => fullscreen(LeadDetailScreen(requestId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/seller/leads/:id/quote',
        pageBuilder: (_, s) => fullscreen(
          QuoteFormScreen(requestId: s.pathParameters['id']!, reviseQuoteId: s.uri.queryParameters['revise']),
          s,
        ),
      ),
      GoRoute(path: '/seller/templates', pageBuilder: (_, s) => fullscreen(const TemplatesScreen(), s)),
      GoRoute(path: '/seller/dashboard', pageBuilder: (_, s) => fullscreen(const DashboardScreen(), s)),
      GoRoute(path: '/seller/plan', pageBuilder: (_, s) => fullscreen(const PlanScreen(), s)),
      GoRoute(
        path: '/s/:id',
        pageBuilder: (_, s) => fullscreen(SellerProfileScreen(sellerId: s.pathParameters['id']!), s),
      ),
      GoRoute(
        path: '/s/:id/reviews',
        pageBuilder: (_, s) => fullscreen(ReviewsScreen(userId: s.pathParameters['id']!), s),
      ),

      // Deep links from the web domains.
      GoRoute(path: '/r/:id', builder: (_, s) => DeepLinkScreen.request(s.pathParameters['id']!)),
      GoRoute(path: '/q/:id', redirect: (_, s) => '/quotes/${s.pathParameters['id']}'),

      // Settings, help and legal.
      GoRoute(path: '/settings', pageBuilder: (_, s) => fullscreen(const SettingsScreen(), s)),
      GoRoute(
        path: '/settings/language',
        pageBuilder: (_, s) => fullscreen(const LanguageScreen(fromSettings: true), s),
      ),
      GoRoute(
        path: '/settings/notifications',
        pageBuilder: (_, s) => fullscreen(const NotificationSettingsScreen(), s),
      ),
      GoRoute(path: '/settings/privacy', pageBuilder: (_, s) => fullscreen(const PrivacySettingsScreen(), s)),
      GoRoute(path: '/settings/blocked', pageBuilder: (_, s) => fullscreen(const BlockedUsersScreen(), s)),
      GoRoute(path: '/settings/delete-account', pageBuilder: (_, s) => fullscreen(const DeleteAccountScreen(), s)),
      GoRoute(path: '/help', pageBuilder: (_, s) => fullscreen(const HelpScreen(), s)),
      GoRoute(path: '/legal', pageBuilder: (_, s) => fullscreen(const LegalIndexScreen(), s)),
      GoRoute(
        path: '/legal/:slug',
        pageBuilder: (_, s) => fullscreen(LegalPageScreen(slug: s.pathParameters['slug']!), s),
      ),
    ],
  );
});

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
