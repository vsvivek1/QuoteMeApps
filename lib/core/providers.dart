import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/chat/domain/chat_repository.dart';
import '../features/notifications/domain/notification_repository.dart';
import '../features/orders/domain/order_repository.dart';
import '../features/quotes/domain/quote_repository.dart';
import '../features/requests/domain/request_repository.dart';
import '../features/reviews/domain/review_repository.dart';
import '../features/safety/domain/safety_repository.dart';
import '../features/seller/domain/seller_repository.dart';
import '../features/settings/domain/app_settings.dart';
import 'cache/cache_providers.dart';
import 'config/app_env.dart';
import 'config/country_config.dart';
import 'data/backend.dart';
import 'data/supabase/edge_functions.dart';
import 'demo/demo_backend.dart';
import 'services/device_services.dart';

part 'providers.g.dart';

/// Injected by the country entry point.
@Riverpod(keepAlive: true)
CountryConfig countryConfig(Ref ref) => throw UnimplementedError('countryConfigProvider must be overridden');

@Riverpod(keepAlive: true)
AppEnv appEnv(Ref ref) => AppEnv.fromEnvironment();

/// The backend: Supabase, or the in-memory demo marketplace.
@Riverpod(keepAlive: true)
Backend backend(Ref ref) {
  final env = ref.watch(appEnvProvider);
  final config = ref.watch(countryConfigProvider);
  final b = env.isDemo
      ? Backend.demo(DemoBackend(config))
      : Backend.supabase(
          config,
          cache: ref.watch(appCacheProvider),
          outbox: ref.watch(outboxProvider),
          media: ref.watch(mediaServiceProvider),
          functions: ref.watch(edgeFunctionsProvider),
        );
  ref.onDispose(b.dispose);
  return b;
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => ref.watch(backendProvider).auth;

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => ref.watch(backendProvider).profiles;

@Riverpod(keepAlive: true)
CategoryRepository categoryRepository(Ref ref) => ref.watch(backendProvider).categories;

@Riverpod(keepAlive: true)
RequestRepository requestRepository(Ref ref) => ref.watch(backendProvider).requests;

@Riverpod(keepAlive: true)
QuoteRepository quoteRepository(Ref ref) => ref.watch(backendProvider).quotes;

@Riverpod(keepAlive: true)
SellerRepository sellerRepository(Ref ref) => ref.watch(backendProvider).sellers;

@Riverpod(keepAlive: true)
LeadRepository leadRepository(Ref ref) => ref.watch(backendProvider).leads;

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) => ref.watch(backendProvider).chats;

@Riverpod(keepAlive: true)
OrderRepository orderRepository(Ref ref) => ref.watch(backendProvider).orders;

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) => ref.watch(backendProvider).reviews;

@Riverpod(keepAlive: true)
NotificationRepository notificationRepository(Ref ref) => ref.watch(backendProvider).notifications;

@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) => ref.watch(backendProvider).safety;

@Riverpod(keepAlive: true)
FlagsRepository flagsRepository(Ref ref) => ref.watch(backendProvider).flags;
