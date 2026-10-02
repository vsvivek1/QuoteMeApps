import '../../features/auth/domain/auth_repository.dart';
import '../../features/chat/domain/chat_repository.dart';
import '../../features/notifications/domain/notification_repository.dart';
import '../../features/orders/domain/order_repository.dart';
import '../../features/quotes/domain/quote_repository.dart';
import '../../features/requests/domain/request_repository.dart';
import '../../features/reviews/domain/review_repository.dart';
import '../../features/safety/domain/safety_repository.dart';
import '../../features/seller/domain/seller_repository.dart';
import '../../features/settings/domain/app_settings.dart';
import '../config/country_config.dart';
import '../demo/demo_backend.dart';
import '../demo/demo_repositories.dart';
import 'supabase/supabase_backend.dart';

/// All repositories for one backend. Features only see the interfaces, so the
/// data layer can be swapped without touching them.
class Backend {
  Backend({
    required this.auth,
    required this.profiles,
    required this.categories,
    required this.requests,
    required this.quotes,
    required this.sellers,
    required this.leads,
    required this.chats,
    required this.orders,
    required this.reviews,
    required this.notifications,
    required this.safety,
    required this.flags,
    this.demo,
    void Function()? onDispose,
  }) : _onDispose = onDispose; // ignore: prefer_initializing_formals

  factory Backend.demo(DemoBackend b) => Backend(
        auth: DemoAuthRepository(b),
        profiles: DemoProfileRepository(b),
        categories: DemoCategoryRepository(b),
        requests: DemoRequestRepository(b),
        quotes: DemoQuoteRepository(b),
        sellers: DemoSellerRepository(b),
        leads: DemoLeadRepository(b),
        chats: DemoChatRepository(b),
        orders: DemoOrderRepository(b),
        reviews: DemoReviewRepository(b),
        notifications: DemoNotificationRepository(b),
        safety: DemoSafetyRepository(b),
        flags: DemoFlagsRepository(),
        demo: b,
        onDispose: b.dispose,
      );

  factory Backend.supabase(CountryConfig config) => createSupabaseBackend(config);

  final AuthRepository auth;
  final ProfileRepository profiles;
  final CategoryRepository categories;
  final RequestRepository requests;
  final QuoteRepository quotes;
  final SellerRepository sellers;
  final LeadRepository leads;
  final ChatRepository chats;
  final OrderRepository orders;
  final ReviewRepository reviews;
  final NotificationRepository notifications;
  final SafetyRepository safety;
  final FlagsRepository flags;

  /// Non-null in demo mode.
  final DemoBackend? demo;
  final void Function()? _onDispose;

  bool get isDemo => demo != null;

  void dispose() => _onDispose?.call();
}
