import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';

enum UserRole { buyer, seller, admin }

enum AppMode { buyer, seller }

/// Row in `profiles` (1:1 with auth.users).
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    String? language,
    @Default([UserRole.buyer]) List<UserRole> roles,
    @Default(AppMode.buyer) AppMode activeMode,
    @Default(false) bool phoneVerified,
    DateTime? createdAt,
  }) = _Profile;

  const Profile._();

  bool get isSeller => roles.contains(UserRole.seller);
  bool get isAdmin => roles.contains(UserRole.admin);
  bool get needsProfileSetup => (name ?? '').trim().isEmpty;
}

/// Minimal auth session info the app needs.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String userId,
    String? phone,
    String? email,
    @Default([]) List<String> providers,
  }) = _AuthSession;
}
