import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/gen/app_localizations.dart';
import '../money/money.dart';
import '../money/money_formatter.dart';

extension ContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  String get lang => Localizations.localeOf(this).languageCode;
  String get localeTag => Localizations.localeOf(this).toString();

  String date(DateTime d) => DateFormat.yMMMd(localeTag).format(d.toLocal());
  String dateTime(DateTime d) => DateFormat.yMMMd(localeTag).add_jm().format(d.toLocal());
  String time(DateTime d) => DateFormat.jm(localeTag).format(d.toLocal());

  /// "45 min" / "3 h" style durations.
  String shortDuration(Duration d) {
    if (d.inMinutes < 60) return l10n.minutesShort(d.inMinutes.clamp(1, 59));
    if (d.inHours < 48) return l10n.hoursShort(d.inHours);
    return DateFormat.MMMd(localeTag).format(DateTime.now().add(d));
  }

  void toast(String message) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

final _formatter = MoneyFormatter('en');

extension MoneyDisplay on Money {
  /// ₹1,00,000.00 / $1,299.50
  String get display => _formatter.format(this);

  /// ₹1,00,000 / $1,299.50
  String get displayCompact => _formatter.compact(this);
}

String moneyRange(Money? min, Money? max) => _formatter.range(min, max);
