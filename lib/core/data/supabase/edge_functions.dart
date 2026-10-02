import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'edge_functions.g.dart';

/// Thin wrapper over Supabase Edge Functions so callers don't depend on the
/// client directly.
class EdgeFunctions {
  EdgeFunctions(this._client);
  final SupabaseClient? _client;

  Future<Map<String, dynamic>> invoke(String name, Map<String, Object?> body) async {
    final client = _client;
    if (client == null) throw StateError('Supabase not configured');
    final res = await client.functions.invoke(name, body: body);
    final data = res.data;
    return data is Map<String, dynamic> ? data : <String, dynamic>{'data': data};
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
