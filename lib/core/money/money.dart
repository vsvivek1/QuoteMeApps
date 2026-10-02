import 'package:money2/money2.dart';

export 'package:money2/money2.dart' show Money, Currency;

/// Helpers around the shared `money2` [Money] type.
///
/// Storage and transport use integer minor units plus an ISO currency code
/// (`amount_minor bigint`, `currency char(3)`). Convert to [Money] at the
/// repository boundary with [moneyFromMinor] and back with [Money.minorUnits].
/// Never use `double` for money.
final CommonCurrencies _common = CommonCurrencies();

Currency currencyFor(String isoCode) {
  switch (isoCode.toUpperCase()) {
    case 'INR':
      return _common.inr;
    case 'USD':
      return _common.usd;
  }
  final c = Currencies().find(isoCode.toUpperCase());
  if (c == null) {
    throw ArgumentError.value(isoCode, 'isoCode', 'Unknown currency');
  }
  return c;
}

Money moneyFromMinor(int minor, String isoCode) => Money.fromIntWithCurrency(minor, currencyFor(isoCode));

Money moneyFromBigMinor(BigInt minor, String isoCode) => Money.fromBigIntWithCurrency(minor, currencyFor(isoCode));

Money zeroMoney(String isoCode) => moneyFromMinor(0, isoCode);

extension MoneyX on Money {
  /// Minor units as an int for storage (bigint column). Throws if out of range.
  int get minorInt => minorUnits.toInt();

  String get isoCode => currency.isoCode;

  bool get isZeroAmount => minorUnits == BigInt.zero;

  /// Sum a list of money values in one currency.
  static Money sum(Iterable<Money> values, String isoCode) => values.fold(zeroMoney(isoCode), (a, b) => a + b);
}

/// Parses user-typed amounts such as "1,299.50" or "1299" into [Money].
/// Returns null for empty or invalid input. Accepts at most the currency's
/// decimal digits.
Money? parseUserAmount(String input, String isoCode) {
  final cleaned = input.replaceAll(RegExp(r'[,\s₹$]'), '');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final major = BigInt.parse(match.group(1)!);
  final fracStr = (match.group(2) ?? '').padRight(2, '0');
  final minor = major * BigInt.from(100) + BigInt.parse(fracStr);
  return moneyFromBigMinor(minor, isoCode);
}
