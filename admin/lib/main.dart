import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/admin_env.dart';
import 'core/providers.dart';

/// Admin panel for one country project. Run with
/// `flutter run -d chrome --dart-define-from-file=config/usa.dev.json`
/// (or `config/india.<env>.json`). With an empty SUPABASE_URL it runs in demo
/// mode on in-memory data.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AdminEnv.fromEnvironment();
  if (!env.isDemo) {
    // Only the anon/publishable key ever reaches the client.
    await Supabase.initialize(url: env.supabaseUrl, publishableKey: env.supabaseAnonKey);
  }
  runApp(ProviderScope(
    overrides: [adminEnvProvider.overrideWithValue(env)],
    child: const AdminApp(),
  ));
}
