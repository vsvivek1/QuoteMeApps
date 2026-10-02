import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iwant/core/config/app_env.dart';
import 'package:iwant/core/config/country_config.dart';
import 'package:iwant/core/providers.dart';
import 'package:iwant/core/state/app_state.dart';
import 'package:iwant/l10n/gen/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds a ProviderContainer on the in-memory demo backend.
Future<ProviderContainer> demoContainer(CountryConfig config) async {
  SharedPreferences.setMockInitialValues({'locale': config.defaultLocale.languageCode});
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(overrides: [
    countryConfigProvider.overrideWithValue(config),
    appEnvProvider.overrideWithValue(const AppEnv(env: Env.dev, forceDemo: true)),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ]);
  addTearDown(c.dispose);
  return c;
}

Future<void> pumpScreen(WidgetTester tester, ProviderContainer container, Widget child,
    {Locale locale = const Locale('en')}) async {
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('es')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: child,
    ),
  ));
  await tester.pump();
}
