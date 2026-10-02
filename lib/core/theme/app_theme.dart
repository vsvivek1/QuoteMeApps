import 'package:flutter/material.dart';

import '../config/country_config.dart';
import 'brand_colors.g.dart';

/// Material 3 theme from the country's brand colours
/// (generated from `branding/<country>/colors.json`).
abstract final class AppTheme {
  static BrandColors brandFor(Country c) =>
      c == Country.india ? BrandColors.india : BrandColors.usa;

  static ThemeData light(CountryConfig config) => _build(config, Brightness.light);
  static ThemeData dark(CountryConfig config) => _build(config, Brightness.dark);

  static ThemeData _build(CountryConfig config, Brightness brightness) {
    final brand = brandFor(config.country);
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: brand.primary,
      brightness: brightness,
    ).copyWith(
      primary: dark ? brand.primaryDark : brand.primary,
      secondary: dark ? brand.secondaryDark : brand.secondary,
      error: dark ? brand.errorDark : brand.error,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );
    const radius = BorderRadius.all(Radius.circular(14));
    return base.copyWith(
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: radius),
        filled: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: const RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      pageTransitionsTheme: config.lowEndDeviceMode
          ? const PageTransitionsTheme(builders: {
              TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
            })
          : null,
    );
  }
}
