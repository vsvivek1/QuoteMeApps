import 'package:supabase_flutter/supabase_flutter.dart';

import '../../cache/app_cache.dart';
import '../../cache/outbox.dart';
import '../../config/country_config.dart';
import '../../services/device_services.dart';
import '../backend.dart';
import 'edge_functions.dart';
import 'supabase_auth_repository.dart';
import 'supabase_chat_repository.dart';
import 'supabase_context.dart';
import 'supabase_misc_repositories.dart';
import 'supabase_quote_repository.dart';
import 'supabase_request_repository.dart';
import 'supabase_seller_repository.dart';

/// Wires the Supabase repositories (contract: supabase/API.md) on
/// `Supabase.instance.client`, which bootstrap initialises with the
/// project URL and the anon / publishable key only. The service role key
/// never ships in the app.
///
/// [cache] and [outbox] enable offline reads (stale-while-revalidate) and
/// queued chat messages; without them the repositories go straight to the
/// network.
Backend createSupabaseBackend(
  CountryConfig config, {
  SupabaseClient? client,
  AppCache? cache,
  Outbox? outbox,
  MediaService? media,
  EdgeFunctions? functions,
}) {
  final ctx = SupabaseContext(
    client: client ?? Supabase.instance.client,
    config: config,
    cache: cache,
    outbox: outbox,
    media: media,
    functions: functions,
  );
  final categories = SupabaseCategoryRepository(ctx);
  return Backend(
    auth: SupabaseAuthRepository(ctx),
    profiles: SupabaseProfileRepository(ctx),
    categories: categories,
    requests: SupabaseRequestRepository(ctx, categories),
    quotes: SupabaseQuoteRepository(ctx),
    sellers: SupabaseSellerRepository(ctx),
    leads: SupabaseLeadRepository(ctx),
    chats: SupabaseChatRepository(ctx),
    orders: SupabaseOrderRepository(ctx),
    reviews: SupabaseReviewRepository(ctx),
    notifications: SupabaseNotificationRepository(ctx),
    safety: SupabaseSafetyRepository(ctx),
    flags: SupabaseFlagsRepository(ctx),
    onDispose: ctx.dispose,
  );
}
