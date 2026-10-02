import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/data/supabase/errors.dart';
import 'package:iwant/core/data/supabase/supabase_misc_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

PostgrestException rpcError(String message, int http) =>
    PostgrestException(message: message, code: 'PT$http', details: message);

void main() {
  group('server code extraction', () {
    test('PostgREST RPC errors carry the snake_case message', () {
      expect(serverErrorCode(rpcError('quote_cap_reached', 409)), 'quote_cap_reached');
      expect(errorCode(rpcError('rate_limited', 429)), 'rate_limited');
    });

    test('RLS violations and non-code messages', () {
      expect(
        errorCode(const PostgrestException(message: 'new row violates row-level security policy', code: '42501')),
        'not_allowed',
      );
      expect(errorCode(const PostgrestException(message: '<html>Bad gateway</html>', code: '502')), 'unknown');
    });

    test('Edge Function errors read the JSON body', () {
      expect(
        errorCode(
          const FunctionException(
            status: 403,
            details: {'code': 'captcha_failed', 'message': 'captcha_failed', 'details': null},
          ),
        ),
        'captcha_failed',
      );
      expect(errorCode(const FunctionException(status: 429, details: 'Too many')), 'rate_limited');
      expect(errorCode(const FunctionsFetchException(details: 'offline')), 'network');
    });

    test('transport failures are network, anything else unknown', () {
      expect(errorCode(const SocketException('no route')), 'network');
      expect(errorCode(TimeoutException('slow')), 'network');
      expect(isNetworkError(Exception('boom')), isFalse);
      expect(errorCode(Exception('boom')), 'unknown');
    });
  });

  group('QuoteFailure codes', () {
    final cases = {
      'quote_cap_reached': 'cap_reached',
      'request_not_open': 'request_closed',
      'quote_window_closed': 'request_closed',
      'licence_required': 'licence_required',
      'quota_exhausted': 'no_credits',
      'priority_window': 'priority_window',
      'rate_limited': 'rate_limited',
      'already_quoted': 'already_quoted',
      'request_not_in_service_area': 'not_allowed',
      'cannot_quote_own_request': 'not_allowed',
      'blocked': 'not_allowed',
      'quote_expired': 'quote_expired', // no special wording: passes through
    };
    cases.forEach((server, app) {
      test('$server -> $app', () => expect(toQuoteFailure(rpcError(server, 409)).code, app));
    });
    test('offline -> network', () {
      expect(toQuoteFailure(const SocketException('x')).code, 'network');
    });
  });

  group('RequestFailure codes', () {
    final cases = {
      'rate_limited': 'rate_limited',
      'duplicate_request': 'duplicate',
      'category_blocked': 'blocked_category',
      'blocked_content': 'blocked_category',
      'invalid_budget': 'invalid',
      'location_required': 'invalid',
      'unknown_postal_code': 'invalid',
      'missing_required_field': 'invalid',
    };
    cases.forEach((server, app) {
      test('$server -> $app', () => expect(toRequestFailure(rpcError(server, 400)).code, app));
    });
    test('offline -> network', () {
      expect(toRequestFailure(const SocketException('x')).code, 'network');
    });
  });

  group('AuthFailure codes', () {
    test('GoTrue error codes', () {
      expect(
        toAuthFailure(const AuthApiException('expired', statusCode: '403', code: 'otp_expired')).code,
        'invalid_otp',
      );
      expect(
        toAuthFailure(const AuthApiException('slow down', statusCode: '429', code: 'over_sms_send_rate_limit')).code,
        'rate_limited',
      );
      expect(toAuthFailure(const AuthException('slow down', statusCode: '429')).code, 'rate_limited');
      expect(
        toAuthFailure(const AuthApiException('x', statusCode: '400', code: 'captcha_failed')).code,
        'captcha_failed',
      );
      expect(toAuthFailure(const AuthApiException('x', statusCode: '422', code: 'phone_exists')).code, 'phone_in_use');
      expect(toAuthFailure(AuthRetryableFetchException(message: 'offline')).code, 'network');
      expect(toAuthFailure(Exception('?')).code, 'failed');
    });
  });

  test('report reasons map to the server enum', () {
    expect(SupabaseSafetyRepository.reasonJson('abuse'), 'abusive');
    expect(SupabaseSafetyRepository.reasonJson('prohibited'), 'prohibited_item');
    expect(SupabaseSafetyRepository.reasonJson('spam'), 'spam');
    expect(SupabaseSafetyRepository.reasonJson('whatever'), 'other');
  });
}
