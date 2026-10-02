// GENERATED from branding/<country>/colors.json — do not edit.
// Sources: branding/usa/colors.json, branding/india/colors.json
// Regenerate with: python3 tool/branding/generate.py

import 'package:flutter/painting.dart';

/// Brand colours per country app. Light values + `*Dark` values for the dark theme.
class BrandColors {
  const BrandColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.error,
    required this.primaryDark,
    required this.secondaryDark,
    required this.surfaceDark,
    required this.errorDark,
  });

  final Color primary;
  final Color secondary;
  final Color surface;
  final Color error;
  final Color primaryDark;
  final Color secondaryDark;
  final Color surfaceDark;
  final Color errorDark;

  /// I Want USA (Liberty blue)
  static const usa = BrandColors(
    primary: Color(0xFF1D4ED8),
    secondary: Color(0xFF475569),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    primaryDark: Color(0xFF93B4FF),
    secondaryDark: Color(0xFFCBD5E1),
    surfaceDark: Color(0xFF0F172A),
    errorDark: Color(0xFFF2B8B5),
  );

  /// I Want India (Deep saffron)
  static const india = BrandColors(
    primary: Color(0xFFC2410C),
    secondary: Color(0xFF475569),
    surface: Color(0xFFFFFFFF),
    error: Color(0xFFB3261E),
    primaryDark: Color(0xFFFFB077),
    secondaryDark: Color(0xFFCBD5E1),
    surfaceDark: Color(0xFF0F172A),
    errorDark: Color(0xFFF2B8B5),
  );
}
