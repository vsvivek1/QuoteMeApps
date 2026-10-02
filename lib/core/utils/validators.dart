/// Pure validators used by CountryConfig. No UI strings here; callers map
/// failures to localized messages.
abstract final class Validators {
  static const _gstChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  /// India GSTIN: 15 chars, state code, PAN, entity number, 'Z', checksum.
  static bool gstin(String input) {
    final v = input.trim().toUpperCase();
    if (!RegExp(r'^\d{2}[A-Z]{5}\d{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch(v)) {
      return false;
    }
    final state = int.parse(v.substring(0, 2));
    if (state < 1 || state > 38 && state != 97 && state != 99) return false;
    return v[14] == gstinCheckChar(v.substring(0, 14));
  }

  static String gstinCheckChar(String first14) {
    var sum = 0;
    for (var i = 0; i < 14; i++) {
      final value = _gstChars.indexOf(first14[i]);
      final product = value * (i.isEven ? 1 : 2);
      sum += product ~/ 36 + product % 36;
    }
    return _gstChars[(36 - sum % 36) % 36];
  }

  /// India Udyam registration: UDYAM-XX-00-0000000.
  static bool udyam(String input) => RegExp(r'^UDYAM-[A-Z]{2}-\d{2}-\d{7}$').hasMatch(input.trim().toUpperCase());

  /// US EIN: 9 digits, optionally formatted 12-3456789, with a valid prefix.
  static bool ein(String input) {
    final digits = input.replaceAll('-', '').trim();
    if (!RegExp(r'^\d{9}$').hasMatch(digits)) return false;
    const invalidPrefixes = {
      '00',
      '07',
      '08',
      '09',
      '17',
      '18',
      '19',
      '28',
      '29',
      '49',
      '69',
      '70',
      '78',
      '79',
      '89',
      '96',
      '97',
    };
    return !invalidPrefixes.contains(digits.substring(0, 2));
  }

  /// Generic licence numbers: 3-30 letters, digits, dashes or slashes.
  static bool licenceNumber(String input) => RegExp(r'^[A-Za-z0-9\-/ ]{3,30}$').hasMatch(input.trim());

  /// India PIN: 6 digits, first digit 1-9.
  static bool indiaPin(String input) => RegExp(r'^[1-9]\d{5}$').hasMatch(input.trim());

  /// US ZIP or ZIP+4.
  static bool usZip(String input) => RegExp(r'^\d{5}(-\d{4})?$').hasMatch(input.trim());

  /// India mobile (without +91): 10 digits starting 6-9.
  static bool indiaMobile(String input) => RegExp(r'^[6-9]\d{9}$').hasMatch(_digits(input));

  /// US phone (without +1): NANP 10 digits.
  static bool usPhone(String input) => RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(_digits(input));

  static String _digits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static bool email(String input) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input.trim());
}

/// Detects phone numbers and emails in chat text before a quote is accepted
/// (Section 2.6: warn, don't block).
abstract final class ContactInfoDetector {
  static final _email = RegExp(r'[^@\s]+@[^@\s]+\.[a-z]{2,}', caseSensitive: false);
  static final _phone = RegExp(r'(\+?\d[\d\s\-().]{8,}\d)');

  static bool containsContactInfo(String text) {
    if (_email.hasMatch(text)) return true;
    for (final m in _phone.allMatches(text)) {
      final digits = m.group(0)!.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= 10) return true;
    }
    return false;
  }
}
