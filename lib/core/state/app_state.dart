import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/domain/app_user.dart';
import '../../features/settings/domain/app_settings.dart';
import '../providers.dart';

part 'app_state.g.dart';

/// Overridden in bootstrap with the loaded instance.
@Riverpod(keepAlive: true)
SharedPreferences sharedPreferences(Ref ref) =>
    throw UnimplementedError('sharedPreferencesProvider must be overridden');

@Riverpod(keepAlive: true)
Stream<AuthSession?> authSession(Ref ref) => ref.watch(authRepositoryProvider).sessionChanges();

@Riverpod(keepAlive: true)
Stream<Profile?> myProfile(Ref ref) {
  final session = ref.watch(authSessionProvider).value;
  if (session == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchMyProfile();
}

@Riverpod(keepAlive: true)
AppMode appMode(Ref ref) => ref.watch(myProfileProvider).value?.activeMode ?? AppMode.buyer;

@Riverpod(keepAlive: true)
Future<AppFlags> appFlags(Ref ref) => ref.watch(flagsRepositoryProvider).load();

/// Whether the signed-in user accepted the current Terms and Privacy versions.
@Riverpod(keepAlive: true)
Future<bool> consentAccepted(Ref ref) async {
  final session = ref.watch(authSessionProvider).value;
  if (session == null) return false;
  final flags = await ref.watch(appFlagsProvider.future);
  // Re-check when the profile changes (consents are recorded through it).
  ref.watch(myProfileProvider);
  return ref.watch(profileRepositoryProvider).hasAcceptedCurrentTerms(flags.termsVersion, flags.privacyVersion);
}

const _localeKey = 'locale';
const _themeKey = 'theme_mode';

@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale? build() {
    final tag = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    if (tag == null) return null;
    final parts = tag.split('_');
    return Locale(parts[0], parts.length > 1 ? parts[1] : null);
  }

  Future<void> set(Locale locale) async {
    await ref
        .read(sharedPreferencesProvider)
        .setString(_localeKey, [locale.languageCode, if (locale.countryCode != null) locale.countryCode].join('_'));
    state = locale;
    final session = ref.read(authSessionProvider).value;
    if (session != null) {
      await ref.read(profileRepositoryProvider).updateProfile(language: locale.languageCode);
    }
  }
}

@Riverpod(keepAlive: true)
class ThemeModeController extends _$ThemeModeController {
  @override
  ThemeMode build() {
    final v = ref.watch(sharedPreferencesProvider).getString(_themeKey);
    return ThemeMode.values.firstWhere((m) => m.name == v, orElse: () => ThemeMode.system);
  }

  Future<void> set(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_themeKey, mode.name);
    state = mode;
  }
}
