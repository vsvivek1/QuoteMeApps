import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/auth/domain/app_user.dart';
import '../../../features/auth/domain/auth_repository.dart';
import 'errors.dart';
import 'mappers.dart';
import 'supabase_context.dart';

/// Phone OTP, Google and Apple through Supabase Auth (API.md section 1).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.ctx);
  final SupabaseContext ctx;

  GoTrueClient get _auth => ctx.client.auth;

  AuthSession? _toSession(Session? s) {
    final u = s?.user;
    if (u == null) return null;
    final providers = u.appMetadata['providers'];
    return AuthSession(
      userId: u.id,
      phone: (u.phone == null || u.phone!.isEmpty) ? null : '+${u.phone!.replaceFirst('+', '')}',
      email: (u.email == null || u.email!.isEmpty) ? null : u.email,
      providers: providers is List
          ? [for (final p in providers) p.toString()]
          : [if (u.appMetadata['provider'] != null) u.appMetadata['provider'].toString()],
    );
  }

  @override
  AuthSession? get currentSession => _toSession(_auth.currentSession);

  /// Custom claims of the current access token (roles, active_mode,
  /// account_status, seller_verified).
  JwtClaims? get claims {
    final token = _auth.currentSession?.accessToken;
    return token == null ? null : claimsFromJwt(token);
  }

  @override
  Stream<AuthSession?> sessionChanges() async* {
    yield currentSession;
    yield* _auth.onAuthStateChange.map((s) => _toSession(s.session)).distinct();
  }

  Future<T> _guard<T>(Future<T> Function() f) async {
    try {
      return await f();
    } catch (e) {
      throw toAuthFailure(e);
    }
  }

  // ------------------------------------------------------------- phone

  @override
  Future<void> sendPhoneOtp(String e164, {String? captchaToken}) =>
      _guard(() => _auth.signInWithOtp(phone: e164, captchaToken: captchaToken));

  @override
  Future<void> verifyPhoneOtp(String e164, String code) =>
      _guard(() => _auth.verifyOTP(phone: e164, token: code, type: OtpType.sms));

  // ------------------------------------------------------------- email

  @override
  Future<void> sendEmailOtp(String email, {String? captchaToken}) =>
      _guard(() => _auth.signInWithOtp(email: email, shouldCreateUser: true, captchaToken: captchaToken));

  @override
  Future<void> verifyEmailOtp(String email, String code) =>
      _guard(() => _auth.verifyOTP(email: email, token: code, type: OtpType.email));

  /// Adds a phone to the signed-in (Google / Apple) user; Supabase sends the
  /// OTP to the new number and links it on verification.
  @override
  Future<void> linkPhone(String e164) => _guard(() => _auth.updateUser(UserAttributes(phone: e164)));

  @override
  Future<void> verifyLinkedPhone(String e164, String code) => _guard(() async {
    await _auth.verifyOTP(phone: e164, token: code, type: OtpType.phoneChange);
    ctx.changed(Topics.profile);
  });

  // ------------------------------------------------------------ google

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final GoogleSignInAccount account;
    try {
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled || e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthFailure('cancelled');
      }
      throw AuthFailure('failed', e.description);
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw const AuthFailure('failed', 'Google returned no ID token');
    await _auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);
  });

  // ------------------------------------------------------------- apple

  static String _rawNonce([int length = 32]) {
    const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static bool get _nativeApple =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  @override
  Future<void> signInWithApple() => _guard(() async {
    if (!_nativeApple) {
      // Android / web: the web OAuth flow (Supabase redirects back to the app).
      await _auth.signInWithOAuth(OAuthProvider.apple, authScreenLaunchMode: LaunchMode.externalApplication);
      return;
    }
    // Apple gets SHA-256(raw); Supabase gets raw and checks the hash.
    final raw = _rawNonce();
    final hashed = sha256.convert(utf8.encode(raw)).toString();
    final AuthorizationCredentialAppleID cred;
    try {
      cred = await SignInWithApple.getAppleIDCredential(
        scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashed,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw const AuthFailure('cancelled');
      throw AuthFailure('failed', e.message);
    }
    final idToken = cred.identityToken;
    if (idToken == null) throw const AuthFailure('failed', 'Apple returned no identity token');
    final res = await _auth.signInWithIdToken(provider: OAuthProvider.apple, idToken: idToken, nonce: raw);
    // Apple sends the name only on the very first sign-in: keep it.
    final name = [cred.givenName, cred.familyName].whereType<String>().where((s) => s.trim().isNotEmpty).join(' ');
    final uid = res.user?.id;
    if (name.isNotEmpty && uid != null) {
      try {
        final row = await ctx.client.from('profiles').select('name').eq('id', uid).maybeSingle();
        if ((row?['name'] as String? ?? '').trim().isEmpty) {
          await ctx.client.from('profiles').update({'name': name}).eq('id', uid);
          ctx.changed(Topics.profile);
        }
      } catch (e) {
        debugPrint('apple name save: $e');
      }
    }
  });

  // ---------------------------------------------------------- sign-out

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('signOut: $e'); // the local session is cleared regardless
    }
    await _clearLocal();
  }

  Future<void> _clearLocal() async {
    ctx.clearMemory();
    try {
      await ctx.cache?.clearAll();
    } catch (e) {
      debugPrint('cache clear: $e');
    }
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }

  @override
  Future<void> deleteAccount({String? reason}) => _guard(() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('not_signed_in');
    final body = <String, Object?>{};
    final providers = currentSession?.providers ?? const [];
    if (providers.contains('apple') && _nativeApple) {
      // Re-run Sign in with Apple so the function can revoke the token.
      try {
        final cred = await SignInWithApple.getAppleIDCredential(scopes: const []);
        body['apple_authorization_code'] = cred.authorizationCode;
      } on SignInWithAppleAuthorizationException catch (e) {
        if (e.code == AuthorizationErrorCode.canceled) throw const AuthFailure('reauth_required');
      }
    }
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;
    await ctx.functions.invoke('delete-account', body);
    await signOut();
  });
}

/// `profiles` row, mode switch and consents.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this.ctx);
  final SupabaseContext ctx;

  @override
  Future<Profile?> fetchMyProfile() async {
    final uid = ctx.uidOrNull;
    if (uid == null) return null;
    final row = await ctx.client.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return mapProfile(row);
  }

  @override
  Stream<Profile?> watchMyProfile() {
    final uid = ctx.uidOrNull;
    if (uid == null) return Stream.value(null);
    return ctx.liveQuery(name: 'profile:$uid', fetch: fetchMyProfile, topics: {Topics.profile, Topics.seller});
  }

  @override
  Future<void> updateProfile({String? name, String? language, String? photoPath}) async {
    final uid = ctx.uid;
    final patch = <String, Object?>{};
    if (name != null) patch['name'] = name.trim();
    if (language != null) patch['language'] = language;
    if (photoPath != null) {
      patch['photo_url'] = SupabaseContext.isLocalPath(photoPath)
          ? ctx.publicUrl(
              Buckets.sellerMedia,
              await ctx.upload(Buckets.sellerMedia, (ext) => '$uid/avatar-${ctx.newId()}.$ext', photoPath),
            )
          : photoPath;
    }
    if (patch.isEmpty) return;
    await guardState(() => ctx.client.from('profiles').update(patch).eq('id', uid));
    ctx.changed(Topics.profile);
  }

  @override
  Future<void> setActiveMode(AppMode mode) async {
    await guardState(() => ctx.client.rpc<dynamic>('set_active_mode', params: {'p_mode': mode.name}));
    try {
      await ctx.client.auth.refreshSession(); // new active_mode claim
    } catch (e) {
      debugPrint('refreshSession: $e');
    }
    ctx.changed(Topics.profile);
  }

  static const _documents = {'terms', 'privacy', 'marketing', 'analytics', 'whatsapp', 'seller_terms'};

  @override
  Future<void> recordConsents(
    Map<String, String> documentVersions, {
    bool marketing = false,
    bool analytics = false,
  }) async {
    final uid = ctx.uid;
    final privacyVersion = documentVersions['privacy'] ?? documentVersions.values.firstOrNull ?? '1.0';
    final rows = [
      for (final e in documentVersions.entries)
        if (_documents.contains(e.key))
          {'user_id': uid, 'document': e.key, 'version': e.value, 'granted': true, 'source': 'app'},
      if (!documentVersions.containsKey('marketing'))
        {'user_id': uid, 'document': 'marketing', 'version': privacyVersion, 'granted': marketing, 'source': 'app'},
      if (!documentVersions.containsKey('analytics'))
        {'user_id': uid, 'document': 'analytics', 'version': privacyVersion, 'granted': analytics, 'source': 'app'},
    ];
    await guardState(() => ctx.client.from('consents').insert(rows));
    ctx.changed(Topics.profile);
  }

  @override
  Future<bool> hasAcceptedCurrentTerms(String termsVersion, String privacyVersion) async {
    final uid = ctx.uidOrNull;
    if (uid == null) return false;
    final rows = await ctx.client
        .from('consents')
        .select('document, version, granted')
        .eq('user_id', uid)
        .inFilter('document', ['terms', 'privacy'])
        .eq('granted', true);
    bool has(String doc, String v) => rows.any((r) => r['document'] == doc && r['version'] == v);
    return has('terms', termsVersion) && has('privacy', privacyVersion);
  }
}
