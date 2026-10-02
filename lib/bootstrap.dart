import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'app.dart';
import 'core/config/app_env.dart';
import 'core/config/country_config.dart';
import 'core/providers.dart';
import 'core/state/app_state.dart';

/// Shared start-up for both country apps.
Future<void> bootstrap(CountryConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  final env = AppEnv.fromEnvironment();

  timeago.setLocaleMessages('hi', timeago.HiMessages());
  timeago.setLocaleMessages('es', timeago.EsMessages());

  if (env.firebaseEnabled) {
    try {
      await Firebase.initializeApp();
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseAppCheck.instance.activate(
        providerAndroid: kDebugMode ? const AndroidDebugProvider() : const AndroidPlayIntegrityProvider(),
        providerApple: kDebugMode ? const AppleDebugProvider() : const AppleAppAttestProvider(),
      );
    } catch (e) {
      debugPrint('Firebase not configured for this flavor: $e');
    }
  }

  if (!env.isDemo) {
    await Supabase.initialize(url: env.supabaseUrl, publishableKey: env.supabaseAnonKey);
    if (env.googleWebClientId.isNotEmpty) {
      await GoogleSignIn.instance.initialize(
        serverClientId: env.googleWebClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS && env.googleIosClientId.isNotEmpty
            ? env.googleIosClientId
            : null,
      );
    }
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(ProviderScope(
    overrides: [
      countryConfigProvider.overrideWithValue(config),
      appEnvProvider.overrideWithValue(env),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const IWantApp(),
  ));
}
