import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/domain/auth_repository.dart';
import '../../../features/quotes/domain/quote_repository.dart';
import '../../../features/requests/domain/request_repository.dart';

/// Maps backend errors (API.md section 9) to the app's failure types.
///
/// RPCs raise `PostgrestException(code: 'PTnnn', message: '<snake_case>')`;
/// Edge Functions answer `{code, message, details, hint}` with the HTTP
/// status (surfaced as a [FunctionException] whose `details` is that body).
/// Codes the app has no special wording for pass through unchanged (they are
/// stable); transport failures become `network`; anything else `unknown`.

final _snake = RegExp(r'^[a-z][a-z0-9_]*$');

/// True when the request never got an answer (offline, DNS, timeout, TLS).
bool isNetworkError(Object e) {
  if (e is FunctionsFetchException) return true;
  if (e is AuthRetryableFetchException) return true;
  if (e is IOException || e is TimeoutException) return true;
  final t = e.runtimeType.toString();
  return t.contains('ClientException') || t.contains('SocketException') || t.contains('HandshakeException');
}

/// The stable snake_case code carried by a backend error, or null.
String? serverErrorCode(Object e) {
  if (e is PostgrestException) {
    if (_snake.hasMatch(e.message)) return e.message;
    if (e.code == '42501') return 'not_allowed'; // RLS / grant violation
    if (e.code == '23505') return 'duplicate';
    return null;
  }
  if (e is FunctionException) {
    final d = e.details;
    if (d is Map) {
      for (final k in const ['message', 'code', 'error']) {
        final v = d[k];
        if (v is String && _snake.hasMatch(v)) return v;
      }
    }
    if (e.status == 429) return 'rate_limited';
    if (e.status == 401) return 'not_authenticated';
    return null;
  }
  if (e is AuthException) {
    final c = e.code;
    return (c != null && _snake.hasMatch(c)) ? c : null;
  }
  return null;
}

/// Server code, `network` or `unknown`.
String errorCode(Object e) => serverErrorCode(e) ?? (isNetworkError(e) ? 'network' : 'unknown');

// -------------------------------------------------------------- requests

/// `rate_limited | duplicate | blocked_category | invalid | network`
/// (+ pass-through server codes).
String requestFailureCode(String server) => switch (server) {
  'rate_limited' => 'rate_limited',
  'duplicate_request' || 'duplicate' => 'duplicate',
  'category_blocked' || 'blocked_content' || 'invalid_or_blocked_category' => 'blocked_category',
  'network' || 'unknown' => server,
  'not_authenticated' || 'account_not_active' || 'not_allowed' || 'blocked' => server,
  'request_not_found' || 'request_not_open' || 'category_not_found' => server,
  _ => 'invalid', // every 400 / 422 validation code
};

RequestFailure toRequestFailure(Object e) {
  final server = errorCode(e);
  return RequestFailure(requestFailureCode(server), e is PostgrestException ? e.details?.toString() : e.toString());
}

// ---------------------------------------------------------------- quotes

/// `cap_reached | request_closed | not_allowed | licence_required |
/// no_credits | priority_window | rate_limited | already_quoted | network`
/// (+ pass-through server codes).
String quoteFailureCode(String server) => switch (server) {
  'quote_cap_reached' => 'cap_reached',
  'request_not_open' || 'quote_window_closed' || 'request_not_found' => 'request_closed',
  'licence_required' || 'licence_expired' => 'licence_required',
  'quota_exhausted' => 'no_credits',
  'priority_window' => 'priority_window',
  'rate_limited' => 'rate_limited',
  'already_quoted' => 'already_quoted',
  'blocked' ||
  'cannot_quote_own_request' ||
  'category_blocked' ||
  'request_not_in_service_area' ||
  'not_a_seller' ||
  'seller_suspended' ||
  'account_not_active' ||
  'chat_not_allowed' ||
  'not_allowed' => 'not_allowed',
  _ => server,
};

QuoteFailure toQuoteFailure(Object e) {
  final server = errorCode(e);
  return QuoteFailure(quoteFailureCode(server), e is PostgrestException ? e.details?.toString() : e.toString());
}

// ------------------------------------------------------------------ auth

/// `invalid_otp | rate_limited | cancelled | captcha_failed | phone_in_use |
/// reauth_required | not_signed_in | network | failed`.
String authFailureCode(String server) => switch (server) {
  'otp_expired' || 'invalid_otp' || 'invalid_credentials' || 'otp_disabled' => 'invalid_otp',
  'over_sms_send_rate_limit' ||
  'over_request_rate_limit' ||
  'over_email_send_rate_limit' ||
  'rate_limited' => 'rate_limited',
  'captcha_failed' => 'captcha_failed',
  'phone_exists' || 'identity_already_exists' || 'email_exists' => 'phone_in_use',
  'session_not_found' || 'session_expired' || 'reauthentication_needed' || 'not_authenticated' => 'reauth_required',
  'cancelled' || 'not_signed_in' || 'network' => server,
  _ => 'failed',
};

AuthFailure toAuthFailure(Object e) {
  if (e is AuthFailure) return e;
  if (e is AuthException && e.code == null && e.statusCode == '429') return AuthFailure('rate_limited', e.message);
  return AuthFailure(authFailureCode(errorCode(e)), e.toString());
}

// --------------------------------------------------------------- generic

/// For repositories without a failure type the demo throws
/// `StateError(code)`; do the same so screens behave identically.
StateError toStateError(Object e) => StateError(errorCode(e));

Future<T> guardState<T>(Future<T> Function() f) async {
  try {
    return await f();
  } on StateError {
    rethrow;
  } catch (e) {
    throw toStateError(e);
  }
}
