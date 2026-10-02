/// Build-time settings for the admin panel, read from
/// `--dart-define-from-file=config/<country>.<env>.json` (see admin/README.md).
///
/// Only public values ever go here: the Supabase URL and the anon /
/// publishable key. Never the service role key; privileged work happens in
/// admin-checked Postgres functions and Edge Functions.
///
/// With no Supabase URL the panel runs on an in-memory demo backend.
class AdminEnv {
  const AdminEnv({
    required this.country,
    this.env = 'dev',
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.forceDemo = false,
  });

  factory AdminEnv.fromEnvironment() => const AdminEnv(
        country: String.fromEnvironment('COUNTRY', defaultValue: 'usa'),
        env: String.fromEnvironment('ENV', defaultValue: 'dev'),
        supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
        supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
        forceDemo: bool.fromEnvironment('DEMO_MODE'),
      );

  /// `usa` or `india`.
  final String country;

  /// `dev`, `staging` or `prod`.
  final String env;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool forceDemo;

  bool get isDemo => forceDemo || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty;
  bool get isProd => env == 'prod';
}
