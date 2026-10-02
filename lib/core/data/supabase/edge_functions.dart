import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'edge_functions.g.dart';

/// Thin wrapper over Supabase Edge Functions so callers don't depend on the
/// client directly. Sends the user JWT (via the client) and, when Firebase is
/// configured, the `X-Firebase-AppCheck` token the functions can enforce.
class EdgeFunctions {
  EdgeFunctions(this._client);
  final SupabaseClient? _client;

  Future<Map<String, dynamic>> invoke(String name, Map<String, Object?> body) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final appCheck = await _appCheckToken();
    final res = await client.functions.invoke(
      name,
      body: body,
      headers: appCheck == null ? null : {'X-Firebase-AppCheck': appCheck},
    );
    final data = res.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{'data': data};
  }

  static Future<String?> _appCheckToken() async {
    try {
      if (Firebase.apps.isEmpty) return null;
      return await FirebaseAppCheck.instance.getToken();
    } catch (_) {
      return null; // not configured for this flavor
    }
  }
}

@Riverpod(keepAlive: true)
EdgeFunctions edgeFunctions(Ref ref) {
  SupabaseClient? client;
  try {
    client = Supabase.instance.client;
  } catch (_) {
    client = null;
  }
  return EdgeFunctions(client);
}
