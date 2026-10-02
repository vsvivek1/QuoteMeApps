import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/routing/router.dart';
import 'core/theme/admin_theme.dart';
import 'l10n/gen/app_localizations.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(countryConfigProvider);
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).adminTitle(config.appName),
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AdminTheme.light(config),
      darkTheme: AdminTheme.dark(config),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
