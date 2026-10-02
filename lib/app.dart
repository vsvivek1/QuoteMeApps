import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/routing/router.dart';
import 'core/services/push_service.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'l10n/gen/app_localizations.dart';

class IWantApp extends ConsumerWidget {
  const IWantApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(countryConfigProvider);
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeControllerProvider);
    final themeMode = ref.watch(themeModeControllerProvider);
    // Registers the FCM token once signed in and routes taps on pushes.
    ref.watch(pushRegistrationProvider);
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light(config),
      darkTheme: AppTheme.dark(config),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: config.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (device, supported) {
        if (device != null) {
          for (final l in supported) {
            if (l.languageCode == device.languageCode) return l;
          }
        }
        return config.defaultLocale;
      },
      builder: (context, child) {
        // Respect large text settings up to 200% (accessibility budget).
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: mq.textScaler.clamp(maxScaleFactor: 2.0)),
          child: child!,
        );
      },
    );
  }
}
