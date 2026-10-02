import 'package:flutter/material.dart';

import '../config/admin_country.dart';

/// Material 3 theme from the country brand colour (`branding/<country>/colors.json`).
abstract final class AdminTheme {
  static ThemeData light(AdminCountryConfig c) => _build(c, Brightness.light);
  static ThemeData dark(AdminCountryConfig c) => _build(c, Brightness.dark);

  static ThemeData _build(AdminCountryConfig c, Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: c.brandPrimary, brightness: b)
        .copyWith(primary: dark ? c.brandPrimaryDark : c.brandPrimary);
    const radius = BorderRadius.all(Radius.circular(12));
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.compact,
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder(borderRadius: radius), isDense: true),
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, scrolledUnderElevation: 1, centerTitle: false),
    );
  }
}
