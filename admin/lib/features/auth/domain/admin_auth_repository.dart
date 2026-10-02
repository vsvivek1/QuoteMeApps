/// A signed-in administrator.
class AdminSession {
  const AdminSession({required this.userId, required this.email, this.name});
  final String userId;
  final String email;
  final String? name;
}

/// Sign-in refused because the account has no active `admin` role.
class NotAdminException implements Exception {
  const NotAdminException();
  @override
  String toString() => 'not_admin';
}

class InvalidCredentialsException implements Exception {
  const InvalidCredentialsException();
  @override
  String toString() => 'invalid_credentials';
}

/// Email + password sign-in for the admin panel. A session only exists when
/// the access token's `roles` claim (custom access token hook) contains
/// `admin` AND the profile still has the role and is active, mirroring
/// `private.is_admin()` in the database.
abstract interface class AdminAuthRepository {
  AdminSession? get current;
  Stream<AdminSession?> sessionChanges();
  Future<AdminSession> signIn({required String email, required String password});
  Future<void> signOut();
}
