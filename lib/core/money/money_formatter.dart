import 'package:intl/intl.dart';

import 'money.dart';

/// The one place money is turned into display text.
///
/// `money2` does the math; display uses `intl` grouping so Indian lakh/crore
/// grouping (₹1,00,000.00) renders correctly. Only integers reach intl, so no
/// floating point is involved.
class MoneyFormatter {
  MoneyFormatter(this.locale);

  final String locale;

  static const _symbols = {'INR': '₹', 'USD': r'$'};

  String _groupingLocale(String isoCode) {
    // Indian grouping for INR whatever the UI language; US grouping for USD.
    if (isoCode == 'INR') return 'en_IN';
    if (isoCode == 'USD') return 'en_US';
    return locale;
  }

  /// Full format, e.g. ₹1,00,000.00 or $1,299.50.
  String format(Money money, {bool showMinorIfZero = true}) {
    final iso = money.currency.isoCode;
    final digits = money.currency.decimalDigits;
    final minor = money.minorUnits;
    final negative = minor.isNegative;
    final abs = minor.abs();
    final scale = BigInt.from(10).pow(digits);
    final major = abs ~/ scale;
    final frac = abs.remainder(scale);
    final grouped = NumberFormat.decimalPattern(_groupingLocale(iso)).format(major.toInt());
    final symbol = _symbols[iso] ?? '$iso ';
    final showFrac = digits > 0 && (showMinorIfZero || frac != BigInt.zero);
    final fracText = showFrac ? '.${frac.toString().padLeft(digits, '0')}' : '';
    return '${negative ? '-' : ''}$symbol$grouped$fracText';
  }

  /// Compact format without zero paise/cents, e.g. ₹1,00,000 or $1,299.50.
  String compact(Money money) => format(money, showMinorIfZero: false);

  /// Range like "₹10,000 – ₹15,000".
  String range(Money? min, Money? max) {
    if (min != null && max != null) return '${compact(min)} – ${compact(max)}';
    if (min != null) return '${compact(min)}+';
    if (max != null) return '≤ ${compact(max)}';
    return '';
  }
}
