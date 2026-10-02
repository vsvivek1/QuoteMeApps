import 'app_user.dart';

/// Thrown by repositories with a stable code the UI maps to l10n text.
class AuthFailure implements Exception {
  const AuthFailure(this.code, [this.message]);
  final String code;
  final String? message;
  @override
  String toString() => 'AuthFailure($code, $message)';
}

abstract interface class AuthRepository {
  Stream<AuthSession?> sessionChanges();
  AuthSession? get currentSession;

  Future<void> sendPhoneOtp(String e164, {String? captchaToken});
  Future<void> verifyPhoneOtp(String e164, String code);

  /// Native Google sign-in followed by signInWithIdToken.
  Future<void> signInWithGoogle();

  /// Sign in with Apple with a hashed nonce. Saves the name Apple only sends
  /// on the first sign-in.
  Future<void> signInWithApple();

  /// Attach a phone to the current (Google/Apple) user instead of creating a
  /// duplicate account.
  Future<void> linkPhone(String e164);
  Future<void> verifyLinkedPhone(String e164, String code);

  Future<void> signOut();

  /// Calls the delete-account Edge Function, then signs out.
  Future<void> deleteAccount({String? reason});
}

abstract interface class ProfileRepository {
  Stream<Profile?> watchMyProfile();
  Future<Profile?> fetchMyProfile();
  Future<void> updateProfile({String? name, String? language, String? photoPath});
  Future<void> setActiveMode(AppMode mode);
  Future<void> recordConsents(Map<String, String> documentVersions,
      {bool marketing = false, bool analytics = false});
  Future<bool> hasAcceptedCurrentTerms(String termsVersion, String privacyVersion);
}
