import 'package:flutter/services.dart' show appFlavor;

enum Env { dev, staging, prod }

/// Build-time settings. Values come from
/// `--dart-define-from-file=config/<country>.<env>.json` (see config/README.md);
/// the env itself comes from the flavor name (e.g. `indiaStaging`).
///
/// With no Supabase URL the app runs in demo mode on an in-memory backend.
class AppEnv {
  const AppEnv({
    required this.env,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
    this.turnstileSiteKey = '',
    this.firebaseEnabled = false,
    this.forceDemo = false,
    this.phoneAuthEnabled = true,
  });

  factory AppEnv.fromEnvironment() => AppEnv(
    env: _envFromFlavor(appFlavor),
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    googleWebClientId: const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    googleIosClientId: const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
    turnstileSiteKey: const String.fromEnvironment('TURNSTILE_SITE_KEY'),
    firebaseEnabled: const bool.fromEnvironment('FIREBASE_ENABLED'),
    forceDemo: const bool.fromEnvironment('DEMO_MODE'),
    phoneAuthEnabled: const bool.fromEnvironment('PHONE_AUTH_ENABLED', defaultValue: true),
  );

  final Env env;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;
  final String turnstileSiteKey;
  final bool firebaseEnabled;
  final bool forceDemo;

  /// False hides phone sign-in and phone linking (no SMS provider configured).
  final bool phoneAuthEnabled;

  bool get isDemo => forceDemo || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  bool get isProd => env == Env.prod;

  static Env _envFromFlavor(String? flavor) {
    final f = (flavor ?? '').toLowerCase();
    if (f.endsWith('prod')) return Env.prod;
    if (f.endsWith('staging')) return Env.staging;
    return Env.dev;
  }
}
